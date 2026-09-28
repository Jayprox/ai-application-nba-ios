//
//  TeamsView.swift
//  Chalk That NBA
//
//  All 30 teams by conference, then division (the web's pages/Teams.jsx),
//  with the "Altitude arena" tag and the web's footnote.
//
import SwiftUI

struct TeamsView: View {
    @StateObject private var vm = TeamsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if vm.loaded {
                    ForEach(vm.conferences, id: \.name) { conf in
                        VStack(alignment: .leading, spacing: 14) {
                            Text(conf.name)
                                .font(.brandDisplay(28, weight: .bold, relativeTo: .title))
                                .foregroundStyle(Color.ink)
                                .padding(.bottom, 4)
                                .overlay(alignment: .bottom) { Rectangle().fill(Color.strong).frame(height: 3) }
                                .accessibilityAddTraits(.isHeader)
                            ForEach(conf.divisions, id: \.name) { division in
                                VStack(alignment: .leading, spacing: 6) {
                                    SectionLabel(text: division.name)
                                    teamList(division.teams)
                                }
                            }
                        }
                    }
                    Text("\"Altitude arena\" = home arena at 4,000 ft or higher (\(vm.altitudeCities.joined(separator: ", "))). The altitude split also counts road games there and in Mexico City.")
                        .font(.brandBody(.footnote))
                        .foregroundStyle(Color.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let error = vm.error {
                    ErrorCard(error: error) { Task { await vm.load() } }
                } else {
                    LoadingCard()
                }
            }
            .padding(16)
        }
        .background(Color.paper)
        .navigationTitle("Teams")
        .task { if !vm.loaded { await vm.load() } }
    }

    private func teamList(_ teams: [Team]) -> some View {
        VStack(spacing: 0) {
            ForEach(teams) { team in
                NavigationLink(value: AppRoute.team(id: team.id)) {
                    HStack(spacing: 12) {
                        Text(team.fullName)
                            .font(.brandBody(.body, weight: .semibold))
                            .foregroundStyle(Color.link)
                        Spacer()
                        if team.isHighAltitude == true {
                            Text("Altitude arena")
                                .font(.brandBody(.caption, weight: .semibold))
                                .foregroundStyle(Color.altInk)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.altBg)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if team.id != teams.last?.id {
                    Rectangle().fill(Color.rule).frame(height: 1)
                }
            }
        }
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
