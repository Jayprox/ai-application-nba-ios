//
//  TeamRosterView.swift
//  Chalk That NBA
//
//  "{season} roster" on team detail (TeamDetail.jsx `Roster`): everyone
//  who played for the team in the explorer's season and type, trades
//  included, sorted by points (the API's order). Tapping a name opens him
//  on that same season and type.
//
import SwiftUI

struct TeamRosterView: View {
    let teamId: Int
    let teamName: String
    let season: String
    let seasonType: String

    @StateObject private var vm = TeamRosterViewModel()

    private var key: TeamRosterViewModel.Key { .init(season: season, seasonType: seasonType) }
    private var typeText: String { Format.seasonTypeLower(seasonType) ?? seasonType }

    private let columns: [DataTable.Column] = [
        .init(title: "GP", width: 32), .init(title: "Min", width: 40), .init(title: "Pts", width: 40, bold: true),
        .init(title: "Reb", width: 40), .init(title: "Ast", width: 40)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "\(season) roster", note: "Everyone who played for the \(teamName) (\(typeText))")
            if vm.loadedKey == key {
                if vm.players.isEmpty {
                    EmptyCard { Text("No \(typeText) games for the \(teamName) in \(season).") }
                } else {
                    DataTable(pinnedTitle: "Player", pinnedWidth: 160, columns: columns, rows: vm.players.map { p in
                        DataTable.Row(
                            id: p.playerId, pinned: p.fullName,
                            cells: [String(p.gp), Format.avg(p.minutes), Format.avg(p.pts), Format.avg(p.reb), Format.avg(p.ast)],
                            route: .player(id: p.playerId, season: season, seasonType: seasonType),
                            spoken: "\(p.fullName), \(p.gp) games, \(Format.avg(p.pts)) points, \(Format.avg(p.reb)) rebounds, \(Format.avg(p.ast)) assists")
                    })
                }
            } else if let error = vm.error {
                ErrorCard(error: error) { Task { await vm.load(teamId: teamId, key: key) } }
            } else {
                LoadingCard()
            }
        }
        .task(id: key) { await vm.load(teamId: teamId, key: key) }
    }
}
