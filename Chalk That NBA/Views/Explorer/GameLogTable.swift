//
//  GameLogTable.swift
//  Chalk That NBA
//
//  The game log, newest first (the web's `GameLog`, player version):
//  Date | Opp Result Min Pts Reb Ast 3PM FG +/- "Pts line" Tags. Tapping
//  the date opens the box score. "Pts line" is the DraftKings points line
//  with its result (O / U / P), blank when no line was pulled. Tags use
//  his own rest when "Rest measured by" is his games.
//
import SwiftUI

enum GameLogText {
    /// `opp`: "@ NYK" away, "vs NYK" home or neutral.
    static func opponent(_ r: GameLogRow) -> String {
        "\(r.venue == "away" ? "@" : "vs") \(r.opponent)"
    }

    /// `tags(r, restby)`: "Playoffs · B2B night 2 · 0d rest · Altitude · National TV".
    static func tags(_ r: GameLogRow, restBy: String) -> String {
        let rest = restBy == "player" ? r.playerRestDays : r.restDays
        let b2b = restBy == "player" ? r.playerB2bNight : r.b2bNight
        let type = ["play_in": "Play-In", "playoffs": "Playoffs", "cup_final": "Cup Final"]
        let tv = ["major": "National TV", "nba_tv": "NBA TV"]
        return [
            r.seasonType != "regular" ? type[r.seasonType] : nil,
            r.venue == "neutral" ? "Neutral site" : nil,
            b2b.map { "B2B night \($0)" },
            rest.map { "\($0)d rest" },
            r.altitude == true ? "Altitude" : nil,
            r.nationalTvTier.flatMap { tv[$0] }
        ].compactMap { $0 }.joined(separator: " · ")
    }

    /// "25.5 O", "lines" (lines but no points line), or "".
    static func pointsLine(_ r: GameLogRow) -> String {
        guard let props = r.props else { return "" }
        guard let pts = props["pts"] else { return "lines" }
        let letter = ["over": "O", "under": "U", "push": "P"][pts.result ?? ""] ?? ""
        return "\(PropCheckView.lineText(pts.line))\(letter.isEmpty ? "" : " \(letter)")"
    }
}

struct GameLogTable: View {
    let entity: QueryEntity
    let rows: [GameLogRow]
    let restBy: String

    private let columns: [DataTable.Column] = [
        .init(title: "Opp", width: 64, leading: true), .init(title: "Result", width: 48, leading: true),
        .init(title: "Min", width: 34), .init(title: "Pts", width: 34, bold: true), .init(title: "Reb", width: 34),
        .init(title: "Ast", width: 34), .init(title: "3PM", width: 34), .init(title: "FG", width: 48),
        .init(title: "+/-", width: 40), .init(title: "Pts line", width: 64),
        .init(title: "Tags", width: 300, leading: true, muted: true)
    ]

    var body: some View {
        let tableRows = rows.map { r in
            DataTable.Row(
                id: r.gameId,
                pinned: Format.tinyDate(r.date),
                cells: [GameLogText.opponent(r), r.won == true ? "W" : "L", Format.mins(r.minutes),
                        r.pts.map(String.init) ?? "", r.reb.map(String.init) ?? "", r.ast.map(String.init) ?? "",
                        r.fg3m.map(String.init) ?? "", Format.made(r.fgm, r.fga), Format.pm(r.plusMinus),
                        GameLogText.pointsLine(r), GameLogText.tags(r, restBy: restBy)],
                route: .game(id: r.gameId),
                spoken: spoken(r))
        }
        DataTable(pinnedTitle: "Date", pinnedWidth: 76, columns: columns, rows: tableRows)
    }

    private func spoken(_ r: GameLogRow) -> String {
        var parts = [Format.shortDate(r.date), GameLogText.opponent(r), r.won == true ? "win" : "loss"]
        if let v = r.pts { parts.append("\(v) points") }
        if let v = r.reb { parts.append("\(v) rebounds") }
        if let v = r.ast { parts.append("\(v) assists") }
        let line = GameLogText.pointsLine(r)
        if !line.isEmpty, line != "lines" { parts.append("points line \(line)") }
        let tags = GameLogText.tags(r, restBy: restBy)
        if !tags.isEmpty { parts.append(tags) }
        return parts.joined(separator: ", ")
    }
}
