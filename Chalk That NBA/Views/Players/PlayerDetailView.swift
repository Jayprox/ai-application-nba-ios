//
//  PlayerDetailView.swift
//  Chalk That NBA
//
//  The core screen (the web's pages/PlayerDetail.jsx): name, a line of
//  bio (position · team · height · weight · Retired), the injury badge
//  (hidden while `current_injury` is null, which is always for now), and
//  the stat explorer.
//
import SwiftUI

struct PlayerDetailView: View {
    @StateObject private var vm: PlayerDetailViewModel

    init(playerId: String) {
        _vm = StateObject(wrappedValue: PlayerDetailViewModel(playerId: playerId))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let player = vm.player {
                    header(player)
                    if player.seasons.isEmpty {
                        EmptyCard { Text("No games for \(player.fullName) since 2003-04 (where our stats begin).") }
                    } else if vm.propsSettled {
                        StatExplorerView(
                            entity: .player, id: player.id, name: player.fullName,
                            seasons: player.seasons, seasonTypes: player.seasonTypes,
                            props: vm.props
                        )
                    } else {
                        LoadingCard(label: "Crunching…")
                    }
                } else if let error = vm.error {
                    if ErrorCard.isNotFound(error) {
                        ErrorCard(error: error)
                    } else {
                        ErrorCard(error: error) { Task { await vm.load() } }
                    }
                } else {
                    LoadingCard()
                }
            }
            .padding(16)
        }
        .background(Color.paper)
        .navigationTitle(vm.player?.fullName ?? "Player")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }

    private func header(_ player: PlayerDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(player.fullName)
                .font(.brandDisplay(38, weight: .bold, relativeTo: .largeTitle))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if !player.subtitle.isEmpty {
                Text(player.subtitle)
                    .font(.brandBody(.body))
                    .foregroundStyle(Color.muted)
            }
            if let injury = player.currentInjury {
                Text(injury.status + (injury.description.map { " — \($0)" } ?? ""))
                    .font(.brandBody(.subheadline, weight: .semibold))
                    .foregroundStyle(Color.altInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.altBg)
                    .clipShape(Capsule())
            }
        }
    }
}
