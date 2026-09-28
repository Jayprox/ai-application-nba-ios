//
//  CareerTable.swift
//  Chalk That NBA
//
//  Career by season, newest first, plus a totals row (the web's `Career`).
//  Player: Season | Team GP Min Pts Reb Ast 3PM Stl Blk TO FG% TS%, footer
//    "Career". Team is "CLE/MIA" when he played for several teams.
//  Team: Season | GP Pts Opp Reb Ast 3PM FG% 3P% TS% Net, footer
//    "All seasons". Net = Format.netRating (the one derived number).
//  Rows come from the API; only their order is flipped.
//
import SwiftUI

struct CareerTable: View {
    let entity: QueryEntity
    let career: CareerData

    private let teamColumns: [DataTable.Column] = [
        .init(title: "GP", width: 30), .init(title: "Pts", width: 44, bold: true), .init(title: "Opp", width: 44),
        .init(title: "Reb", width: 38), .init(title: "Ast", width: 38), .init(title: "3PM", width: 38),
        .init(title: "FG%", width: 44), .init(title: "3P%", width: 44), .init(title: "TS%", width: 44), .init(title: "Net", width: 44)
    ]

    private func teamCells(_ r: Averages) -> [String] {
        [r.gp.map(String.init) ?? "—", Format.avg(r.pts), Format.avg(r.oppPts), Format.avg(r.reb), Format.avg(r.ast),
         Format.avg(r.fg3m), Format.pct(r.fgPct), Format.pct(r.fg3Pct), Format.pct(r.tsPct),
         Format.netRating(off: r.offRtg, def: r.defRtg)]
    }

    private func teamSpoken(_ label: String, _ r: Averages) -> String {
        "\(label), \(r.gp ?? 0) games, \(Format.avg(r.pts)) points, \(Format.avg(r.oppPts)) allowed, "
            + "net rating \(Format.netRating(off: r.offRtg, def: r.defRtg))"
    }

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
        if entity == .team { teamBody } else { playerBody }
    }

    private var teamBody: some View {
        let rows = career.bySeason.reversed().map { r in
            DataTable.Row(id: r.season ?? UUID().uuidString, pinned: r.season ?? "",
                          cells: teamCells(r), spoken: teamSpoken(r.season ?? "", r))
        }
        let footer = DataTable.Row(id: "all", pinned: "All seasons", cells: teamCells(career.totals),
                                   spoken: teamSpoken("All seasons", career.totals))
        return DataTable(pinnedTitle: "Season", pinnedWidth: 100, columns: teamColumns, rows: rows, footer: footer)
    }

    private var playerBody: some View {
        let rows = career.bySeason.reversed().map { r in
            DataTable.Row(id: r.season ?? UUID().uuidString, pinned: r.season ?? "",
                          cells: cells(r, team: r.team ?? ""), spoken: spoken("\(r.season ?? "") \(r.team ?? "")", r))
        }
        let footer = DataTable.Row(id: "career", pinned: "Career", cells: cells(career.totals, team: ""),
                                   spoken: spoken("Career", career.totals))
        return DataTable(pinnedTitle: "Season", pinnedWidth: 84, columns: columns, rows: rows, footer: footer)
    }
}
