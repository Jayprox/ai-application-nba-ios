//
//  StatExplorerViewModel.swift
//  Chalk That NBA
//
//  One POST /query for whatever the explorer's controls say (the web's
//  components/StatExplorer.jsx). A result is shown only while it belongs
//  to the current controls (`resultQuery == currentQuery`), so switching
//  scope never paints the old scope's data in the new layout: the iOS
//  version of the stale-state crash PLATFORM.md §2 describes.
//
import Foundation
import Combine

struct ExplorerResult {
    enum Content {
        case averages(Averages?)
        case career(CareerData?)
        case gameLog([GameLogRow])
    }
    let content: Content
    let meta: QueryMeta
    let props: [String: PropHits]?
}

@MainActor
final class StatExplorerViewModel: ObservableObject {
    let entity: QueryEntity
    let id: String
    let name: String
    let seasons: [String]
    let seasonTypes: [String: [String]]
    /// Tonight's DraftKings lines (players with an upcoming game), graded
    /// over the selected games via POST /query `lines`.
    let lines: [String: Double]?

    @Published var filters: ExplorerFilters
    @Published private(set) var result: ExplorerResult?
    @Published private(set) var resultQuery: StatQuery?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    /// `startSeason` / `startType` open on those filters when valid (a
    /// roster link); otherwise the newest season, regular season.
    init(entity: QueryEntity, id: String, name: String, seasons: [String],
         seasonTypes: [String: [String]], lines: [String: Double]?,
         startSeason: String? = nil, startType: String? = nil, startFilters: ExplorerFilters? = nil) {
        self.entity = entity
        self.id = id
        self.name = name
        self.seasons = seasons
        self.seasonTypes = seasonTypes
        self.lines = lines
        var filters = startFilters ?? ExplorerFilters()
        let wanted = startFilters?.season ?? startSeason
        filters.season = wanted.flatMap { seasons.contains($0) ? $0 : nil } ?? startSeason.flatMap { seasons.contains($0) ? $0 : nil } ?? seasons.first
        if entity == .team { filters.restBy = "player" }
        if let startType, ExplorerFilters.seasonTypes.contains(where: { $0.value == startType }) {
            filters.seasonType = startType
        }
        self.filters = filters
    }

    var currentQuery: StatQuery { filters.query(entity: entity, id: id, lines: lines) }
    var isCurrent: Bool { resultQuery == currentQuery }

    /// The season types played that season (nil for career), for the
    /// "didn't play in the playoffs" empty state.
    var playedTypes: [String]? {
        filters.scope == "career" ? nil : filters.season.flatMap { seasonTypes[$0] }
    }

    func load() async {
        let query = currentQuery
        isLoading = true
        error = nil
        do {
            let fetched = try await fetch(query)
            guard query == currentQuery else { return }
            result = fetched
            resultQuery = query
        } catch {
            guard query == currentQuery else { return }
            if !Task.isCancelled { self.error = error }
        }
        isLoading = false
    }

    private func fetch(_ query: StatQuery) async throws -> ExplorerResult {
        switch query.scope {
        case "career":
            let r: QueryResponse<CareerData> = try await APIClient.shared.post(Endpoints.query, body: query)
            return ExplorerResult(content: .career(r.data), meta: r.meta, props: r.props)
        case "game_log":
            let r: QueryResponse<[GameLogRow]> = try await APIClient.shared.post(Endpoints.query, body: query)
            return ExplorerResult(content: .gameLog(r.data ?? []), meta: r.meta, props: r.props)
        default:
            let r: QueryResponse<Averages> = try await APIClient.shared.post(Endpoints.query, body: query)
            return ExplorerResult(content: .averages(r.data), meta: r.meta, props: r.props)
        }
    }
}
