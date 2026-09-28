//
//  TokenRefresher.swift
//  Chalk That NBA
//
//  Owns POST /refresh. Refresh tokens ROTATE, and presenting an
//  already-used one revokes every session for the user (api.md §2), so
//  "only one refresh ever in flight" is a correctness rule, not an
//  optimization. Two guards, both from the web's lib/api.js:
//
//  1. Single flight. An actor with one shared Task: callers that arrive
//     while a refresh is running await that same Task.
//  2. Already refreshed. A caller passes the access token its request was
//     sent with. If the stored token is different, someone else already
//     refreshed, so it gets the stored token and no refresh happens. This
//     covers a 401 that lands just AFTER another refresh finished, which
//     guard 1 alone (the NFL app's version) would refresh again.
//
//  Outcomes:
//  - 2xx: new pair saved (refresh token first), new access token returned.
//  - 400/401 from /refresh (expired, invalid, reused): session cleared,
//    throws `.unauthorized`, and APIClient returns the app to Login.
//  - Network error or 429: throws that error and KEEPS the session, so a
//    dropped connection doesn't sign the user out.
//
import Foundation

actor TokenRefresher {
    static let shared = TokenRefresher()
    private init() {}

    private var inFlight: Task<String, Error>?

    /// - Parameter rejected: the access token the server just answered 401 to.
    func freshAccessToken(replacing rejected: String?) async throws -> String {
        if let inFlight {
            return try await inFlight.value
        }
        if let current = KeychainManager.accessToken, current != rejected {
            return current
        }

        let task = Task<String, Error> { try await Self.performRefresh() }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }

    private static func performRefresh() async throws -> String {
        guard let refreshToken = KeychainManager.refreshToken else {
            throw APIError.unauthorized
        }

        let body = try JSONEncoder.chalkThatNBA.encode(RefreshRequest(refreshToken: refreshToken))
        let (data, http) = try await APIClient.shared.send(path: Endpoints.refresh, method: "POST", body: body, token: nil)

        switch http.statusCode {
        case 200...299:
            let pair: TokenPairResponse
            do {
                pair = try JSONDecoder.chalkThatNBA.decode(TokenPairResponse.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
            // Signed out while this was in flight: don't bring the old
            // session back. Signed in again: keep the newer session.
            guard let stored = KeychainManager.refreshToken else {
                throw APIError.unauthorized
            }
            guard stored == refreshToken else {
                if let current = KeychainManager.accessToken { return current }
                throw APIError.unauthorized
            }
            KeychainManager.saveSession(accessToken: pair.accessToken, refreshToken: pair.refreshToken)
            return pair.accessToken

        case 400, 401:
            if KeychainManager.refreshToken == refreshToken {
                KeychainManager.clearSession()
            }
            throw APIError.unauthorized

        default:
            throw APIClient.serverError(data, http)
        }
    }
}
