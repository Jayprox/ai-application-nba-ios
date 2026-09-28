//
//  ScoreboardViewModel.swift
//  Chalk That NBA
//
//  GET /games?date= for one calendar date. The date defaults to the
//  viewer's today (the web's `todayLocal()`); the arrows jump to
//  meta.prev_date / next_date, which skip days without games.
//
//  Stale-response guard (PLATFORM.md §2's lesson, iOS edition): games are
//  shown only when `loadedDate == date`, and a response for a date the
//  user has already left is dropped, so a slow request can never paint
//  one day's games under another day's title.
//
import Foundation
import Combine

@MainActor
final class ScoreboardViewModel: ObservableObject {
    @Published var date: String = Format.todayLocal()
    @Published private(set) var games: [ScoreboardGame] = []
    @Published private(set) var meta: GamesMeta?
    @Published private(set) var loadedDate: String?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    /// True when what's on screen belongs to the selected date.
    var isCurrent: Bool { loadedDate == date }
    var hasLiveGames: Bool { isCurrent && games.contains(where: \.isLive) }

    func go(to newDate: String?) {
        guard let newDate, Format.isYmd(newDate), newDate != date else { return }
        date = newDate
    }

    /// The view's `.task(id: date)`: load, then keep live scores fresh.
    /// Coming back to a date that's already on screen refreshes quietly
    /// (no spinner over the games).
    func run() async {
        await load(quietly: isCurrent)
        await LivePolling.run(isLive: { [weak self] in self?.hasLiveGames ?? false }) { [weak self] in
            await self?.load(quietly: true)
        }
    }

    func load(quietly: Bool) async {
        let requested = date
        if !quietly {
            isLoading = true
            error = nil
        }
        do {
            let envelope: APIEnvelope<[ScoreboardGame], GamesMeta> = try await APIClient.shared.get(Endpoints.games(date: requested))
            guard requested == date else { return }
            games = envelope.data
            meta = envelope.meta
            loadedDate = requested
            error = nil
        } catch {
            guard requested == date else { return }
            // A cancelled request (the screen went away) isn't an error to show.
            if !quietly, !Task.isCancelled { self.error = error }
        }
        isLoading = false
    }
}
