//
//  StatTiles.swift
//  Chalk That NBA
//
//  Averages as tiles (the web's `Tiles`), player version:
//    Points, Rebounds, Assists, 3PM, FG%, Steals, Blocks, Turnovers,
//    Minutes, +/-
//    Efficiency & usage: TS%, eFG%, FT rate, Pts/36, Reb/36, Ast/36,
//    Usage (est.)
//  Values are the API's, formatted (Format); each tile's hint is the
//  web's tooltip text. The team version arrives with team detail (step 4).
//
import SwiftUI

struct StatTiles: View {
    let entity: QueryEntity
    let d: Averages

    private typealias Tile = (label: String, value: String, hint: String?)

    private var main: [Tile] {
        [("Points", Format.avg(d.pts), nil), ("Rebounds", Format.avg(d.reb), nil), ("Assists", Format.avg(d.ast), nil),
         ("3PM", Format.avg(d.fg3m), nil), ("FG%", Format.pct(d.fgPct), nil), ("Steals", Format.avg(d.stl), nil),
         ("Blocks", Format.avg(d.blk), nil), ("Turnovers", Format.avg(d.tov), nil), ("Minutes", Format.avg(d.minutes), nil),
         ("+/-", Format.signedAvg(d.plusMinus), nil)]
    }

    private var efficiency: [Tile] {
        [("TS%", Format.pct(d.tsPct), "True shooting: points per shot, counting 3s and free throws"),
         ("eFG%", Format.pct(d.efgPct), "Effective FG%: a 3 counts 1.5 makes"),
         ("FT rate", Format.pct(d.ftRate), "Free-throw attempts per field-goal attempt"),
         ("Pts / 36", Format.avg(d.ptsPer36), "Points per 36 minutes"),
         ("Reb / 36", Format.avg(d.rebPer36), "Rebounds per 36 minutes"),
         ("Ast / 36", Format.avg(d.astPer36), "Assists per 36 minutes"),
         ("Usage (est.)", Format.usgPct(d.usgPct),
          "Share of his team's plays (shots, free-throw trips, turnovers) he used while on the floor, estimated from the box score")]
    }

    private let grid = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: grid, spacing: 10) {
                ForEach(main, id: \.label) { tile($0) }
            }
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "Efficiency & usage")
                LazyVGrid(columns: grid, spacing: 10) {
                    ForEach(efficiency, id: \.label) { tile($0) }
                }
            }
        }
    }

    private func tile(_ t: Tile) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Eyebrow(text: t.label, color: t.label.contains("est.") ? .caution : .muted)
            Text(t.value)
                .font(.brandDisplay(34, weight: .bold, relativeTo: .title))
                .monospacedDigit()
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityHint(t.hint ?? "")
    }
}
