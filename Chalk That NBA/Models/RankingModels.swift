//
//  RankingModels.swift
//  Chalk That NBA
//
//  GET /rankings/matchups (api.md §6): what each defense allows per game
//  to guards, forwards and centers, in every prop market. Rank 1 = allows
//  the fewest. `label` is "strong" (best 5), "weak" (worst 5) or null.
//  Players are ranked by an equal-weight z-score composite the API
//  computes; teams by estimated ratings. The app shows them as given.
//
//  Keys inside dictionaries (z["ts_pct"], ranks["off_rtg"]) arrive exactly
//  as the API sends them: JSONDecoder's key strategy doesn't touch them.
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
    let leagueAvg: [String: [String: Double?]?]?
    let meta: NotesMeta?
}

struct NotesMeta: Decodable {
    let notes: [String]?
}

struct PlayerRankingRow: Decodable, Identifiable {
    let rank: Int
    let playerId: String
    let name: String
    let team: String?
    let listedPosition: String?
    let gp: Int
    let pts, reb, ast, stl, blk, fg3m, tov, minutes, tsPct: Double?
    let z: [String: Double?]
    let score: Double?

    var id: String { playerId }

    /// The stat named in meta.stats ("pts", "ts_pct"…).
    func value(_ stat: String) -> Double? {
        switch stat {
        case "pts": return pts
        case "reb": return reb
        case "ast": return ast
        case "stl": return stl
        case "blk": return blk
        case "fg3m": return fg3m
        case "tov": return tov
        case "ts_pct": return tsPct
        default: return nil
        }
    }

    func zScore(_ stat: String) -> Double? { z[stat] ?? nil }
}

struct PlayerRankingsMeta: Decodable {
    let positionLabel: String
    let stats: [String]
    let count: Int
    let notes: [String]
}

struct TeamRankingRow: Decodable, Identifiable {
    let teamId: Int
    let abbr: String
    let name: String
    let gp: Int?
    let w: Int
    let l: Int
    let pts, oppPts, offRtg, defRtg, netRtg, pace: Double?
    let ranks: [String: Int?]

    var id: Int { teamId }

    func rank(_ key: String) -> Int? { ranks[key] ?? nil }
}
