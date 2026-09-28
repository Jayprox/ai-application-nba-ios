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

    // MARK: - Games (api.md §4)
    static func games(date: String) -> String { "/games?date=\(date)" }
    static func game(_ id: String) -> String { "/games/\(id)" }

    // MARK: - Browse (api.md §4)
    static let teams = "/teams"
    static let seasons = "/seasons"

    /// GET /players?q=&team=&active= ("active" defaults to true on the server;
    /// it's always sent so the request says what it means).
    static func players(q: String, teamId: Int?, active: Bool) -> String {
        var components = URLComponents()
        var items: [URLQueryItem] = []
        if !q.isEmpty { items.append(URLQueryItem(name: "q", value: q)) }
        if let teamId { items.append(URLQueryItem(name: "team", value: String(teamId))) }
        items.append(URLQueryItem(name: "active", value: active ? "true" : "false"))
        components.queryItems = items
        return "/players?" + (components.percentEncodedQuery ?? "")
    }
    static func player(_ id: String) -> String { "/players/\(id)" }
    static func playerProps(_ id: String) -> String { "/players/\(id)/props" }

    // MARK: - Stats engine (api.md §3)
    static let query = "/query"
}
