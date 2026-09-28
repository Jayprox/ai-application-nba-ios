//
//  TeamModels.swift
//  Chalk That NBA
//
//  GET /teams (api.md §4): all 30, ordered by conference, division, name.
//  Team detail (GET /teams/:id) arrives in step 4.
//
import Foundation

struct Team: Decodable, Identifiable, Hashable {
    let id: Int
    let abbreviation: String
    let city: String?
    let name: String?
    let fullName: String
    let conference: String?
    let division: String?
    let arena: String?
    let arenaCity: String?
    let elevationFt: Int?
    let isHighAltitude: Bool?
}

/// GET /teams/:id: the team row plus `season_types` (season -> types
/// played, "cup" included). The active `roster` it also returns isn't
/// shown; the page lists everyone who played that season instead.
struct TeamDetail: Decodable {
    let id: Int
    let abbreviation: String
    let city: String?
    let name: String?
    let fullName: String
    let conference: String?
    let division: String?
    let arena: String?
    let arenaCity: String?
    let elevationFt: Int?
    let isHighAltitude: Bool?
    let seasonTypes: [String: [String]]

    /// "Western Conference · Northwest · Ball Arena" (TeamDetail.jsx).
    var subtitle: String {
        var s = "\(conference ?? "")ern Conference · \(division ?? "")"
        if let arena { s += " · \(arena)" }
        return s
    }
}

/// GET /teams/:id/players?season=&season_type=: everyone who played for
/// the team that season (trades included), sorted by points.
struct TeamSeasonPlayer: Decodable, Identifiable {
    let playerId: String
    let fullName: String
    let gp: Int
    let minutes: Double?
    let pts: Double?
    let reb: Double?
    let ast: Double?

    var id: String { playerId }
}

/// GET /seasons: seasons with finished games, newest first.
struct SeasonRow: Decodable {
    let season: String
    let types: [String]
    let finalGames: Int?
}

struct SeasonsMeta: Decodable {
    let currentSeason: String?
    let latestWithGames: String?
}
