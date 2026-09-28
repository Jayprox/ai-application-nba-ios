//
//  Endpoints.swift
//  Chalk That NBA
//
//  Route constants for backend-api (docs/api.md in ai-application-nba).
//  Each screen adds its routes here as it's built.
//
//  The base URL comes from the build config, not code: the `API_BASE_URL`
//  build setting is written into Info.plist as `APIBaseURL`. Debug and
//  Release both point at production today (kickoff decision 2026-09-28);
//  change the build setting per configuration to point elsewhere.
//
import Foundation

enum Endpoints {
    static let baseURL: String = {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String) ?? ""
        precondition(!raw.isEmpty && !raw.hasPrefix("$("),
                     "APIBaseURL is missing from Info.plist. Set the API_BASE_URL build setting.")
        return raw.hasSuffix("/") ? String(raw.dropLast()) : raw
    }()

    // MARK: - Auth (public; api.md §2)
    static let login   = "/login"
    static let refresh = "/refresh"
    static let logout  = "/logout"
    static let health  = "/health"
}
