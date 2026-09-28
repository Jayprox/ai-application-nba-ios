//
//  AuthViewModel.swift
//  Chalk That NBA
//
//  Owns `isAuthenticated` (the App switches Login ↔ tabs on it) and the
//  login/logout flow. Listens for `.chalkThatNBASessionExpired` so a
//  session that ends anywhere (refresh rejected or reused) returns to
//  Login. Copied from the NFL app. Error wording matches the web's
//  pages/Login.jsx, except a 429 shows `retry_after_seconds`
//  (ios-kickoff.md §3, screen 1).
//
import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var isAuthenticated: Bool
    @Published private(set) var username: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var sessionExpiredObserver: NSObjectProtocol?

    init() {
        // A stored refresh token means there's a session to resume. The
        // access token may have expired (15 min); the first request's 401
        // refreshes it.
        isAuthenticated = KeychainManager.refreshToken != nil
        username = KeychainManager.username

        sessionExpiredObserver = NotificationCenter.default.addObserver(
            forName: .chalkThatNBASessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isAuthenticated = false
                self?.username = nil
            }
        }
    }

    deinit {
        if let sessionExpiredObserver {
            NotificationCenter.default.removeObserver(sessionExpiredObserver)
        }
    }

    func login(username: String, password: String) async {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your username and password."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let pair: TokenPairResponse = try await APIClient.shared.post(
                Endpoints.login,
                body: LoginRequest(username: trimmedUsername, password: password),
                authenticated: false
            )
            KeychainManager.saveSession(
                accessToken: pair.accessToken,
                refreshToken: pair.refreshToken,
                username: trimmedUsername
            )
            self.username = trimmedUsername
            isAuthenticated = true
        } catch {
            errorMessage = Self.loginMessage(for: error)
        }
    }

    /// Mirrors pages/Login.jsx.
    static func loginMessage(for error: Error) -> String {
        switch error {
        case APIError.server(401, _, _):
            return "Wrong username or password."
        case APIError.server(429, _, let retryAfter):
            if let retryAfter {
                return "Too many failed attempts. Try again in \(APIError.waitText(seconds: retryAfter))."
            }
            return "Too many failed attempts. Wait 15 minutes, then try again."
        case APIError.networkError:
            return "Can't reach the server."
        default:
            return "Sign-in failed. Try again."
        }
    }

    func logout() async {
        // Clear locally first (the web does the same), then revoke the
        // refresh token server-side, best effort. /logout is idempotent.
        let refreshToken = KeychainManager.refreshToken
        KeychainManager.clearSession()
        username = nil
        isAuthenticated = false
        if let refreshToken {
            try? await APIClient.shared.postDiscardingResponse(
                Endpoints.logout,
                body: LogoutRequest(refreshToken: refreshToken),
                authenticated: false
            )
        }
    }
}
