//
//  APIClient.swift
//  Chalk That NBA
//
//  The one request wrapper; every API call goes through it (the web's
//  equivalent is frontend/src/lib/api.js). It attaches the bearer token
//  and, on a 401, gets a fresh access token from TokenRefresher and
//  retries the request exactly once (api.md §2). If the retry is still a
//  401, or the refresh itself says the session is over, it signs out and
//  posts `.chalkThatNBASessionExpired` so the UI returns to Login.
//
//  Structure copied from the NFL app. Differences, both matching the web:
//  - The token a request was SENT with is passed to TokenRefresher, which
//    skips the refresh when the stored token has already changed (another
//    request refreshed first). That is what makes it exactly one refresh.
//  - A refresh that fails from a network error or a 429 does NOT sign
//    out; the error surfaces and the session stays. Only a 400/401 from
//    /refresh ends the session.
//
import Foundation

enum APIError: LocalizedError {
    case invalidURL
    /// The session is over (the user has been signed out).
    case unauthorized
    /// A non-2xx response. `message` is the API's `error` string, which is
    /// written to be shown (api.md §1).
    case server(status: Int, message: String?, retryAfterSeconds: Int?)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request."
        case .unauthorized:
            return "Your session ended. Sign in again."
        case .server(let status, let message, let retryAfter):
            if status == 429 {
                if let retryAfter { return "Too many requests. Try again in \(Self.waitText(seconds: retryAfter))." }
                return message ?? "Too many requests. Try again later."
            }
            return message ?? "Server error (\(status))."
        case .decodingError:
            return "Couldn't read the server's response."
        case .networkError:
            return "Can't reach the server."
        case .unknown:
            return "Something went wrong."
        }
    }

    /// "45 seconds", "1 minute", "15 minutes": whole minutes, rounded up.
    static func waitText(seconds: Int) -> String {
        if seconds < 60 { return seconds == 1 ? "1 second" : "\(seconds) seconds" }
        let minutes = (seconds + 59) / 60
        return minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }
}

extension Notification.Name {
    /// Posted when the session ends anywhere in the app (refresh rejected,
    /// or still 401 after a refresh). AuthViewModel returns to Login.
    static let chalkThatNBASessionExpired = Notification.Name("chalkThatNBASessionExpired")
}

extension JSONDecoder {
    /// The API is snake_case (`sample_size`, `tipoff_utc`); Swift models are
    /// camelCase. Two things this strategy does that are easy to get wrong
    /// (both caught by the unit tests):
    /// - Keys inside `[String: T]` dictionaries are NOT converted:
    ///   `z["ts_pct"]`, `ranks["off_rtg"]` keep the API's spelling.
    /// - Components after the first are `.capitalized`, which treats a digit
    ///   as a word break: `player_b2b_night` -> `playerB2BNight`.
    static let chalkThatNBA: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

extension JSONEncoder {
    static let chalkThatNBA: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    /// A `var` only so the unit tests can swap in a stubbed session.
    var session: URLSession = .shared

    // MARK: - Authenticated request with refresh-and-retry-once

    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        bodyData: Data? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        let data = try await requestData(path: path, method: method, bodyData: bodyData, authenticated: authenticated)
        do {
            return try JSONDecoder.chalkThatNBA.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[APIClient] decode failed for \(T.self): \(String(describing: error))")
            #endif
            throw APIError.decodingError(error)
        }
    }

    /// The same auth / refresh / retry flow, returning the raw 2xx body.
    /// POST /ask uses it to read `plan` without the snake-case conversion.
    func requestData(
        path: String,
        method: String = "GET",
        bodyData: Data? = nil,
        authenticated: Bool = true
    ) async throws -> Data {
        let sentToken = authenticated ? KeychainManager.accessToken : nil
        let (data, http) = try await send(path: path, method: method, body: bodyData, token: sentToken)

        guard http.statusCode == 401, authenticated else {
            return try successData(data, http)
        }

        // Expired or invalid access token: one refresh (shared with any
        // concurrent callers), then one retry.
        let freshToken: String
        do {
            freshToken = try await TokenRefresher.shared.freshAccessToken(replacing: sentToken)
        } catch APIError.unauthorized {
            endSession()
            throw APIError.unauthorized
        }

        let (retryData, retryHTTP) = try await send(path: path, method: method, body: bodyData, token: freshToken)
        if retryHTTP.statusCode == 401 {
            endSession()
            throw APIError.unauthorized
        }
        return try successData(retryData, retryHTTP)
    }

    // MARK: - Convenience wrappers

    func get<T: Decodable>(_ path: String, authenticated: Bool = true) async throws -> T {
        try await request(path: path, method: "GET", authenticated: authenticated)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B, authenticated: Bool = true) async throws -> T {
        let data = try JSONEncoder.chalkThatNBA.encode(body)
        return try await request(path: path, method: "POST", bodyData: data, authenticated: authenticated)
    }

    /// For 204 / bodies we don't need (logout).
    func postDiscardingResponse<B: Encodable>(_ path: String, body: B, authenticated: Bool = true) async throws {
        let data = try JSONEncoder.chalkThatNBA.encode(body)
        let (responseData, http) = try await send(path: path, method: "POST", body: data, token: nil)
        guard (200...299).contains(http.statusCode) else { throw Self.serverError(responseData, http) }
    }

    // MARK: - Raw HTTP (no refresh logic; TokenRefresher uses this too)

    func send(path: String, method: String, body: Data?, token: String?) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: Endpoints.baseURL + path) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = body

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }

        #if DEBUG
        print("[APIClient] \(method) \(path) -> \(http.statusCode), \(data.count) bytes")
        #endif
        return (data, http)
    }

    static func serverError(_ data: Data, _ http: HTTPURLResponse) -> APIError {
        let body = try? JSONDecoder.chalkThatNBA.decode(APIErrorResponse.self, from: data)
        let headerRetry = http.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
        return .server(status: http.statusCode, message: body?.error, retryAfterSeconds: body?.retryAfterSeconds ?? headerRetry)
    }

    private func successData(_ data: Data, _ http: HTTPURLResponse) throws -> Data {
        guard (200...299).contains(http.statusCode) else { throw Self.serverError(data, http) }
        return data
    }

    private func endSession() {
        KeychainManager.clearSession()
        NotificationCenter.default.post(name: .chalkThatNBASessionExpired, object: nil)
    }
}
