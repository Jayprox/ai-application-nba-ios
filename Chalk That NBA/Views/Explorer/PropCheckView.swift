//
//  PropCheckView.swift
//  Chalk That NBA
//
//  "Prop check" (the web's `PropCheck`): his next game's DraftKings lines,
//  each with how often he went over it in exactly the games the explorer
//  selects (POST /query `props`), plus his over–under record against past
//  lines. Counts, never picks. Renders nothing without lines or history.
//
import SwiftUI

struct PropCheckView: View {
    let props: PlayerProps?
    let hits: [String: PropHits]?

    private var upcoming: PlayerProps.Upcoming? { props?.upcoming }

    private var record: [(market: String, line: PlayerProps.RecordLine)] {
        (props?.record ?? [:]).map { ($0.key, $0.value) }.sorted { Markets.order($0.market) < Markets.order($1.market) }
    }

    var body: some View {
        if upcoming != nil || !record.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel(text: title)
                    Text(bookLine)
                        .font(.brandBody(.caption))
                        .foregroundStyle(Color.muted)
                }
                if let upcoming {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        ForEach(upcoming.lines, id: \.market) { line in
                            lineCell(line)
                        }
                    }
                }
                if !footnote.isEmpty {
                    Text(footnote)
                        .font(.brandBody(.caption))
                        .foregroundStyle(Color.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(Color.card)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    var title: String {
        guard let g = upcoming?.game else { return "Prop check" }
        let when = g.status == "live" ? "(live)" : Format.tipTime(g.tipoffUtc)
        return "Prop check · \(g.away) @ \(g.home) · \(Format.tinyDate(g.date)) \(when)"
    }

    var bookLine: String {
        guard let upcoming else { return "DraftKings" }
        return "DraftKings · \(upcoming.lines.contains { $0.snapshot == "close" } ? "closing" : "opening") lines"
    }

    private func lineCell(_ line: PlayerProps.Line) -> some View {
        let h = hits?[line.market]
        return VStack(alignment: .leading, spacing: 2) {
            Eyebrow(text: "\(Markets.short(line.market)) \(Self.lineText(line.line))")
            Group {
                if let h, h.games > 0 {
                    (Text("Over \(h.over)").bold() + Text(" of \(h.games)\(h.push > 0 ? " · \(h.push) push" : "")"))
                        .foregroundColor(.ink)
                } else {
                    Text("no games").foregroundColor(.muted)
                }
            }
            .font(.brandBody(.subheadline))
            .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.rule, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityHint(priceHint(line))
    }

    /// The web's title tooltip: "Points: over -115 / under -105 · opened 25.5".
    private func priceHint(_ line: PlayerProps.Line) -> String {
        var s = "\(line.label ?? Markets.short(line.market)): over \(Markets.price(line.overPrice)) / under \(Markets.price(line.underPrice))"
        if let open = line.openLine, open != line.line { s += " · opened \(Self.lineText(open))" }
        return s
    }

    var footnote: String {
        var s = upcoming != nil ? "Counts use the games selected above (season, type, splits, last N). " : ""
        if !record.isEmpty {
            let anyPush = record.contains { $0.line.push > 0 }
            let parts = record.map { r in
                "\(Markets.short(r.market)) \(r.line.over)–\(r.line.under)\(r.line.push > 0 ? "–\(r.line.push)" : "")"
            }
            s += "Vs. his past DraftKings lines (over–under\(anyPush ? "–push" : "")): \(parts.joined(separator: " · "))."
        }
        return s
    }

    /// A line the way JS prints a number: 25.5, 26 (not 26.0).
    static func lineText(_ v: Double) -> String { Format.jsNumber(v) }
}
