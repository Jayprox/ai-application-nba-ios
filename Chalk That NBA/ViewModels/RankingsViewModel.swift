//
//  RankingsViewModel.swift
//  Chalk That NBA
//
//  The web's pages/Rankings.jsx: three views (Players / Teams /
//  Matchups), each for a season, Regular / Playoffs, and Season / Last 10;
//  players and matchups by position (G / F / C). Teams and matchups have a
//  "Rank by" choice that only re-sorts rows already loaded.
//
import Foundation
import Combine

@MainActor
final class RankingsViewModel: ObservableObject {
    static let views: [(value: String, label: String)] = [("players", "Players"), ("teams", "Teams"), ("matchups", "Matchups")]
    static let types: [(value: String, label: String)] = [("regular", "Regular"), ("playoffs", "Playoffs")]
    static let scopes: [(value: String, label: String)] = [("season", "Season"), ("last10", "Last 10")]
    static let positions: [(value: String, label: String)] = [("G", "Guards"), ("F", "Forwards"), ("C", "Centers")]
    static let teamSorts: [(value: String, label: String)] = [("net_rtg", "Net rating"), ("off_rtg", "Offense"), ("def_rtg", "Defense"), ("pace", "Pace")]
    static let matchupStats: [(value: String, label: String)] = [("pts", "Points"), ("reb", "Rebounds"), ("ast", "Assists"), ("fg3m", "3PM")]
    static let zLabel = ["pts": "PTS", "reb": "REB", "ast": "AST", "stl": "STL", "blk": "BLK", "fg3m": "3PM", "ts_pct": "TS%", "tov": "TOV"]

    struct Key: Hashable {
        var view = "players"
        var season: String
        var seasonType = "regular"
        var scope = "season"
        var position = "G"
    }

    @Published private(set) var seasons: [String] = []
    @Published var key: Key?

    private let start: (view: String?, season: String?, position: String?, sort: String?, scope: String?)

    init(view: String? = nil, season: String? = nil, position: String? = nil, sort: String? = nil, scope: String? = nil) {
        start = (view, season, position, sort, scope)
        if view == "teams", let sort, Self.teamSorts.contains(where: { $0.value == sort }) { teamSort = sort }
        if view == "matchups", let sort, Self.matchupStats.contains(where: { $0.value == sort }) { matchupSort = sort }
    }
    @Published var teamSort = "net_rtg"
    @Published var matchupSort = "pts"

    @Published private(set) var players: [PlayerRankingRow] = []
    @Published private(set) var playersMeta: PlayerRankingsMeta?
    @Published private(set) var teams: [TeamRankingRow] = []
    @Published private(set) var teamNotes: [String] = []
    @Published private(set) var matchups: MatchupsData?
    @Published private(set) var loadedKey: Key?
    @Published private(set) var error: Error?

    var isCurrent: Bool { key != nil && loadedKey == key }

    func loadSeasons() async {
        guard seasons.isEmpty else { return }
        error = nil
        do {
            let result = try await SeasonsLoader.load()
            seasons = result.seasons
            if key == nil, let latest = result.meta?.latestWithGames ?? result.seasons.first {
                var k = Key(season: start.season.flatMap { result.seasons.contains($0) ? $0 : nil } ?? latest)
                if let v = start.view, Self.views.contains(where: { $0.value == v }) { k.view = v }
                if let p = start.position, Self.positions.contains(where: { $0.value == p }) { k.position = p }
                if let s = start.scope, Self.scopes.contains(where: { $0.value == s }) { k.scope = s }
                key = k
            }
        } catch {
            if !Task.isCancelled { self.error = error }
        }
    }

    func load() async {
        guard let k = key else { return }
        error = nil
        do {
            switch k.view {
            case "teams":
                let e: APIEnvelope<[TeamRankingRow], NotesMeta> = try await APIClient.shared.get(
                    Endpoints.teamRankings(season: k.season, seasonType: k.seasonType, scope: k.scope))
                guard k == key else { return }
                teams = e.data
                teamNotes = e.meta?.notes ?? []
            case "matchups":
                let m: MatchupsData = try await APIClient.shared.get(
                    Endpoints.matchups(season: k.season, seasonType: k.seasonType, scope: k.scope))
                guard k == key else { return }
                matchups = m
            default:
                let e: APIEnvelope<[PlayerRankingRow], PlayerRankingsMeta> = try await APIClient.shared.get(
                    Endpoints.playerRankings(season: k.season, seasonType: k.seasonType, scope: k.scope, position: k.position))
                guard k == key else { return }
                players = e.data
                playersMeta = e.meta
            }
            loadedKey = k
        } catch {
            guard k == key else { return }
            if !Task.isCancelled { self.error = error }
        }
    }

    /// Teams sorted by the chosen rank (rank 1 first), then abbreviation.
    var sortedTeams: [TeamRankingRow] {
        teams.stableSorted { a, b in
            let ra = a.rank(teamSort) ?? 99, rb = b.rank(teamSort) ?? 99
            return ra != rb ? ra < rb : a.abbr < b.abbr
        }
    }

    /// One position's defenses sorted by the chosen stat's rank, then abbreviation.
    func sortedMatchups(_ position: String) -> [MatchupRow] {
        (matchups?.data[position] ?? []).stableSorted { a, b in
            let ra = (a.rank[matchupSort] ?? nil) ?? 99, rb = (b.rank[matchupSort] ?? nil) ?? 99
            return ra != rb ? ra < rb : a.abbr < b.abbr
        }
    }
}
