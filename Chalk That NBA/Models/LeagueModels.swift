//
//  LeagueModels.swift
//  Chalk That NBA
//
//  Leaders (POST /query scope "leaderboard"), GET /standings and
//  GET /bracket (api.md §3, §5).
//
import Foundation

struct LeaderRow: Decodable, Identifiable {
    let rank: Int
    let playerId: String
    let fullName: String
    let gp: Int
    /// A per-game average, or for usage a 0–1 share.
    let value: Double?
    let team: String?

    var id: String { playerId }
}

struct StandingsData: Decodable {
    let east: [StandingRow]
    let west: [StandingRow]

    enum CodingKeys: String, CodingKey { case east = "East", west = "West" }
}

struct StandingRow: Decodable, Identifiable {
    let teamId: Int
    let abbreviation: String?
    let name: String
    let wins: Int
    let losses: Int
    let pct: Double?
    let home: String?
    let road: String?
    let conf: String?
    let last10: String?
    let streak: String?
    let rank: Int
    let rankSource: String?
    let clinch: String?
    let gb: Double?

    var id: Int { teamId }
}

struct PlayoffFormat: Decodable {
    let playoffSeeds: Int
    let playInSeeds: [Int]
}

struct StandingsMeta: Decodable {
    let season: String?
    let games: Double?
    let format: PlayoffFormat?
    let notes: [String]?
}

struct Series: Decodable, Identifiable {
    let id: Int
    let round: String
    let conference: String?
    let bracketSlot: String?
    let bestOf: Int?
    let higherSeed: Int?
    let lowerSeed: Int?
    let higherId: Int?
    let higherAbbr: String?
    let higherName: String?
    let lowerId: Int?
    let lowerAbbr: String?
    let lowerName: String?
    let winnerTeamId: Int?
    let higherWins: Int?
    let lowerWins: Int?
    let firstGame: String?
    let lastGame: String?
}
