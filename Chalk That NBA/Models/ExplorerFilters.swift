//
//  ExplorerFilters.swift
//  Chalk That NBA
//
//  The stat explorer's controls (ios-kickoff.md §4), mirroring the web's
//  StatExplorer.jsx: season, season type, scope, "rest measured by", and
//  five splits. `query(...)` is a port of the web's `buildQuery()` and is
//  pinned by the same tests (ExplorerFiltersTests).
//
import Foundation

struct ExplorerFilters: Hashable {
    var season: String?
    var seasonType = "regular"
    var scope = "season"
    /// "player" (his games, the default) or "team" (team's schedule). Players only.
    var restBy = "player"
    var venue: String?       // home | away
    var b2b: String?         // 1 | 2
    var rest: String?        // 0 | 1 | 2 | 3+
    var tv: String?          // major | nba_tv | local
    var alt: String?         // yes | no

    static let seasonTypes: [(value: String, label: String)] = [
        ("regular", "Regular"), ("play_in", "Play-In"), ("playoffs", "Playoffs"), ("all", "All"), ("cup", "NBA Cup")
    ]

    static let scopes: [(value: String, label: String)] = [
        ("season", "Season Avg"), ("last5", "Last 5"), ("last10", "Last 10"), ("career", "Career"), ("game_log", "Game Log")
    ]

    static let scopeLabel = ["season": "Season average", "last5": "Last 5 games", "last10": "Last 10 games",
                             "career": "Career", "game_log": "Game log"]

    enum Split: String, CaseIterable {
        case venue, b2b, rest, tv, alt

        var label: String {
            switch self {
            case .venue: return "Venue"
            case .b2b: return "Back-to-back"
            case .rest: return "Rest days"
            case .tv: return "National TV"
            case .alt: return "Altitude"
            }
        }

        /// (value, label); "all" means the split is off.
        var options: [(value: String, label: String)] {
            switch self {
            case .venue: return [("all", "All"), ("home", "Home"), ("away", "Away")]
            case .b2b: return [("all", "All"), ("1", "Night 1"), ("2", "Night 2")]
            case .rest: return [("all", "All"), ("0", "0"), ("1", "1"), ("2", "2"), ("3+", "3+")]
            case .tv: return [("all", "All"), ("major", "Major"), ("nba_tv", "NBA TV"), ("local", "Local")]
            case .alt: return [("all", "All"), ("yes", "At altitude"), ("no", "Not")]
            }
        }
    }

    subscript(split: Split) -> String? {
        get {
            switch split {
            case .venue: return venue
            case .b2b: return b2b
            case .rest: return rest
            case .tv: return tv
            case .alt: return alt
            }
        }
        set {
            let value = newValue == "all" ? nil : newValue
            switch split {
            case .venue: venue = value
            case .b2b: b2b = value
            case .rest: rest = value
            case .tv: tv = value
            case .alt: alt = value
            }
        }
    }

    var splitCount: Int { Split.allCases.filter { self[$0] != nil }.count }

    mutating func clearSplits() {
        for split in Split.allCases { self[split] = nil }
    }

    /// "2003-04 regular season", or "regular season" for career (the web's `where`).
    var whereText: String {
        let type = Format.seasonTypeLower(seasonType) ?? seasonType
        return scope == "career" ? type : "\(season ?? "") \(type)"
    }

    /// Port of buildQuery(entity, id, p, lines): the POST /query body.
    func query(entity: QueryEntity, id: String, lines: [String: Double]? = nil) -> StatQuery {
        let byPlayer = entity == .player && restBy != "team"
        var splits = QuerySplits()
        splits.venue = venue
        if let b2b, let night = Int(b2b) {
            if byPlayer { splits.playerB2b = night } else { splits.b2b = night }
        }
        if let rest {
            let value: RestValue? = rest == "3+" ? .threePlus : Int(rest).map(RestValue.days)
            if byPlayer { splits.playerRest = value } else { splits.rest = value }
        }
        splits.nationalTv = tv
        if let alt { splits.altitude = alt == "yes" }

        var body = StatQuery(entity: entity, id: id, scope: scope, season: nil, seasonType: seasonType, splits: splits)
        if scope != "career" { body.season = season }
        if entity == .player, let lines, !lines.isEmpty, scope != "game_log" { body.lines = lines }
        return body
    }
}
