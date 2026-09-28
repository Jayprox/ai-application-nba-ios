//
//  BoxScoreViewModel.swift
//  Chalk That NBA
//
//  GET /games/:id. Re-fetches every ~60 s while the game is live.
//
import Foundation
import Combine

@MainActor
final class BoxScoreViewModel: ObservableObject {
    let gameId: String
    @Published private(set) var box: BoxScore?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    init(gameId: String) {
        self.gameId = gameId
    }

    var isLive: Bool { box?.game.isLive ?? false }

    func run() async {
        if box == nil { await load(quietly: false) }
        await LivePolling.run(isLive: { [weak self] in self?.isLive ?? false }) { [weak self] in
            await self?.load(quietly: true)
        }
    }

    func load(quietly: Bool) async {
        if !quietly {
            isLoading = true
            error = nil
        }
        do {
            let envelope: APIEnvelope<BoxScore, EmptyMeta> = try await APIClient.shared.get(Endpoints.game(gameId))
            box = envelope.data
            error = nil
        } catch {
            if !quietly, !Task.isCancelled { self.error = error }
        }
        isLoading = false
    }
}
