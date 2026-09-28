//
//  StubServer.swift
//  Chalk That NBATests
//
//  A fake backend-api behind a URLProtocol: no real network, no real
//  server. It follows api.md §2's rotation rules: /refresh with the
//  current refresh token issues a new pair and kills the old one;
//  /refresh with a used token answers 401 `refresh_token_reused` and
//  counts it. Any other path answers 200 for the current access token and
//  401 `access_token_expired` otherwise.
//
import Foundation

final class StubServer {
    static let shared = StubServer()

    private let lock = NSLock()
    private var validAccess = "A1"
    private var validRefresh = "R1"
    private var generation = 1

    private(set) var refreshCalls = 0
    private(set) var reuseCount = 0

    /// Seconds /refresh takes to answer, so concurrent callers overlap it.
    var refreshDelay: TimeInterval = 0.3
    /// Forces every /refresh to fail this way instead of rotating.
    var refreshFailure: RefreshFailure?
    /// Makes every data request 401, even with the current token.
    var alwaysRejectData = false

    enum RefreshFailure {
        case status(Int, String)
        case offline
    }

    func reset(access: String = "A1", refresh: String = "R1") {
        lock.lock(); defer { lock.unlock() }
        validAccess = access
        validRefresh = refresh
        generation = 1
        refreshCalls = 0
        reuseCount = 0
        refreshDelay = 0.3
        refreshFailure = nil
        alwaysRejectData = false
    }

    var currentAccess: String { lock.lock(); defer { lock.unlock() }; return validAccess }
    var currentRefresh: String { lock.lock(); defer { lock.unlock() }; return validRefresh }

    /// Returns (status, JSON body, delay) or throws for a network error.
    func respond(to request: URLRequest, body: Data?) throws -> (Int, Data, TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        let path = request.url?.path ?? ""

        if path == "/refresh" {
            refreshCalls += 1
            if let failure = refreshFailure {
                switch failure {
                case .offline: throw URLError(.notConnectedToInternet)
                case .status(let code, let error): return (code, json(["error": error]), refreshDelay)
                }
            }
            let sent = (try? JSONSerialization.jsonObject(with: body ?? Data())) as? [String: Any]
            guard let token = sent?["refresh_token"] as? String else {
                return (400, json(["error": "refresh_token is required"]), 0)
            }
            guard token == validRefresh else {
                reuseCount += 1
                return (401, json(["error": "refresh_token_reused"]), refreshDelay)
            }
            generation += 1
            validAccess = "A\(generation)"
            validRefresh = "R\(generation)"
            return (200, json([
                "access_token": validAccess, "refresh_token": validRefresh,
                "token_type": "Bearer", "expires_in": 900
            ]), refreshDelay)
        }

        if path == "/logout" { return (204, Data(), 0) }

        let auth = request.value(forHTTPHeaderField: "Authorization")
        if !alwaysRejectData, auth == "Bearer \(validAccess)" {
            return (200, json(["data": ["ok": true], "meta": [:]]), 0.05)
        }
        return (401, json(["error": "access_token_expired"]), 0.05)
    }

    private func json(_ object: [String: Any]) -> Data {
        (try? JSONSerialization.data(withJSONObject: object)) ?? Data()
    }
}

final class StubURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = request.httpBody ?? Self.readStream(request.httpBodyStream)
        do {
            let (status, data, delay) = try StubServer.shared.respond(to: request, body: body)
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, let url = self.request.url else { return }
                let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1",
                                               headerFields: ["Content-Type": "application/json"])!
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: data)
                self.client?.urlProtocolDidFinishLoading(self)
            }
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func readStream(_ stream: InputStream?) -> Data? {
        guard let stream else { return nil }
        stream.open(); defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
