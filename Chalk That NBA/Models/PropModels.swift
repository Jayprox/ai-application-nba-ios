//
//  PropModels.swift
//  Chalk That NBA
//
//  GET /players/:id/props (api.md §7) plus the market vocabulary shared
//  with the props board (step 6). Counts against real DraftKings lines,
//  never picks.
//
import Foundation

enum Markets {
    /// The web's lib/props.js MARKETS: board order and short labels.
    static let all: [(key: String, short: String)] = [
        ("pts", "PTS"), ("reb", "REB"), ("ast", "AST"), ("fg3m", "3PM"), ("pra", "PRA"), ("pr", "P+R"),
        ("pa", "P+A"), ("ra", "R+A"), ("stl", "STL"), ("blk", "BLK"), ("stocks", "STL+BLK"), ("tov", "TOV")
    ]
    static func short(_ market: String) -> String { all.first { $0.key == market }?.short ?? market.uppercased() }
    static func order(_ market: String) -> Int { all.firstIndex { $0.key == market } ?? all.count }

    /// `price`: American odds, "+105" / "-110".
    static func price(_ p: Int?) -> String {
        guard let p else { return "" }
        return p > 0 ? "+\(p)" : String(p)
    }

    static let resultLabel = ["over": "Over", "under": "Under", "push": "Push", "dnp": "DNP"]
}

struct PlayerProps: Decodable {
    let upcoming: Upcoming?
    let record: [String: RecordLine]

    struct Upcoming: Decodable {
        let game: Game
        let lines: [Line]
    }

    struct Game: Decodable {
        let id: String
        let date: String
        let tipoffUtc: String?
        let status: String
        let home: String
        let away: String
    }

    struct Line: Decodable {
        let market: String
        let label: String?
        let line: Double
        let overPrice: Int?
        let underPrice: Int?
        let snapshot: String?
        let openLine: Double?
    }

    struct RecordLine: Decodable {
        let label: String?
        let over: Int
        let under: Int
        let push: Int
        let games: Int
    }
}

/// POST /query `props`: how often he went over each line in the selected games.
struct PropHits: Decodable {
    let line: Double
    let over: Int
    let under: Int
    let push: Int
    let games: Int
}

/// A game-log row's `props[market]`: the line and how it graded.
struct GradedLine: Decodable {
    let line: Double
    let result: String?
}
