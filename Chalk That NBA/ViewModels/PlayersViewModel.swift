//
//  PlayersViewModel.swift
//  Chalk That NBA
//
//  The Players tab (the web's pages/Players.jsx): name search (typing is
//  debounced 250 ms), a team filter, and "Active only" (on by default;
//  off searches everyone since 2003-04). When "Active only" hides retired
//  matches, a second request counts them, as the web does.
//
import Foundation
import Combine

@MainActor
final class PlayersViewModel: ObservableObject {
    struct SearchKey: Hashable {
        var q = ""
        var teamId: Int?
        var activeOnly = true
    }

    /// What's in the search field; `key.q` follows it after the debounce.
    @Published var text = ""
    @Published var key = SearchKey()
    @Published private(set) var teams: [Team] = []

    @Published private(set) var players: [PlayerSearchResult] = []
    @Published private(set) var meta: PlayerSearchMeta?
    @Published private(set) var hiddenRetired = 0
    @Published private(set) var loadedKey: SearchKey?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    var isCurrent: Bool { loadedKey == key }

    /// The view's `.task(id: text)`.
    func debounceText() async {
        try? await Task.sleep(nanoseconds: 250_000_000)
        guard !Task.isCancelled else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed != key.q { key.q = trimmed }
    }

    func loadTeams() async {
        guard teams.isEmpty else { return }
        if let envelope: APIEnvelope<[Team], EmptyMeta> = try? await APIClient.shared.get(Endpoints.teams) {
            teams = envelope.data.sorted { $0.fullName < $1.fullName }
        }
    }

    /// The view's `.task(id: key)`.
    func search() async {
        let requested = key
        isLoading = true
        error = nil
        do {
            let envelope: APIEnvelope<[PlayerSearchResult], PlayerSearchMeta> = try await APIClient.shared.get(
                Endpoints.players(q: requested.q, teamId: requested.teamId, active: requested.activeOnly))
            var hidden = 0
            if requested.activeOnly, !requested.q.isEmpty, let shown = envelope.meta?.total,
               let all: APIEnvelope<[PlayerSearchResult], PlayerSearchMeta> = try? await APIClient.shared.get(
                Endpoints.players(q: requested.q, teamId: requested.teamId, active: false)),
               let total = all.meta?.total {
                hidden = max(0, total - shown)
            }
            guard requested == key else { return }
            players = envelope.data
            meta = envelope.meta
            hiddenRetired = hidden
            loadedKey = requested
        } catch {
            guard requested == key else { return }
            if !Task.isCancelled { self.error = error }
        }
        isLoading = false
    }
}
