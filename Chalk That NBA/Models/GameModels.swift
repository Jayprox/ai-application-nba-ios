//
//  GameModels.swift
//  Chalk That NBA
//
//  GET /games?date=YYYY-MM-DD (api.md §4). Enum-like fields (status,
//  season_type, national_tv_tier, cup_stage, series_round) stay Strings so
//  a new value from the server can't break decoding; Format turns them
//  into labels.
//
import Foundation

struct ScoreboardGame: Decodable, Identifiable, Hashable {
    let id: String
    let season: String
    let seasonType: String
    let cupStage: String?
    /// The home venue's local calendar date. Never convert to a Date in UTC.
    let date: String
    let tipoffUtc: String?
    let status: String
    let isNeutralSite: Bool
    let nationalTvTier: String
    let nationalBroadcasters: [String]
    let home: String
    let homeScore: Int?
    let away: String
    let awayScore: Int?
    let arena: String?
    let arenaCity: String?
    let seriesRound: String?
    let seriesGameNumber: Int?

    var isFinal: Bool { status == "final" }
    var isLive: Bool { status == "live" }
}

struct GamesMeta: Decodable {
    let date: String
    let count: Int
    let prevDate: String?
    let nextDate: String?
}
