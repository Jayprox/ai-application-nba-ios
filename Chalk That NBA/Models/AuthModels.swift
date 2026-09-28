//
//  AuthModels.swift
//  Chalk That NBA
//
//  Wire models for api.md §2. Username + password only; there is no
//  signup (JD creates accounts). The API is snake_case throughout
//  (`access_token`), bridged by JSONDecoder/Encoder.chalkThatNBA.
//
import Foundation

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct RefreshRequest: Encodable {
    let refreshToken: String
}

struct LogoutRequest: Encodable {
    let refreshToken: String
}

/// POST /login and POST /refresh:
/// `{ access_token, refresh_token, token_type: "Bearer", expires_in: 900 }`.
struct TokenPairResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String?
    let expiresIn: Int?
}

/// Every error body is `{ "error": "<message>" }` (api.md §1); a 429 adds
/// `retry_after_seconds`.
struct APIErrorResponse: Decodable {
    let error: String?
    let retryAfterSeconds: Int?
}
