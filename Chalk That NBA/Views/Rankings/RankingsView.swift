//
//  RankingsView.swift
//  Chalk That NBA
//
//  The web's pages/Rankings.jsx:
//  - Players: by position, ranked by the API's composite score (0 = an
//    average qualified player at the position), with every stat and its
//    z-score shown so you can see how the score was built.
//  - Teams: W-L, Off / Def / Net rating and Pace (est.) with ranks;
//    "Rank by" re-sorts.
//  - Matchups: what each defense allows per game to one position, with
//    rank, vs league average and strong / weak; a League avg row.
//  Every meta.notes line is shown under the table.
//
import SwiftUI

struct RankingsView: View {
    @StateObject private var vm = RankingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let key = vm.key {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "\(key.season) · \(key.seasonType == "regular" ? "Regular season" : "Playoffs") · \(key.scope == "season" ? "full season" : "last 10 games")")
                        Text("Rankings")
                            .font(.brandDisplay(32, weight: .bold, relativeTo: .largeTitle))
                            .foregroundStyle(Color.ink)
                            .accessibilityAddTraits(.isHeader)
                    }
                    UnderlineTabs(options: RankingsViewModel.views, selected: key.view) { vm.key?.view = $0 }
                    controls(key)
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
        .navigationTitle("Rankings")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadSeasons() }
        .task(id: vm.key) { await vm.load() }
    }

    private func controls(_ key: RankingsViewModel.Key) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SeasonMenu(seasons: vm.seasons, selected: key.season) { vm.key?.season = $0 }
            field("Season type") {
                Pills(label: "Season type", options: RankingsViewModel.types, selected: key.seasonType) { vm.key?.seasonType = $0 }
            }
            field("Games") {
                Pills(label: "Games", options: RankingsViewModel.scopes, selected: key.scope) { vm.key?.scope = $0 }
            }
            if key.view != "teams" {
                field("Position") {
                    Pills(label: "Position", options: RankingsViewModel.positions, selected: key.position) { vm.key?.position = $0 }
                }
            }
        }
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.brandBody(.footnote, weight: .semibold))
                .foregroundStyle(Color.ink)
            content()
        }
    }

    @ViewBuilder
    private func content(_ key: RankingsViewModel.Key) -> some View {
        if vm.isCurrent {
            switch key.view {
            case "teams": teamsView(key)
            case "matchups": matchupsView(key)
            default: playersView(key)
            }
        } else if let error = vm.error {
            ErrorCard(error: error) { Task { await vm.load() } }
        } else {
            LoadingCard(label: "Ranking…")
        }
    }

    private func notes(_ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Rectangle().fill(Color.line).frame(height: 1).padding(.bottom, 6)
            ForEach(lines, id: \.self) { Text($0) }
        }
        .font(.brandBody(.footnote))
        .foregroundStyle(Color.muted)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func rankBy(_ options: [(value: String, label: String)], selected: String, suffix: String = "",
                        onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Rank by")
                .font(.brandBody(.footnote, weight: .semibold))
                .foregroundStyle(Color.ink)
            Menu {
                ForEach(options, id: \.value) { option in
                    Button(option.label + suffix) { onSelect(option.value) }
                }
            } label: {
                HStack(spacing: 8) {
                    Text((options.first { $0.value == selected }?.label ?? selected) + suffix)
                    Image(systemName: "chevron.up.chevron.down").font(.caption)
                }
                .font(.brandBody(.body))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.field, lineWidth: 1))
            }
        }
    }

    // MARK: - Players

    @ViewBuilder
    private func playersView(_ key: RankingsViewModel.Key) -> some View {
        if let meta = vm.playersMeta {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(meta.positionLabel) · \(meta.count) qualified")
                    .font(.brandBody(.headline, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.ink)
                Text("score 0 = an average qualified \(Self.singular(meta.positionLabel.lowercased()))")
                    .font(.brandBody(.subheadline))
                    .foregroundStyle(Color.muted)
            }
            if vm.players.isEmpty {
                EmptyCard { Text("No qualified \(meta.positionLabel.lowercased()) for these filters.") }
            } else {
                let columns = [DataTable.Column(title: "Score", width: 48, bold: true), DataTable.Column(title: "GP", width: 30)]
                    + meta.stats.map { DataTable.Column(title: RankingsViewModel.zLabel[$0] ?? $0, width: 44) }
                DataTable(pinnedTitle: "Player", pinnedWidth: 176, columns: columns, rows: vm.players.map { r in
                    let values = meta.stats.map { $0 == "ts_pct" ? Format.pct(r.value($0)) : Format.avg(r.value($0)) }
                    let zs = meta.stats.map { Format.signedAvg(r.zScore($0)) }
                    return DataTable.Row(
                        id: r.playerId, pinned: r.name,
                        cells: [Format.signedAvg(r.score), String(r.gp)] + values,
                        route: .player(id: r.playerId, season: key.season),
                        spoken: "\(r.rank), \(r.name), \(r.team ?? ""), score \(Format.signedAvg(r.score)), \(r.gp) games",
                        prefix: String(r.rank),
                        subcells: ["", ""] + zs,
                        detail: r.team)
                })
            }
            notes(meta.notes)
        }
    }

    /// "Guards" -> "guard" (the web's `.replace(/s$/, '')`).
    static func singular(_ s: String) -> String { s.hasSuffix("s") ? String(s.dropLast()) : s }

    // MARK: - Teams

    @ViewBuilder
    private func teamsView(_ key: RankingsViewModel.Key) -> some View {
        rankBy(RankingsViewModel.teamSorts, selected: vm.teamSort) { vm.teamSort = $0 }
        let rows = vm.sortedTeams
        if rows.isEmpty {
            EmptyCard { Text("No games for these filters.") }
        } else {
            let columns: [DataTable.Column] = [
                .init(title: "W-L", width: 48), .init(title: "Off rtg", width: 52), .init(title: "Def rtg", width: 52),
                .init(title: "Net", width: 48, bold: true), .init(title: "Pace", width: 48), .init(title: "Pts", width: 46), .init(title: "Opp", width: 46)
            ]
            DataTable(pinnedTitle: "Team", pinnedWidth: 196, columns: columns, rows: rows.map { r in
                DataTable.Row(
                    id: String(r.teamId), pinned: r.name,
                    cells: ["\(r.w)-\(r.l)", Format.avg(r.offRtg), Format.avg(r.defRtg), Format.signedAvg(r.netRtg),
                            Format.avg(r.pace), Format.avg(r.pts), Format.avg(r.oppPts)],
                    route: .team(id: r.teamId, season: key.season),
                    spoken: "\(r.name), \(r.w) and \(r.l), offensive rating \(Format.avg(r.offRtg)), defensive rating \(Format.avg(r.defRtg)), net \(Format.signedAvg(r.netRtg)), pace \(Format.avg(r.pace))",
                    prefix: r.rank(vm.teamSort).map(String.init) ?? "",
                    subcells: ["", Format.ordinal(r.rank("off_rtg")), Format.ordinal(r.rank("def_rtg")),
                               Format.ordinal(r.rank("net_rtg")), Format.ordinal(r.rank("pace")), "", ""])
            })
        }
        notes(vm.teamNotes + ["Defense: rank 1 = fewest points allowed per 100 possessions. Pace: rank 1 = fastest."])
    }

    // MARK: - Matchups

    @ViewBuilder
    private func matchupsView(_ key: RankingsViewModel.Key) -> some View {
        rankBy(RankingsViewModel.matchupStats, selected: vm.matchupSort, suffix: " allowed") { vm.matchupSort = $0 }
        let rows = vm.sortedMatchups(key.position)
        let label = (RankingsViewModel.positions.first { $0.value == key.position }?.label ?? "").lowercased()
        if rows.isEmpty {
            EmptyCard { Text("No games for these filters.") }
        } else {
            let stats = RankingsViewModel.matchupStats
            let columns = [DataTable.Column(title: "GP", width: 30)]
                + stats.map { DataTable.Column(title: $0.label, width: 72, bold: $0.value == vm.matchupSort) }
            let avgRow = (vm.matchups?.leagueAvg?[key.position] ?? nil)
            let footer = avgRow.map { avg in
                DataTable.Row(id: "avg", pinned: "League avg",
                              cells: [""] + stats.map { Format.avg(avg[$0.value] ?? nil) },
                              spoken: "League average, " + stats.map { "\($0.label) \(Format.avg(avg[$0.value] ?? nil))" }.joined(separator: ", "))
            }
            DataTable(pinnedTitle: "Defense", pinnedWidth: 130, columns: columns, rows: rows.map { r in
                let tag = r.label[vm.matchupSort] ?? nil
                return DataTable.Row(
                    id: String(r.teamId), pinned: r.abbr,
                    cells: [String(r.games)] + stats.map { Format.avg(r.allowed[$0.value] ?? nil) },
                    route: .team(id: r.teamId, season: key.season),
                    spoken: "\(r.abbr), " + stats.map { s in
                        "\(s.label) \(Format.avg(r.allowed[s.value] ?? nil)) allowed, \(Format.ordinal(r.rank[s.value] ?? nil))"
                    }.joined(separator: ", ") + (tag.map { ", \($0)" } ?? ""),
                    prefix: (r.rank[vm.matchupSort] ?? nil).map(String.init) ?? "",
                    suffix: tag,
                    subcells: [""] + stats.map { s in
                        [Format.ordinal(r.rank[s.value] ?? nil), Format.signedAvg(r.vsAvg[s.value] ?? nil)].filter { !$0.isEmpty }.joined(separator: " · ")
                    })
            }, footer: footer)
            Text("Per game to opposing \(label); small number = rank · vs league average. Rank 1 = allows the fewest.")
                .font(.brandBody(.caption))
                .foregroundStyle(Color.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        notes(vm.matchups?.meta?.notes ?? [])
    }
}
