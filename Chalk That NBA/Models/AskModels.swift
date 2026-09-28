//
//  AskModels.swift
//  Chalk That NBA
//
//  POST /ask (api.md §9). Claude only picks the query (the plan); the
//  numbers and the sentence come from the API. `view.type` says what to
//  draw; the web renderer is `View` in pages/Ask.jsx.
//
//  The response is decoded twice from the same bytes:
//  - with JSONDecoder.chalkThatNBA for everything shown (`AskAnswer`),
//  - with a plain JSONDecoder for `plan` (`AskRawPlan`), which is sent
//    back unchanged when a chip is removed or a clarification is picked.
//
import Foundation

struct AskRawPlan: Decodable {
    let plan: JSONValue?
}

struct AskChip: Decodable, Hashable {
    let key: String
    let label: String
    let removable: Bool?
}

struct AskClarify: Decodable {
    let field: String
    let options: [Option]

    struct Option: Decodable, Hashable {
        let name: String
    }
}

struct AskAnswer: Decodable {
    let sentence: String
    let cached: Bool?
    let chips: [AskChip]?
    let clarify: AskClarify?
    let link: String?
    let season: String?
    let view: AskDisplay?
}

/// A game-log row with the asking team's abbreviation (view "game").
struct AskGameRow: Decodable, Identifiable {
    let gameId: String
    let date: String
    let team: String?
    let venue: String
    let opponent: String
    let won: Bool?
    let pts: Int?
    let oppPts: Int?

    var id: String { gameId }
}

struct AskStandingRow: Decodable, Identifiable {
    let teamId: Int
    let name: String
    let conference: String?
    let rank: Int
    let wins: Int
    let losses: Int
    let gb: Double?

    var id: Int { teamId }
}

enum AskDisplay: Decodable {
    case stats(scope: String, subjectType: String, content: ExplorerResult.Content, meta: QueryMeta)
    case leaders(stat: String?, rows: [LeaderRow])
    case playerRankings([PlayerRankingRow])
    case teamRankings(stat: String?, rows: [TeamRankingRow])
    case matchups(stat: String?, rows: [MatchupRow])
    case props(upcoming: PlayerProps.Upcoming?, market: String?, hits: PropHits?, record: PlayerProps.RecordLine?)
    case standings([AskStandingRow])
    case game([AskGameRow])
    case series([Series])
    case unsupported
    case clarify
    case other

    private enum Keys: String, CodingKey {
        case type, query, stat, rows, upcoming, market, hits, record, games
    }

    private struct StatsHead: Decodable {
        struct Q: Decodable { let scope: String? }
        struct S: Decodable { let type: String? }
        let query: Q?
        let subject: S?
        let meta: QueryMeta
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        switch try c.decode(String.self, forKey: .type) {
        case "stats":
            let head = try c.decode(StatsHead.self, forKey: .query)
            let scope = head.query?.scope ?? "season"
            let content: ExplorerResult.Content
            switch scope {
            case "career": content = .career(try c.decode(QueryResponse<CareerData>.self, forKey: .query).data)
            case "game_log": content = .gameLog(try c.decode(QueryResponse<[GameLogRow]>.self, forKey: .query).data ?? [])
            default: content = .averages(try c.decode(QueryResponse<Averages>.self, forKey: .query).data)
            }
            self = .stats(scope: scope, subjectType: head.subject?.type ?? "player", content: content, meta: head.meta)
        case "leaders":
            self = .leaders(stat: try c.decodeIfPresent(String.self, forKey: .stat),
                            rows: try c.decodeIfPresent([LeaderRow].self, forKey: .rows) ?? [])
        case "player_rankings":
            self = .playerRankings(try c.decodeIfPresent([PlayerRankingRow].self, forKey: .rows) ?? [])
        case "team_rankings":
            self = .teamRankings(stat: try c.decodeIfPresent(String.self, forKey: .stat),
                                 rows: try c.decodeIfPresent([TeamRankingRow].self, forKey: .rows) ?? [])
        case "matchups":
            self = .matchups(stat: try c.decodeIfPresent(String.self, forKey: .stat),
                             rows: try c.decodeIfPresent([MatchupRow].self, forKey: .rows) ?? [])
        case "props":
            self = .props(upcoming: try c.decodeIfPresent(PlayerProps.Upcoming.self, forKey: .upcoming),
                          market: try c.decodeIfPresent(String.self, forKey: .market),
                          hits: try c.decodeIfPresent(PropHits.self, forKey: .hits),
                          record: try c.decodeIfPresent(PlayerProps.RecordLine.self, forKey: .record))
        case "standings":
            self = .standings(try c.decodeIfPresent([AskStandingRow].self, forKey: .rows) ?? [])
        case "game":
            self = .game(try c.decodeIfPresent([AskGameRow].self, forKey: .games) ?? [])
        case "series":
            self = .series(try c.decodeIfPresent([Series].self, forKey: .rows) ?? [])
        case "unsupported":
            self = .unsupported
        case "clarify":
            self = .clarify
        default:
            self = .other
        }
    }
}

enum AskText {
    /// The web's EXAMPLES.
    static let examples = [
        "Jokić on the second night of back-to-backs",
        "Brunson on the road last 10 games",
        "who leads the league in steals",
        "which teams give up the most points to centers",
        "has Edwards gone over 27.5 points lately",
        "Knicks record"
    ]

    static let rounds = ["play_in": "Play-In", "first_round": "First round", "conf_semis": "Conf. semis",
                         "conf_finals": "Conf. finals", "finals": "Finals"]

    /// Series result like the web: "BOS 4-1" when decided, "2-1" in progress.
    static func seriesResult(_ x: Series) -> String {
        let hw = x.higherWins ?? 0, lw = x.lowerWins ?? 0
        guard let winner = x.winnerTeamId else { return "\(hw)-\(lw)" }
        let abbr = winner == x.higherId ? (x.higherAbbr ?? "") : (x.lowerAbbr ?? "")
        return "\(abbr) \(max(hw, lw))-\(min(hw, lw))"
    }

    static func seriesRound(_ x: Series) -> String {
        (rounds[x.round] ?? x.round) + (x.conference != nil && x.round != "finals" ? " (\(x.conference!))" : "")
    }
}
