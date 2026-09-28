//
//  TokenRefreshTests.swift
//  Chalk That NBATests
//
//  ios-kickoff.md §7 step 1: "force an expired token, confirm exactly one
//  refresh", plus the sign-out rules from api.md §2. Runs against
//  StubServer (no network) in its own Keychain namespace, so it never
//  touches a real signed-in session in the simulator.
//
import XCTest
@testable import Chalk_That_NBA

private struct OK: Decodable {
    struct Payload: Decodable { let ok: Bool }
    let data: Payload
}

final class TokenRefreshTests: XCTestCase {
    private var server: StubServer { .shared }

    override func setUp() {
        super.setUp()
        KeychainManager.service = "com.chalkthat.nba.tests"
        KeychainManager.clearSession()
        server.reset()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        APIClient.shared.session = URLSession(configuration: config)
    }

    override func tearDown() {
        KeychainManager.clearSession()
        super.tearDown()
    }

    /// Expired access token "A0" + the live refresh token "R1".
    private func signInWithExpiredAccessToken() {
        KeychainManager.saveSession(accessToken: "A0", refreshToken: server.currentRefresh, username: "jd")
    }

    private func get() async throws -> OK {
        try await APIClient.shared.get("/seasons")
    }

    // MARK: - Exactly one refresh

    func testConcurrent401sShareExactlyOneRefresh() async throws {
        signInWithExpiredAccessToken()

        try await withThrowingTaskGroup(of: Bool.self) { group in
            for _ in 0..<8 {
                group.addTask { try await self.get().data.ok }
            }
            for try await ok in group { XCTAssertTrue(ok) }
        }

        XCTAssertEqual(server.refreshCalls, 1, "8 concurrent 401s must share one refresh")
        XCTAssertEqual(server.reuseCount, 0, "no refresh token may be presented twice")
        XCTAssertEqual(KeychainManager.accessToken, server.currentAccess)
        XCTAssertEqual(KeychainManager.refreshToken, server.currentRefresh)
    }

    func testLate401AfterRefreshFinishedDoesNotRefreshAgain() async throws {
        signInWithExpiredAccessToken()

        let first = try await TokenRefresher.shared.freshAccessToken(replacing: "A0")
        // A request that was sent with A0 before the refresh, whose 401
        // only arrives now that the refresh is done.
        let late = try await TokenRefresher.shared.freshAccessToken(replacing: "A0")

        XCTAssertEqual(first, late)
        XCTAssertEqual(server.refreshCalls, 1)
        XCTAssertEqual(server.reuseCount, 0)
    }

    func testRequestsAfterRefreshUseNewTokenWithoutRefreshing() async throws {
        signInWithExpiredAccessToken()
        _ = try await get()
        _ = try await get()
        _ = try await get()
        XCTAssertEqual(server.refreshCalls, 1)
    }

    // MARK: - Sign-out rules

    func testReusedRefreshTokenSignsOut() async throws {
        signInWithExpiredAccessToken()
        server.refreshFailure = .status(401, "refresh_token_reused")
        let expired = expectation(forNotification: .chalkThatNBASessionExpired, object: nil)

        do {
            _ = try await get()
            XCTFail("expected unauthorized")
        } catch APIError.unauthorized {
        }

        await fulfillment(of: [expired], timeout: 2)
        XCTAssertNil(KeychainManager.refreshToken)
        XCTAssertNil(KeychainManager.accessToken)
    }

    func testStill401AfterRefreshSignsOut() async throws {
        signInWithExpiredAccessToken()
        server.alwaysRejectData = true

        do {
            _ = try await get()
            XCTFail("expected unauthorized")
        } catch APIError.unauthorized {
        }

        XCTAssertEqual(server.refreshCalls, 1, "refresh once, retry once, then stop")
        XCTAssertNil(KeychainManager.refreshToken)
    }

    func testNetworkErrorDuringRefreshKeepsSession() async throws {
        signInWithExpiredAccessToken()
        server.refreshFailure = .offline

        do {
            _ = try await get()
            XCTFail("expected a network error")
        } catch APIError.networkError {
        }

        XCTAssertEqual(KeychainManager.refreshToken, "R1", "a dropped connection must not sign out")
    }

    func testRateLimitedRefreshKeepsSession() async throws {
        signInWithExpiredAccessToken()
        server.refreshFailure = .status(429, "too_many_attempts")

        do {
            _ = try await get()
            XCTFail("expected a 429")
        } catch APIError.server(let status, _, _) {
            XCTAssertEqual(status, 429)
        }

        XCTAssertEqual(KeychainManager.refreshToken, "R1")
    }

    func testSignOutDuringRefreshDoesNotRestoreSession() async throws {
        signInWithExpiredAccessToken()
        server.refreshDelay = 0.5

        async let result: OK = get()
        try await Task.sleep(nanoseconds: 150_000_000)
        KeychainManager.clearSession()

        do {
            _ = try await result
            XCTFail("expected unauthorized")
        } catch APIError.unauthorized {
        }
        XCTAssertNil(KeychainManager.refreshToken, "the old session must not come back")
    }

    // MARK: - Login messages (pages/Login.jsx wording)

    func testLoginMessages() async {
        let wrong = await AuthViewModel.loginMessage(for: APIError.server(status: 401, message: "invalid_credentials", retryAfterSeconds: nil))
        XCTAssertEqual(wrong, "Wrong username or password.")

        let limited = await AuthViewModel.loginMessage(for: APIError.server(status: 429, message: "too_many_attempts", retryAfterSeconds: 840))
        XCTAssertEqual(limited, "Too many failed attempts. Try again in 14 minutes.")

        let offline = await AuthViewModel.loginMessage(for: APIError.networkError(URLError(.notConnectedToInternet)))
        XCTAssertEqual(offline, "Can't reach the server.")
    }
}
