//
//  PlayersView.swift
//  Chalk That NBA
//
//  The Players tab (the web's pages/Players.jsx): search by name, filter
//  by team, "Active only" on by default. Wording matches the web,
//  including the truncation line ("Showing the first 100 of N players —
//  type a name to narrow it down") and the retired-hidden hint.
//
import SwiftUI

struct PlayersView: View {
    @StateObject private var vm = PlayersViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                filters
                content
            }
            .padding(16)
        }
        .background(Color.paper)
        .navigationTitle("Players")
        .searchable(text: $vm.text, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Try \"jokic\", \"cook\" or \"lebron\"")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .task(id: vm.text) { await vm.debounceText() }
        .task(id: vm.key) { await vm.search() }
        .task { await vm.loadTeams() }
        .refreshable { await vm.search() }
    }

    // MARK: - Filters

    private var teamName: String {
        vm.key.teamId.flatMap { id in vm.teams.first { $0.id == id }?.fullName } ?? "All teams"
    }

    private var filters: some View {
        HStack(spacing: 10) {
            Menu {
                Button("All teams") { vm.key.teamId = nil }
                ForEach(vm.teams) { team in
                    Button(team.fullName) { vm.key.teamId = team.id }
                }
            } label: {
                HStack {
                    Text(teamName).lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.up.chevron.down").font(.caption)
                }
                .font(.brandBody(.subheadline))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.field, lineWidth: 1))
            }
            .accessibilityLabel("Team: \(teamName)")

            Toggle(isOn: $vm.key.activeOnly) {
                Text("Active only")
                    .font(.brandBody(.subheadline, weight: .semibold))
                    .foregroundStyle(Color.ink)
            }
            .toggleStyle(.switch)
            .tint(Color.accent)
            .fixedSize()
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Color.card)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.field, lineWidth: 1))
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var content: some View {
        if vm.isCurrent, let meta = vm.meta {
            Text(countLine(meta))
                .font(.brandBody(.footnote))
                .foregroundStyle(Color.muted)
            if vm.players.isEmpty {
                EmptyCard {
                    Text(vm.hiddenRetired > 0
                         ? "No active players match. Turn off \"Active only\" to include retired players (2003-04 onward)."
                         : "No players match that name.")
                }
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(vm.players) { player in
                        NavigationLink(value: AppRoute.player(id: player.id)) {
                            PlayerRow(player: player)
                        }
                        .buttonStyle(.plain)
                        if player.id != vm.players.last?.id {
                            Rectangle().fill(Color.rule).frame(height: 1)
                        }
                    }
                }
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        } else if let error = vm.error {
            ErrorCard(error: error) { Task { await vm.search() } }
        } else {
            LoadingCard(label: "Searching…")
        }
    }

    private func countLine(_ meta: PlayerSearchMeta) -> String {
        var line = meta.truncated
            ? "Showing the first \(vm.players.count) of \(meta.total) players — type a name to narrow it down"
            : "\(meta.total) player\(meta.total == 1 ? "" : "s")"
        if vm.hiddenRetired > 0 { line += " · \(vm.hiddenRetired) retired hidden by \"Active only\"" }
        return line
    }
}

private struct PlayerRow: View {
    let player: PlayerSearchResult

    private var detail: String {
        [player.team, player.listedPosition].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.brandBody(.body, weight: .semibold))
                    .foregroundStyle(Color.link)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.brandBody(.subheadline))
                        .foregroundStyle(Color.muted)
                }
            }
            Spacer()
            Text(player.isActive ? "Active" : "Retired")
                .font(.brandBody(.footnote, weight: .semibold))
                .foregroundStyle(player.isActive ? Color.positive : Color.muted)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(player.isActive ? Color.positiveBg : Color.card2)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
