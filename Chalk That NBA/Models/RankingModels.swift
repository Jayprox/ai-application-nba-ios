//
//  RankingModels.swift
//  Chalk That NBA
//
//  GET /rankings/matchups (api.md §6): what each defense allows per game
//  to guards, forwards and centers, in every prop market. Rank 1 = allows
//  the fewest. `label` is "strong" (best 5), "weak" (worst 5) or null.
//  Players and teams rankings arrive in step 6.
//
import Foundation

struct MatchupRow: Decodable {
    let teamId: Int
    let abbr: String
    let games: Int
    let allowed: [String: Double?]
    let vsAvg: [String: Double?]
    let rank: [String: Int?]
    let label: [String: String?]
}

struct MatchupsData: Decodable {
    let data: [String: [MatchupRow]]
    let leagueAvg: [String: [String: Double?]]?
}
