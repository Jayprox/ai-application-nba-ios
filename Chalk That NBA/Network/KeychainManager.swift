//
//  KeychainManager.swift
//  Chalk That NBA
//
//  Keychain storage for the access/refresh token pair (never
//  UserDefaults: api.md §2), plus the username typed at login for display.
//  Copied from the NFL app, with two changes: items are
//  AfterFirstUnlockThisDeviceOnly (not synced or restored to another
//  device), and the refresh token is always written first (below). `service` is a `var` only so the unit tests
//  can use their own Keychain namespace and never touch a real session.
//
import Foundation
import Security

enum KeychainManager {
    static var service = "com.chalkthat.nba"
    private static let accessTokenKey  = "chalkThatNBA_accessToken"
    private static let refreshTokenKey = "chalkThatNBA_refreshToken"
    private static let usernameKey     = "chalkThatNBA_username"

    // MARK: - Generic get/set/delete over kSecClassGenericPassword

    @discardableResult
    private static func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        delete(forKey: key)
        let query: [CFString: Any] = [
            kSecClass:          kSecClassGenericPassword,
            kSecAttrService:    service,
            kSecAttrAccount:    key,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData:      data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    private static func load(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else { return nil }
        return value
    }

    @discardableResult
    private static func delete(forKey key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    // MARK: - Session

    static var accessToken: String? {
        get { load(forKey: accessTokenKey) }
        set { if let newValue { save(newValue, forKey: accessTokenKey) } else { delete(forKey: accessTokenKey) } }
    }

    static var refreshToken: String? {
        get { load(forKey: refreshTokenKey) }
        set { if let newValue { save(newValue, forKey: refreshTokenKey) } else { delete(forKey: refreshTokenKey) } }
    }

    static var username: String? {
        get { load(forKey: usernameKey) }
        set { if let newValue { save(newValue, forKey: usernameKey) } else { delete(forKey: usernameKey) } }
    }

    /// The refresh token is written FIRST, on purpose. If the app dies
    /// between the two writes, a new refresh token + old access token just
    /// means one more refresh later. The other order (new access token +
    /// already-rotated refresh token) would make the next refresh a reuse,
    /// which signs the user out everywhere (api.md §2).
    static func saveSession(accessToken: String, refreshToken: String, username: String? = nil) {
        self.refreshToken = refreshToken
        self.accessToken = accessToken
        if let username { self.username = username }
    }

    static func clearSession() {
        accessToken = nil
        refreshToken = nil
        username = nil
    }
}
