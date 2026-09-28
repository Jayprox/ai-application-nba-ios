//
//  PropsBoardViewModel.swift
//  Chalk That NBA
//
//  The Props tab (the web's pages/Props.jsx). With no date chosen the
//  server picks today if it has lines, else the next date that does;
//  the arrows jump between dates with lines (meta.prev_date / next_date).
//  Game filter and sort only reshape rows already loaded.
//
import Foundation
import Combine

@MainActor
final class PropsBoardViewModel: ObservableObject {
    struct Key: Hashable {
        var date: String?
        var market = "pts"
    }

    @Published var key = Key()
    @Published var gameFilter = "all"
    @Published var sort: PropText.Sort = .l10

    @Published private(set) var response: PropBoardResponse?
    @Published private(set) var loadedKey: Key?
    @Published private(set) var error: Error?

    var isCurrent: Bool { loadedKey == key }

    /// The date on screen: the one asked for, or the one the server picked.
    var shownDate: String? { (isCurrent ? response?.meta.date : nil) ?? key.date }

    var games: [PropBoardGame] { isCurrent ? response?.games ?? [] : [] }

    var rows: [PropBoardRow] {
        guard isCurrent, let response else { return [] }
        let game = response.games.contains { $0.id == gameFilter } ? gameFilter : "all"
        let order = Dictionary(uniqueKeysWithValues: response.games.enumerated().map { ($1.id, $0) })
        let filtered = response.data.filter { game == "all" || $0.gameId == game }
        return PropText.sortRows(filtered, by: sort, gameOrder: order)
    }

    func go(to date: String?) {
        guard let date, Format.isYmd(date) else { return }
        key.date = date
        gameFilter = "all"
    }

    func load() async {
        let requested = key
        error = nil
        do {
            let r: PropBoardResponse = try await APIClient.shared.get(Endpoints.props(date: requested.date, market: requested.market))
            guard requested == key else { return }
            response = r
            loadedKey = requested
        } catch {
            guard requested == key else { return }
            if !Task.isCancelled { self.error = error }
        }
    }
}
