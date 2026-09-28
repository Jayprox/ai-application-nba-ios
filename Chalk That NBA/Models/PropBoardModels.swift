//
//  PropBoardModels.swift
//  Chalk That NBA
//
//  GET /props?date=&market= (api.md §7): DraftKings lines for one date and
//  market, each with how often the player went over that exact line
//  before this date. Counts, never picks.
//
import Foundation

struct PropBoardResponse: Decodable {
    let data: [PropBoardRow]
    let games: [PropBoardGame]
    let meta: PropBoardMeta
}

struct HitRate: Decodable {
    let over: Int
    let under: Int
    let push: Int
    let games: Int
    let avg: Double?
}

struct MatchupNote: Decodable {
    let position: String?
    let positionLabel: String
    let rank: Int?
    let of: Int
    let allowed: Double?
    let vsAvg: Double?
    let label: String?
    let games: Int?
    let opponent: String
}

struct PropBoardRow: Decodable, Identifiable {
    let gameId: String
    let playerId: String
    let name: String
    let team: String?
    let opponent: String?
    let venue: String?
    let line: Double
    let overPrice: Int?
    let underPrice: Int?
    let snapshot: String?
    let openLine: Double?
    let actual: Double?
    let result: String?
    let last10: HitRate
    let season: HitRate
    let lastSeason: HitRate?
    let matchup: MatchupNote?

    var id: String { "\(gameId):\(playerId)" }
}

struct PropBoardGame: Decodable, Identifiable {
    let id: String
    let tipoffUtc: String?
    let status: String
    let home: String
    let away: String
}

struct PropBoardMeta: Decodable {
    let date: String?
    let market: String
    let marketLabel: String
    let markets: [[String]]?
    let prevDate: String?
    let nextDate: String?
    let count: Int
    let notes: [String]
}

/// The web's lib/props.js + lib/rankings.js helpers, pure and tested.
enum PropText {
    /// `hits`: "7/10", or "—" with no games.
    static func hits(_ h: HitRate?) -> String {
        guard let h, h.games > 0 else { return "—" }
        return "\(h.over)/\(h.games)"
    }

    /// `ratePct`: "70%" (Math.round), or "—".
    static func ratePct(_ h: HitRate?) -> String {
        guard let h, h.games > 0 else { return "—" }
        return "\(Int(Format.jsRound(Double(h.over) / Double(h.games) * 100)))%"
    }

    static func overRate(_ h: HitRate?) -> Double? {
        guard let h, h.games > 0 else { return nil }
        return Double(h.over) / Double(h.games)
    }

    /// `movement`: up / down from the opening line, or nil when unchanged.
    static func movement(open: Double?, line: Double?) -> (up: Bool, by: Double)? {
        guard let open, let line, open != line else { return nil }
        return (line > open, abs(line - open))
    }

    /// `matchupText`: "BOS: 27th of 30 vs guards", or nil.
    static func matchupText(_ m: MatchupNote?) -> String? {
        guard let m, let rank = m.rank else { return nil }
        return "\(m.opponent): \(Format.ordinal(rank)) of \(m.of) vs \(m.positionLabel.lowercased())"
    }

    /// `seasonOf`: this season's record, or last season's before he has played.
    static func seasonOf(_ r: PropBoardRow) -> (rate: HitRate?, isLastSeason: Bool) {
        if r.season.games > 0 { return (r.season, false) }
        return (r.lastSeason, r.lastSeason?.games ?? 0 > 0)
    }

    /// `matchup`: "BOS @ NYK" from his side.
    static func matchup(_ r: PropBoardRow) -> String {
        guard let team = r.team else { return "" }
        return "\(team) \(r.venue == "home" ? "vs" : "@") \(r.opponent ?? "")"
    }

    enum Sort: String, CaseIterable {
        case l10, season, line, game
        var label: String {
            switch self {
            case .l10: return "Last 10 over rate"
            case .season: return "Season over rate"
            case .line: return "Line (high to low)"
            case .game: return "Game"
            }
        }
    }

    /// `sortRows`: over rate high to low (the bigger sample first on equal
    /// rates), then line; line: high to low; game: tip-off order, then
    /// name. Ties fall back to name, as on the web.
    static func sortRows(_ rows: [PropBoardRow], by sort: Sort, gameOrder: [String: Int] = [:]) -> [PropBoardRow] {
        func rate(_ h: HitRate) -> Double { overRate(h) ?? -1 }
        func compare(_ a: PropBoardRow, _ b: PropBoardRow) -> Int {
            func sign(_ x: Double) -> Int { x < 0 ? -1 : (x > 0 ? 1 : 0) }
            switch sort {
            case .l10:
                return firstNonZero(sign(rate(b.last10) - rate(a.last10)), b.last10.games - a.last10.games, sign(b.line - a.line))
            case .season:
                return firstNonZero(sign(rate(b.season) - rate(a.season)), b.season.games - a.season.games, sign(b.line - a.line))
            case .line:
                return sign(b.line - a.line)
            case .game:
                return firstNonZero((gameOrder[a.gameId] ?? 0) - (gameOrder[b.gameId] ?? 0), nameOrder(a.name, b.name))
            }
        }
        return rows.stableSorted { a, b in
            let c = compare(a, b)
            return (c != 0 ? c : nameOrder(a.name, b.name)) < 0
        }
    }

    private static func firstNonZero(_ values: Int...) -> Int { values.first { $0 != 0 } ?? 0 }

    /// Stand-in for JS localeCompare (only breaks exact ties).
    private static func nameOrder(_ a: String, _ b: String) -> Int {
        switch a.compare(b, options: [], range: nil, locale: Locale(identifier: "en_US")) {
        case .orderedAscending: return -1
        case .orderedDescending: return 1
        case .orderedSame: return 0
        }
    }
}
