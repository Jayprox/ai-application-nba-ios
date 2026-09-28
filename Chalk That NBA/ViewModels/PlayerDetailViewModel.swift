//
//  PlayerDetailViewModel.swift
//  Chalk That NBA
//
//  GET /players/:id and GET /players/:id/props together (the web's
//  pages/PlayerDetail.jsx). Props are optional: if that call fails the
//  page works without them. The stat explorer waits for props to settle
//  so its first query already carries tonight's lines (one request, not
//  two), as the web does.
//
import Foundation
import Combine

@MainActor
final class PlayerDetailViewModel: ObservableObject {
    let playerId: String
    @Published private(set) var player: PlayerDetail?
    @Published private(set) var props: PlayerProps?
    @Published private(set) var propsSettled = false
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    init(playerId: String) {
        self.playerId = playerId
    }

    func load() async {
        guard player == nil else { return }
        isLoading = true
        error = nil
        async let detail: APIEnvelope<PlayerDetail, EmptyMeta> = APIClient.shared.get(Endpoints.player(playerId))
        async let lines = fetchProps()
        do {
            player = try await detail.data
        } catch {
            if !Task.isCancelled { self.error = error }
        }
        props = await lines
        propsSettled = true
        isLoading = false
    }

    private func fetchProps() async -> PlayerProps? {
        let envelope: APIEnvelope<PlayerProps, EmptyMeta>? = try? await APIClient.shared.get(Endpoints.playerProps(playerId))
        return envelope?.data
    }
}
