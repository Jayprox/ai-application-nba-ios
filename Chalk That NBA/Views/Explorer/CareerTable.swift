//
//  CareerTable.swift
//  Chalk That NBA
//
//  Career by season, newest first, plus a Career totals row (the web's
//  `Career`, player version): Season | Team GP Min Pts Reb Ast 3PM Stl
//  Blk TO FG% TS%. Team is "CLE/MIA" when he played for several teams
//  that season. Rows come from the API; only their order is flipped.
//
import SwiftUI

struct CareerTable: View {
    let entity: QueryEntity
    let career: CareerData

    private let columns: [DataTable.Column] = [
        .init(title: "Team", width: 64, leading: true), .init(title: "GP", width: 30), .init(title: "Min", width: 38),
        .init(title: "Pts", width: 38, bold: true), .init(title: "Reb", width: 38), .init(title: "Ast", width: 38),
        .init(title: "3PM", width: 38), .init(title: "Stl", width: 34), .init(title: "Blk", width: 34),
        .init(title: "TO", width: 34), .init(title: "FG%", width: 44), .init(title: "TS%", width: 44)
    ]

    private func cells(_ r: Averages, team: String) -> [String] {
        [team, r.gp.map(String.init) ?? "—", Format.avg(r.minutes), Format.avg(r.pts), Format.avg(r.reb), Format.avg(r.ast),
         Format.avg(r.fg3m), Format.avg(r.stl), Format.avg(r.blk), Format.avg(r.tov), Format.pct(r.fgPct), Format.pct(r.tsPct)]
    }

    private func spoken(_ label: String, _ r: Averages) -> String {
        "\(label), \(r.gp ?? 0) games, \(Format.avg(r.pts)) points, \(Format.avg(r.reb)) rebounds, \(Format.avg(r.ast)) assists, "
            + "field goal \(Format.pct(r.fgPct)), true shooting \(Format.pct(r.tsPct))"
    }

    var body: some View {
        let rows = career.bySeason.reversed().map { r in
            DataTable.Row(id: r.season ?? UUID().uuidString, pinned: r.season ?? "",
                          cells: cells(r, team: r.team ?? ""), spoken: spoken("\(r.season ?? "") \(r.team ?? "")", r))
        }
        let footer = DataTable.Row(id: "career", pinned: "Career", cells: cells(career.totals, team: ""),
                                   spoken: spoken("Career", career.totals))
        DataTable(pinnedTitle: "Season", pinnedWidth: 84, columns: columns, rows: rows, footer: footer)
    }
}
