//
//  LeagueViewModels.swift
//  Chalk That NBA
//
//  Leaders (the web's pages/Leaders.jsx) and Standings + bracket
//  (pages/Standings.jsx). Both default to /seasons latest_with_games.
//
import Foundation
import Combine

/// GET /seasons, shared by every season picker.
enum SeasonsLoader {
    static func load() async throws -> (seasons: [String], meta: SeasonsMeta?) {
        let envelope: APIEnvelope<[SeasonRow], SeasonsMeta> = try await APIClient.shared.get(Endpoints.seasons)
        return (envelope.data.map(\.season), envelope.meta)
    }
}

@MainActor
final class LeadersViewModel: ObservableObject {
    static let stats: [(value: String, label: String)] = [
        ("pts", "Points"), ("reb", "Rebounds"), ("ast", "Assists"), ("fg3m", "3-pointers"),
        ("stl", "Steals"), ("blk", "Blocks"), ("usg_pct", "Usage")
    ]
    /// No play-in or Cup: too few games to rank (as on the web).
    static let types: [(value: String, label: String)] = [("regular", "Regular"), ("playoffs", "Playoffs"), ("all", "All")]

    struct Key: Hashable {
        var season: String
        var seasonType = "regular"
        var stat = "pts"
    }

    @Published private(set) var seasons: [String] = []
    @Published private(set) var currentSeason: String?
    @Published var key: Key?

    private let start: (season: String?, seasonType: String?, stat: String?)

    init(season: String? = nil, seasonType: String? = nil, stat: String? = nil) {
        start = (season, seasonType, stat)
    }
    @Published private(set) var rows: [LeaderRow] = []
    @Published private(set) var meta: QueryMeta?
    @Published private(set) var loadedKey: Key?
    @Published private(set) var error: Error?

    var isCurrent: Bool { key != nil && loadedKey == key }

    func loadSeasons() async {
        guard seasons.isEmpty else { return }
        error = nil
        do {
            let result = try await SeasonsLoader.load()
            seasons = result.seasons
            currentSeason = result.meta?.currentSeason
            if key == nil, let latest = result.meta?.latestWithGames ?? result.seasons.first {
                var k = Key(season: start.season.flatMap { result.seasons.contains($0) ? $0 : nil } ?? latest)
                if let t = start.seasonType, Self.types.contains(where: { $0.value == t }) { k.seasonType = t }
                if let s = start.stat, Self.stats.contains(where: { $0.value == s }) { k.stat = s }
                key = k
            }
        } catch {
            if !Task.isCancelled { self.error = error }
        }
    }

    func load() async {
        guard let requested = key else { return }
        error = nil
        let query = StatQuery(entity: .player, id: "", scope: "leaderboard", season: requested.season,
                              seasonType: requested.seasonType, splits: QuerySplits(), stat: requested.stat, limit: 25)
        do {
            let response: QueryResponse<[LeaderRow]> = try await APIClient.shared.post(Endpoints.query, body: query)
            guard requested == key else { return }
            rows = response.data ?? []
            meta = response.meta
            loadedKey = requested
        } catch {
            guard requested == key else { return }
            if !Task.isCancelled { self.error = error }
        }
    }
}

@MainActor
final class StandingsViewModel: ObservableObject {
    enum Mode: String { case table, bracket }

    struct Key: Hashable {
        var season: String
        var view: Mode = .table
    }

    @Published private(set) var seasons: [String] = []
    @Published var key: Key?

    private let startSeason: String?
    private let startBracket: Bool

    init(season: String? = nil, bracket: Bool = false) {
        startSeason = season
        startBracket = bracket
    }

    @Published private(set) var standings: StandingsData?
    @Published private(set) var standingsMeta: StandingsMeta?
    @Published private(set) var series: [Series] = []
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
                key = Key(season: startSeason.flatMap { result.seasons.contains($0) ? $0 : nil } ?? latest,
                          view: startBracket ? .bracket : .table)
            }
        } catch {
            if !Task.isCancelled { self.error = error }
        }
    }

    func load() async {
        guard let requested = key else { return }
        error = nil
        do {
            switch requested.view {
            case .table:
                let envelope: APIEnvelope<StandingsData, StandingsMeta> = try await APIClient.shared.get(Endpoints.standings(season: requested.season))
                guard requested == key else { return }
                standings = envelope.data
                standingsMeta = envelope.meta
            case .bracket:
                let envelope: APIEnvelope<[Series], EmptyMeta> = try await APIClient.shared.get(Endpoints.bracket(season: requested.season))
                guard requested == key else { return }
                series = envelope.data
            }
            loadedKey = requested
        } catch {
            guard requested == key else { return }
            if !Task.isCancelled { self.error = error }
        }
    }
}

/// The web's `arrangeBracket`: per conference, play-in (7v8, 9v10, then
/// the game for the 8th seed), first round in classic order (1v8, 4v5,
/// 3v6, 2v7), semis by half, conference finals; the Finals separate.
/// Pure; pinned by the same test as the web (LeagueTests).
struct Bracket {
    struct Conference {
        var playIn: [Series] = []
        var first: [Series] = []
        var semis: [Series] = []
        var finals: [Series] = []
    }
    let east: Conference
    let west: Conference
    let finals: Series?

    private static let firstRoundOrder = [1: 0, 8: 0, 4: 1, 5: 1, 3: 2, 6: 2, 2: 3, 7: 3]
    private static func half(_ s: Series) -> Int { [1, 8, 4, 5].contains(s.higherSeed ?? 0) ? 0 : 1 }

    init(_ series: [Series]) {
        func by(_ round: String, _ conf: String?) -> [Series] {
            series.filter { $0.round == round && (conf == nil || $0.conference == conf) }
        }
        func conference(_ c: String) -> Conference {
            let isEighthSeedGame = { (s: Series) in (s.bracketSlot ?? "").hasSuffix("8seed") ? 1 : 0 }
            return Conference(
                playIn: by("play_in", c).stableSorted {
                    (isEighthSeedGame($0), $0.higherSeed ?? 0) < (isEighthSeedGame($1), $1.higherSeed ?? 0)
                },
                first: by("first_round", c).stableSorted {
                    (Self.firstRoundOrder[$0.higherSeed ?? 0] ?? 9) < (Self.firstRoundOrder[$1.higherSeed ?? 0] ?? 9)
                },
                semis: by("conf_semis", c).stableSorted { Self.half($0) < Self.half($1) },
                finals: by("conf_finals", c))
        }
        east = conference("East")
        west = conference("West")
        finals = by("finals", nil).first
    }

    subscript(conference: String) -> Conference { conference == "East" ? east : west }
}

extension Array {
    /// Like `sorted(by:)`, but equal elements keep their order, as JS's
    /// Array.prototype.sort does (Swift's sort isn't guaranteed stable).
    func stableSorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> [Element] {
        enumerated().sorted { a, b in
            if areInIncreasingOrder(a.element, b.element) { return true }
            if areInIncreasingOrder(b.element, a.element) { return false }
            return a.offset < b.offset
        }.map(\.element)
    }
}
