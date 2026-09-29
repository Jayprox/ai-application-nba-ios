//
//  QueryModels.swift
//  Chalk That NBA
//
//  POST /query, the one stats engine (api.md §3). `StatQuery` is the
//  request body; `QueryResponse<T>` is generic over `data`, which differs
//  by scope: an `Averages` object (season / last5 / last10, null with no
//  games), `CareerData`, or `[GameLogRow]`.
//
//  Numbers are decoded as-is and only formatted; nothing here computes a
//  stat.
//
//  Decodable types here must NOT declare snake_case CodingKeys: the
//  decoder's convertFromSnakeCase turns "plus_minus" into "plusMinus"
//  before matching, so a "plus_minus" raw value would never match.
//  (`pts_per36` -> `ptsPer36`, `fg3_pct` -> `fg3Pct`, `b2b_night` -> `b2bNight`,
//  but `player_b2b_night` -> `playerB2BNight`: a later component is
//  `.capitalized`, which treats a digit as a word break, so b2b -> B2B.)
//  Keys INSIDE [String: T] dictionaries are not converted at all.
//
import Foundation

// MARK: - Request

enum QueryEntity: String, Encodable {
    case player, team
}

/// Rest values: 0, 1, 2 or the string "3+" (a small enum with a custom encoder).
enum RestValue: Hashable, Encodable {
    case days(Int)
    case threePlus

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .days(let n): try container.encode(n)
        case .threePlus: try container.encode("3+")
        }
    }
}

struct QuerySplits: Hashable, Encodable {
    var venue: String?
    var playerRest: RestValue?
    var playerB2b: Int?
    var rest: RestValue?
    var b2b: Int?
    var nationalTv: String?
    var altitude: Bool?

    enum CodingKeys: String, CodingKey {
        case venue, playerRest = "player_rest", playerB2b = "player_b2b", rest, b2b
        case nationalTv = "national_tv", altitude
    }

    /// Only the splits that are set go in the body (encodeIfPresent).
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(venue, forKey: .venue)
        try c.encodeIfPresent(playerRest, forKey: .playerRest)
        try c.encodeIfPresent(playerB2b, forKey: .playerB2b)
        try c.encodeIfPresent(rest, forKey: .rest)
        try c.encodeIfPresent(b2b, forKey: .b2b)
        try c.encodeIfPresent(nationalTv, forKey: .nationalTv)
        try c.encodeIfPresent(altitude, forKey: .altitude)
    }
}

struct StatQuery: Hashable, Encodable {
    var entity: QueryEntity
    /// Player UUID, or a team id as a string (encoded as a JSON number for teams).
    var id: String
    var scope: String
    var season: String?
    var seasonType: String
    var splits: QuerySplits
    var stat: String?
    var limit: Int?
    var lines: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case entity, id, scope, season, seasonType = "season_type", splits, stat, limit, lines
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(entity, forKey: .entity)
        if entity == .team, let teamId = Int(id) { try c.encode(teamId, forKey: .id) }
        else if !id.isEmpty { try c.encode(id, forKey: .id) }
        try c.encode(scope, forKey: .scope)
        try c.encodeIfPresent(season, forKey: .season)
        try c.encode(seasonType, forKey: .seasonType)
        try c.encode(splits, forKey: .splits)
        try c.encodeIfPresent(stat, forKey: .stat)
        try c.encodeIfPresent(limit, forKey: .limit)
        try c.encodeIfPresent(lines, forKey: .lines)
    }
}

// MARK: - Response

struct QueryResponse<T: Decodable>: Decodable {
    let data: T?
    let props: [String: PropHits]?
    let meta: QueryMeta
}

struct QueryMeta: Decodable {
    let sampleSize: Int
    let record: String?
    let notes: [String]
    let freshness: Freshness?
    let cached: Bool?
    let qualifier: Qualifier?

    struct Freshness: Decodable {
        let syncedAt: String?
        let source: String?
    }

    struct Qualifier: Decodable {
        let minGames: Int
        let teamGames: Int
        let qualifiedPlayers: Int?
        let minMinutes: Int?
    }
}

/// Per-game averages and season-sum ratios, for a player or a team. One
/// type for both (and for career rows, which add `season` / `team`); a
/// field the entity doesn't have is simply nil.
struct Averages: Decodable {
    let season: String?
    let team: String?
    let gp: Int?
    let pts, reb, ast, stl, blk, tov, fg3m: Double?
    let fgm, fga, fg3a, ftm, fta, oreb, dreb, pf: Double?
    let plusMinus: Double?
    let minutes: Double?
    let fgPct, fg3Pct, ftPct, tsPct, efgPct, ftRate: Double?
    // players
    let ptsPer36, rebPer36, astPer36, usgPct: Double?
    // teams
    let oppPts, offRtg, defRtg: Double?
}

struct CareerData: Decodable {
    let totals: Averages
    let bySeason: [Averages]
}

struct GameLogRow: Decodable, Identifiable {
    let gameId: String
    let date: String
    let season: String
    let seasonType: String
    let venue: String
    let opponent: String
    let won: Bool?
    let restDays: Int?
    let b2bNight: Int?
    let nationalTvTier: String?
    let altitude: Bool?
    // players
    let playerRestDays: Int?
    /// "player_b2b_night": convertFromSnakeCase capitalizes "b2b" as "B2B".
    let playerB2BNight: Int?
    let started: Bool?
    let minutes: Double?
    let pts, reb, ast, stl, blk, tov, fg3m, fgm, fga, fg3a, ftm, fta: Int?
    let plusMinus: Int?
    let props: [String: GradedLine]?
    // teams
    let oppPts: Int?

    var id: String { gameId }
}
