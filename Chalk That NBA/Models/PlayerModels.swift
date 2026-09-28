//
//  PlayerModels.swift
//  Chalk That NBA
//
//  GET /players?q=&active=&team= and GET /players/:id (api.md §4).
//
import Foundation

struct PlayerSearchResult: Decodable, Identifiable, Hashable {
    let id: String
    let fullName: String
    let listedPosition: String?
    let isActive: Bool
    let firstSeasonStart: Int?
    let teamId: Int?
    let team: String?
}

struct PlayerSearchMeta: Decodable {
    let total: Int
    let truncated: Bool
    let activeOnly: Bool?
}

struct PlayerDetail: Decodable {
    let id: String
    let fullName: String
    let listedPosition: String?
    let heightIn: Int?
    let weightLb: Int?
    let isActive: Bool
    let team: String?
    let teamName: String?
    /// Seasons he played, newest first.
    let seasons: [String]
    /// season -> the season types he played ("regular", "playoffs", "cup"…).
    let seasonTypes: [String: [String]]
    let currentInjury: Injury?

    struct Injury: Decodable {
        let status: String
        let description: String?
    }

    /// The web's `height()`: 6'9".
    var heightText: String? {
        guard let heightIn, heightIn > 0 else { return nil }
        return "\(heightIn / 12)'\(heightIn % 12)\""
    }

    /// "F · Los Angeles Lakers · 6'9" · 250 lb · Retired" (PlayerDetail.jsx).
    var subtitle: String {
        [listedPosition, teamName, heightText, weightLb.map { "\($0) lb" }, isActive ? nil : "Retired"]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
