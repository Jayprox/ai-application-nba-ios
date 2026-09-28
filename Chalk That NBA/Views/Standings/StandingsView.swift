//
//  StandingsView.swift
//  Chalk That NBA
//
//  The web's pages/Standings.jsx: a season picker and a Standings |
//  Playoffs toggle.
//  - Standings: per conference, rows in the API's rank order, clinch
//    marks, the playoff and play-in cut lines from meta.format (8 seeds
//    before 2019-20, the bubble's 8v9, 6 + play-in since 2020-21), a
//    legend for the marks shown, and every meta.notes line.
//  - Playoffs: the bracket (BracketView).
//
import SwiftUI

struct StandingsView: View {
    @StateObject private var vm: StandingsViewModel

    init(season: String? = nil, bracket: Bool = false) {
        _vm = StateObject(wrappedValue: StandingsViewModel(season: season, bracket: bracket))
    }

    static let clinchText = [
        "z": "best record in the league", "w": "clinched the West", "e": "clinched the East", "y": "clinched division",
        "x": "clinched playoffs", "p": "clinched a playoff spot", "sw": "clinched the Southwest", "se": "clinched the Southeast",
        "a": "clinched the Atlantic", "c": "clinched the Central", "nw": "clinched the Northwest",
        "pi": "clinched a play-in spot", "o": "eliminated"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let key = vm.key {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "\(key.season) · \(key.view == .table ? "Regular season" : "Postseason")")
                        Text("Standings")
                            .font(.brandDisplay(32, weight: .bold, relativeTo: .largeTitle))
                            .foregroundStyle(Color.ink)
                            .accessibilityAddTraits(.isHeader)
                    }
                    SeasonMenu(seasons: vm.seasons, selected: key.season) { vm.key?.season = $0 }
                    UnderlineTabs(options: [("table", "Standings"), ("bracket", "Playoffs")], selected: key.view.rawValue) {
                        vm.key?.view = StandingsViewModel.Mode(rawValue: $0) ?? .table
                    }
                    content(key)
                } else if let error = vm.error {
                    ErrorCard(error: error) { Task { await vm.loadSeasons() } }
                } else {
                    LoadingCard()
                }
            }
            .padding(16)
        }
        .background(Color.paper)
        .navigationTitle("Standings")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadSeasons() }
        .task(id: vm.key) { await vm.load() }
    }

    @ViewBuilder
    private func content(_ key: StandingsViewModel.Key) -> some View {
        if vm.isCurrent {
            switch key.view {
            case .table: table(key.season)
            case .bracket: BracketView(series: vm.series, season: key.season)
            }
        } else if let error = vm.error {
            ErrorCard(error: error) { Task { await vm.load() } }
        } else {
            LoadingCard()
        }
    }

    // MARK: - Table

    @ViewBuilder
    private func table(_ season: String) -> some View {
        if let data = vm.standings, let meta = vm.standingsMeta, let format = meta.format,
           !data.east.isEmpty, (meta.games ?? 0) > 0 {
            conference("East", data.east, format: format, season: season)
            conference("West", data.west, format: format, season: season)
            VStack(alignment: .leading, spacing: 4) {
                Rectangle().fill(Color.line).frame(height: 1).padding(.bottom, 6)
                Text(legend(data, format: format, season: season))
                ForEach(meta.notes ?? [], id: \.self) { Text($0) }
            }
            .font(.brandBody(.footnote))
            .foregroundStyle(Color.muted)
            .fixedSize(horizontal: false, vertical: true)
        } else {
            EmptyCard { Text("No regular-season games yet for \(season).") }
        }
    }

    private func legend(_ data: StandingsData, format: PlayoffFormat, season: String) -> String {
        var s = "Seeds 1–\(format.playoffSeeds): playoffs"
        if let first = format.playInSeeds.first, let last = format.playInSeeds.last {
            s += " · seeds \(first)–\(last): \(season == "2019-20" ? "bubble play-in" : "play-in")"
        }
        s += "."
        var marks: [String] = []
        for mark in (data.east + data.west).compactMap(\.clinch) where !marks.contains(mark) { marks.append(mark) }
        if !marks.isEmpty {
            s += " " + marks.map { "\($0) = \(Self.clinchText[$0] ?? $0)" }.joined(separator: " · ") + "."
        }
        return s
    }

    private static let columns: [DataTable.Column] = [
        .init(title: "W", width: 28, bold: true), .init(title: "L", width: 28, bold: true), .init(title: "Pct", width: 44),
        .init(title: "GB", width: 36), .init(title: "Home", width: 48), .init(title: "Road", width: 48),
        .init(title: "Conf", width: 48), .init(title: "L10", width: 40), .init(title: "Strk", width: 44)
    ]

    private func conference(_ name: String, _ rows: [StandingRow], format: PlayoffFormat, season: String) -> some View {
        let lastPlayoff = format.playoffSeeds
        let lastPlayIn = format.playInSeeds.last ?? format.playoffSeeds
        let tableRows = rows.map { t in
            DataTable.Row(
                id: String(t.teamId),
                pinned: t.name,
                cells: [String(t.wins), String(t.losses), Format.winPct(t.pct),
                        t.gb == 0 ? "—" : (t.gb.map(Format.jsNumber) ?? ""),
                        t.home ?? "", t.road ?? "", t.conf ?? "", t.last10 ?? "", t.streak ?? "—"],
                route: .team(id: t.teamId, season: season),
                spoken: spoken(t),
                prefix: String(t.rank),
                suffix: t.clinch,
                muted: t.rank > lastPlayIn,
                shaded: t.rank > lastPlayoff && t.rank <= lastPlayIn,
                heavyBottom: t.rank == lastPlayoff || t.rank == lastPlayIn)
        }
        return VStack(alignment: .leading, spacing: 8) {
            Text("\(name)ern Conference")
                .font(.brandDisplay(26, weight: .bold, relativeTo: .title2))
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            DataTable(pinnedTitle: "Team", pinnedWidth: 190, columns: Self.columns, rows: tableRows)
        }
    }

    private func spoken(_ t: StandingRow) -> String {
        var s = "\(t.rank), \(t.name), \(t.wins) and \(t.losses)"
        if let clinch = t.clinch { s += ", \(Self.clinchText[clinch] ?? clinch)" }
        if let gb = t.gb, gb != 0 { s += ", \(Format.jsNumber(gb)) games back" }
        if let streak = t.streak { s += ", streak \(streak)" }
        return s
    }
}
