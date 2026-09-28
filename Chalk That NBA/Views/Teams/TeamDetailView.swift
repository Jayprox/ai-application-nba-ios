//
//  TeamDetailView.swift
//  Chalk That NBA
//
//  The web's pages/TeamDetail.jsx: name, "Western Conference · Northwest ·
//  Ball Arena" (+ "Altitude arena · 5,280 ft"), the stat explorer in team
//  mode (default season = /seasons latest_with_games), then two sections
//  that follow the explorer's season and type:
//    - Defense by position (GET /rankings/matchups; regular or playoffs)
//    - the season roster, everyone who played for them, trades included
//      (GET /teams/:id/players). Names open that player on the same
//      season and type.
//
import SwiftUI

struct TeamDetailView: View {
    @StateObject private var vm: TeamDetailViewModel

    init(teamId: Int) {
        _vm = StateObject(wrappedValue: TeamDetailViewModel(teamId: teamId))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let team = vm.team, vm.loaded {
                    header(team)
                    if let latest = vm.latestSeason {
                        StatExplorerView(
                            entity: .team, id: String(team.id), name: "the \(team.fullName)",
                            seasons: vm.seasons, seasonTypes: team.seasonTypes, startSeason: latest
                        ) { filters in
                            vm.season = filters.season
                            vm.seasonType = filters.seasonType
                        }
                        if let season = vm.season ?? vm.latestSeason {
                            DefenseByPositionView(teamId: team.id, teamName: team.name ?? team.fullName,
                                                  season: season, seasonType: vm.seasonType)
                            TeamRosterView(teamId: team.id, teamName: team.name ?? team.fullName,
                                           season: season, seasonType: vm.seasonType)
                        }
                    } else {
                        EmptyCard { Text("No finished games loaded yet.") }
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
        .navigationTitle(vm.team?.fullName ?? "Team")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }

    private func header(_ team: TeamDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(team.fullName)
                .font(.brandDisplay(38, weight: .bold, relativeTo: .largeTitle))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(team.subtitle)
                .font(.brandBody(.body))
                .foregroundStyle(Color.muted)
            if team.isHighAltitude == true {
                Text("Altitude arena" + (team.elevationFt.map { " · \(Format.thousands($0)) ft" } ?? ""))
                    .font(.brandBody(.caption, weight: .semibold))
                    .foregroundStyle(Color.altInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.altBg)
                    .clipShape(Capsule())
            }
        }
    }
}

/// Section title in the web's style: big display title + small muted note.
struct SectionTitle: View {
    let title: String
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.brandDisplay(26, weight: .bold, relativeTo: .title2))
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            Text(note)
                .font(.brandBody(.footnote))
                .foregroundStyle(Color.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
