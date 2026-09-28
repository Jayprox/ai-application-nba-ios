//
//  BoxScoreTable.swift
//  Chalk That NBA
//
//  One team's box score (BoxScore.jsx `TeamTable`): Player | Min Pts Reb
//  Ast FG 3PT FT Stl Blk TO +/-. The player column stays put while the
//  stats scroll sideways (the web's sticky first column). Starters get an
//  "S", DNPs show "DNP — reason" across the row, and a Totals row closes
//  it (team +/- left blank, as on the web).
//
//  VoiceOver reads each row as one sentence from the name cell; the
//  scrolling grid is hidden from it so rows aren't read cell by cell.
//
import SwiftUI

struct BoxScoreTable: View {
    let team: BoxScoreTeam

    @ScaledMetric(relativeTo: .subheadline) private var rowHeight: CGFloat = 36
    @ScaledMetric(relativeTo: .subheadline) private var nameWidth: CGFloat = 150
    @ScaledMetric(relativeTo: .subheadline) private var unit: CGFloat = 1

    private struct Column {
        let title: String
        let width: CGFloat
        let value: (any BoxScoreLine) -> String
        var bold = false
    }

    private let columns: [Column] = [
        Column(title: "Min", width: 38, value: { Format.mins($0.minutes) }),
        Column(title: "Pts", width: 38, value: { $0.pts.map(String.init) ?? "" }, bold: true),
        Column(title: "Reb", width: 38, value: { $0.reb.map(String.init) ?? "" }),
        Column(title: "Ast", width: 38, value: { $0.ast.map(String.init) ?? "" }),
        Column(title: "FG", width: 54, value: { Format.made($0.fgm, $0.fga) }),
        Column(title: "3PT", width: 50, value: { Format.made($0.fg3m, $0.fg3a) }),
        Column(title: "FT", width: 50, value: { Format.made($0.ftm, $0.fta) }),
        Column(title: "Stl", width: 38, value: { $0.stl.map(String.init) ?? "" }),
        Column(title: "Blk", width: 38, value: { $0.blk.map(String.init) ?? "" }),
        Column(title: "TO", width: 38, value: { $0.tov.map(String.init) ?? "" }),
        Column(title: "+/-", width: 44, value: { Format.pm($0.plusMinus) })
    ]

    private var gridWidth: CGFloat { columns.map { $0.width * unit }.reduce(0, +) + 12 * unit }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            nameColumn
                .frame(width: nameWidth)
                .overlay(alignment: .trailing) { Rectangle().fill(Color.line).frame(width: 1) }
            ScrollView(.horizontal, showsIndicators: false) {
                statGrid
            }
            .accessibilityHidden(true)
        }
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Player column

    private var nameColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerCell("Player", alignment: .leading)
                .padding(.horizontal, 12)
                .overlay(alignment: .bottom) { heavyRule }
            ForEach(team.players) { player in
                HStack(spacing: 5) {
                    Text(player.fullName)
                        .font(.brandBody(.subheadline, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if player.started == true {
                        Text("S")
                            .font(.brandBody(.caption2, weight: .semibold))
                            .foregroundStyle(Color.accent)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 12)
                .frame(height: rowHeight)
                .overlay(alignment: .bottom) { rule }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spoken(player))
            }
            Text("Totals")
                .font(.brandBody(.subheadline, weight: .semibold))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .leading)
                .overlay(alignment: .top) { heavyRule }
                .accessibilityLabel(spoken(totals: team))
        }
    }

    // MARK: - Stats

    private var statGrid: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(columns, id: \.title) { column in
                    headerCell(column.title, alignment: .trailing)
                        .frame(width: column.width * unit, alignment: .trailing)
                }
            }
            .padding(.trailing, 12 * unit)
            .overlay(alignment: .bottom) { heavyRule }

            ForEach(team.players) { player in
                Group {
                    if player.dnp {
                        Text("DNP\(player.dnpReason.map { " — \($0)" } ?? "")")
                            .font(.brandBody(.subheadline).italic())
                            .foregroundStyle(Color.muted)
                            .lineLimit(1)
                            .padding(.leading, 12)
                            .frame(width: gridWidth, alignment: .leading)
                    } else {
                        statRow(player, blankPlusMinus: false)
                    }
                }
                .frame(height: rowHeight)
                .overlay(alignment: .bottom) { rule }
            }

            statRow(team, blankPlusMinus: true, weight: .semibold)
                .frame(height: rowHeight)
                .overlay(alignment: .top) { heavyRule }
        }
    }

    private func statRow(_ line: any BoxScoreLine, blankPlusMinus: Bool, weight: Font.Weight? = nil) -> some View {
        HStack(spacing: 0) {
            ForEach(columns, id: \.title) { column in
                Text(blankPlusMinus && column.title == "+/-" ? "" : column.value(line))
                    .font(.brandBody(.subheadline, weight: weight ?? (column.bold ? .semibold : .regular)))
                    .monospacedDigit()
                    .foregroundStyle(Color.ink)
                    .frame(width: column.width * unit, alignment: .trailing)
            }
        }
        .padding(.trailing, 12 * unit)
    }

    // MARK: - Pieces

    private func headerCell(_ title: String, alignment: Alignment) -> some View {
        Text(title.uppercased())
            .font(.brandBody(.caption, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(Color.muted)
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: alignment)
    }

    private var rule: some View { Rectangle().fill(Color.rule).frame(height: 1) }
    private var heavyRule: some View { Rectangle().fill(Color.strong).frame(height: 2) }

    // MARK: - VoiceOver

    private func spoken(_ p: BoxScorePlayer) -> String {
        var parts = [p.fullName]
        if p.started == true { parts.append("starter") }
        if p.dnp {
            parts.append("did not play" + (p.dnpReason.map { ", \($0)" } ?? ""))
            return parts.joined(separator: ", ")
        }
        return (parts + statPhrases(p)).joined(separator: ", ")
    }

    private func spoken(totals t: BoxScoreTeam) -> String {
        (["Team totals"] + statPhrases(t, includePlusMinus: false)).joined(separator: ", ")
    }

    private func statPhrases(_ l: any BoxScoreLine, includePlusMinus: Bool = true) -> [String] {
        var out: [String] = []
        if let m = l.minutes { out.append("\(Format.mins(m)) minutes") }
        if let v = l.pts { out.append("\(v) points") }
        if let v = l.reb { out.append("\(v) rebounds") }
        if let v = l.ast { out.append("\(v) assists") }
        let fg = Format.made(l.fgm, l.fga); if !fg.isEmpty { out.append("\(fg) field goals") }
        let three = Format.made(l.fg3m, l.fg3a); if !three.isEmpty { out.append("\(three) threes") }
        let ft = Format.made(l.ftm, l.fta); if !ft.isEmpty { out.append("\(ft) free throws") }
        if let v = l.stl { out.append("\(v) steals") }
        if let v = l.blk { out.append("\(v) blocks") }
        if let v = l.tov { out.append("\(v) turnovers") }
        if includePlusMinus, let v = l.plusMinus { out.append("plus-minus \(Format.pm(v))") }
        return out
    }
}
