//
//  BoxScoreModels.swift
//  Chalk That NBA
//
//  GET /games/:id (api.md §4): `{ data: { game, teams } }`. `teams[0]` is
//  the AWAY team. Players arrive starters first, then by minutes, DNPs
//  last. Every stat is optional: null means unknown and shows blank,
//  never 0.
//
import Foundation

struct BoxScore: Decodable {
    let game: BoxScoreGame
    let teams: [BoxScoreTeam]
}

struct BoxScoreGame: Decodable {
    let id: String
    let season: String
    let seasonType: String
    let cupStage: String?
    let seriesGameNumber: Int?
    let gameDateLocal: String
    let tipoffUtc: String?
    let isNeutralSite: Bool
    let nationalTvTier: String
    let nationalBroadcasters: [String]
    let status: String
    let homeScore: Int?
    let awayScore: Int?
    let arena: String?
    let arenaCity: String?
    let isHighAltitude: Bool?

    var isFinal: Bool { status == "final" }
    var isLive: Bool { status == "live" }
}

/// Team totals plus its players. The stat fields are shared with
/// `BoxScorePlayer` through `BoxScoreLine` so one table renders both.
struct BoxScoreTeam: Decodable, Identifiable {
    let teamId: Int
    let abbreviation: String
    let fullName: String
    let venueSplit: String
    let restDays: Int?
    let b2bNight: Int?
    let won: Bool?
    let minutes: Double?
    let pts, reb, ast, stl, blk, tov: Int?
    let fgm, fga, fg3m, fg3a, ftm, fta: Int?
    let plusMinus: Int?
    let players: [BoxScorePlayer]

    var id: Int { teamId }
}

struct BoxScorePlayer: Decodable, Identifiable {
    let playerId: String
    let fullName: String
    let teamId: Int
    let started: Bool?
    let dnp: Bool
    let dnpReason: String?
    let minutes: Double?
    let pts, reb, ast, stl, blk, tov: Int?
    let fgm, fga, fg3m, fg3a, ftm, fta: Int?
    let plusMinus: Int?
    let playerRestDays: Int?
    /// "player_b2b_night" -> playerB2BNight (see QueryModels.swift).
    let playerB2BNight: Int?

    var id: String { playerId }
}

protocol BoxScoreLine {
    var minutes: Double? { get }
    var pts: Int? { get }
    var reb: Int? { get }
    var ast: Int? { get }
    var stl: Int? { get }
    var blk: Int? { get }
    var tov: Int? { get }
    var fgm: Int? { get }
    var fga: Int? { get }
    var fg3m: Int? { get }
    var fg3a: Int? { get }
    var ftm: Int? { get }
    var fta: Int? { get }
    var plusMinus: Int? { get }
}

extension BoxScoreTeam: BoxScoreLine {}
extension BoxScorePlayer: BoxScoreLine {}
