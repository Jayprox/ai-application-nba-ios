//
//  BracketView.swift
//  Chalk That NBA
//
//  The postseason bracket (Standings.jsx `Bracket`): the Finals first,
//  then West and East, each as Play-In, First round (1v8, 4v5, 3v6,
//  2v7), Conf. semifinals, Conf. finals, stacked for a phone (the web's
//  mobile layout). Series scores are the API's higher_wins / lower_wins.
//  An unfinished series gets a blue border and "In progress · first to 4".
//
import SwiftUI

struct BracketView: View {
    let series: [Series]
    let season: String

    var body: some View {
        if series.isEmpty {
            EmptyCard { Text("No postseason games for \(season) yet.") }
        } else {
            let bracket = Bracket(series)
            if let finals = bracket.finals {
                VStack(alignment: .leading, spacing: 8) {
                    title("NBA Finals")
                    SeriesCard(series: finals, season: season, big: true)
                }
            }
            ForEach(["West", "East"], id: \.self) { conf in
                let c = bracket[conf]
                VStack(alignment: .leading, spacing: 12) {
                    title("\(conf)ern Conference")
                    column(season == "2019-20" ? "Play-In (best of 2)" : "Play-In", c.playIn)
                    column("First round", c.first)
                    column("Conf. semifinals", c.semis)
                    column("Conf. finals", c.finals)
                }
            }
            Text("Seeds from NBA.com's final standings. Series wins count finished games; tap a team for its playoff stats.")
                .font(.brandBody(.footnote))
                .foregroundStyle(Color.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.brandDisplay(26, weight: .bold, relativeTo: .title2))
            .foregroundStyle(Color.ink)
            .accessibilityAddTraits(.isHeader)
    }

    private func column(_ title: String, _ items: [Series]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            if items.isEmpty {
                Text("—")
                    .font(.brandBody(.subheadline))
                    .foregroundStyle(Color.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            } else {
                ForEach(items) { SeriesCard(series: $0, season: season) }
            }
        }
    }
}

struct SeriesCard: View {
    let series: Series
    let season: String
    var big = false

    private var done: Bool { series.winnerTeamId != nil }

    /// "first to 4" (playoffs), "first to 1" (single play-in game), or nil
    /// for the 2019-20 best-of-2 play-in.
    private var needed: Int? {
        series.round == "play_in" ? (series.bestOf == 2 ? nil : 1) : 4
    }

    private var status: String {
        if done, let first = series.firstGame {
            let last = series.lastGame ?? first
            return first == last ? Format.tinyDate(first) : "\(Format.tinyDate(first)) – \(Format.tinyDate(last))"
        }
        return needed.map { "In progress · first to \($0)" } ?? "In progress"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            teamRow(seed: series.higherSeed, id: series.higherId, abbr: series.higherAbbr, name: series.higherName, wins: series.higherWins)
            teamRow(seed: series.lowerSeed, id: series.lowerId, abbr: series.lowerAbbr, name: series.lowerName, wins: series.lowerWins)
            Text(status)
                .font(.brandBody(.caption))
                .foregroundStyle(Color.muted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(done ? Color.line : Color.link, lineWidth: done ? 1 : 2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func teamRow(seed: Int?, id: Int?, abbr: String?, name: String?, wins: Int?) -> some View {
        let won = done && series.winnerTeamId == id
        let label = HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(seed.map(String.init) ?? "")
                .font(.brandBody(.caption))
                .monospacedDigit()
                .foregroundStyle(Color.muted)
                .frame(minWidth: 18, alignment: .leading)
            Text(id != nil ? (abbr ?? "") : "TBD")
                .font(.brandBody(big ? .title3 : .body, weight: won ? .bold : .medium))
                .foregroundStyle(id != nil ? (done && !won ? Color.muted : Color.link) : Color.muted)
            Spacer()
            Text(wins.map(String.init) ?? "")
                .font(.brandDisplay(big ? 30 : 24, weight: won ? .bold : .semibold, relativeTo: .title2))
                .monospacedDigit()
                .foregroundStyle(done && !won ? Color.muted : Color.ink)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(seed.map { "Seed \($0), " } ?? "")\(name ?? abbr ?? "TBD"), \(wins ?? 0) wins\(won ? ", won the series" : "")")

        return Group {
            if let id {
                NavigationLink(value: AppRoute.team(id: id, season: season,
                                                    seasonType: series.round == "play_in" ? "play_in" : "playoffs")) {
                    label.contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                label
            }
        }
    }
}
