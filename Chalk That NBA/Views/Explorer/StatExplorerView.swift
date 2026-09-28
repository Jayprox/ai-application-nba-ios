//
//  StatExplorerView.swift
//  Chalk That NBA
//
//  The heart of the app (ios-kickoff.md §4; the web's
//  components/StatExplorer.jsx): season + season type, scope tabs, the
//  splits panel, then one POST /query result:
//    - header "Season average · 79 games" + "33-46 in these games ·
//      2003-04 regular season · 1 split applied"
//    - every meta.notes line
//    - the designed empty state when sample_size is 0
//    - tiles (averages), the career table, or the game log
//    - Prop check (players with lines) above tiles / career
//    - footer "From NBA.com game logs · synced 1 day ago"
//  Shared by player detail and (step 4) team detail.
//
import SwiftUI

struct StatExplorerView: View {
    @StateObject private var vm: StatExplorerViewModel
    private let props: PlayerProps?
    private let onFiltersChange: ((ExplorerFilters) -> Void)?
    @State private var showSplits = false

    /// - Parameter onFiltersChange: team detail follows the explorer's
    ///   season and type with its roster and defense sections, like the web.
    init(entity: QueryEntity, id: String, name: String, seasons: [String],
         seasonTypes: [String: [String]], props: PlayerProps? = nil,
         startSeason: String? = nil, startType: String? = nil,
         onFiltersChange: ((ExplorerFilters) -> Void)? = nil) {
        let lines = props?.upcoming.map { upcoming in
            Dictionary(upcoming.lines.map { ($0.market, $0.line) }, uniquingKeysWith: { first, _ in first })
        }
        _vm = StateObject(wrappedValue: StatExplorerViewModel(
            entity: entity, id: id, name: name, seasons: seasons, seasonTypes: seasonTypes, lines: lines,
            startSeason: startSeason, startType: startType))
        self.props = props
        self.onFiltersChange = onFiltersChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            seasonControls
            UnderlineTabs(options: ExplorerFilters.scopes, selected: vm.filters.scope) { vm.filters.scope = $0 }
            SplitsPanel(filters: $vm.filters, entity: vm.entity, expanded: $showSplits)
            result
        }
        .task(id: vm.currentQuery) { await vm.load() }
        .onAppear { onFiltersChange?(vm.filters) }
        .onChange(of: vm.filters) { onFiltersChange?($0) }
    }

    // MARK: - Season + type

    private var seasonControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Season")
                    .font(.brandBody(.footnote, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Menu {
                    ForEach(vm.seasons, id: \.self) { season in
                        Button(season) { vm.filters.season = season }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(vm.filters.season ?? "—").monospacedDigit()
                        Image(systemName: "chevron.up.chevron.down").font(.caption)
                    }
                    .font(.brandBody(.body))
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(Color.card)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.field, lineWidth: 1))
                }
                .opacity(vm.filters.scope == "career" ? 0.5 : 1)
                .accessibilityLabel("Season: \(vm.filters.season ?? "none")")
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Season type")
                    .font(.brandBody(.footnote, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Pills(label: "Season type", options: ExplorerFilters.seasonTypes, selected: vm.filters.seasonType) {
                    vm.filters.seasonType = $0
                }
            }
        }
    }

    // MARK: - Result

    @ViewBuilder
    private var result: some View {
        if vm.isCurrent, let result = vm.result {
            ResultView(vm: vm, result: result, props: props)
        } else if let error = vm.error {
            ErrorCard(error: error) { Task { await vm.load() } }
        } else {
            LoadingCard(label: "Crunching…")
        }
    }
}

// MARK: - Splits panel

private struct SplitsPanel: View {
    @Binding var filters: ExplorerFilters
    let entity: QueryEntity
    @Binding var expanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
            } label: {
                HStack {
                    Text("Splits\(filters.splitCount > 0 ? " · \(filters.splitCount) applied" : "")")
                        .font(.brandBody(.body, weight: .semibold))
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.footnote.weight(.semibold))
                }
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.field, lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")

            if expanded { panel }
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if entity == .player {
                row("Rest measured by") {
                    Pills(label: "Rest measured by", options: [("player", "His games"), ("team", "Team's schedule")],
                          selected: filters.restBy, small: true) { filters.restBy = $0 }
                }
            }
            ForEach(ExplorerFilters.Split.allCases, id: \.self) { split in
                row(split.label) {
                    Pills(label: split.label, options: split.options, selected: filters[split] ?? "all", small: true) {
                        filters[split] = $0
                    }
                }
            }
            Rectangle().fill(Color.rule).frame(height: 1)
            Text((entity == .player && filters.restBy == "player"
                  ? "Rest and back-to-back count the games he played (how NBA.com splits players)."
                  : "Rest and back-to-back follow the team schedule.") + " Splits apply first, then Last 5 / Last 10.")
                .font(.brandBody(.footnote))
                .foregroundStyle(Color.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                filters.clearSplits()
            } label: {
                Text("Clear splits\(filters.splitCount > 0 ? " (\(filters.splitCount))" : "")")
                    .font(.brandBody(.subheadline, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 36)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.field, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(filters.splitCount == 0)
            .opacity(filters.splitCount == 0 ? 0.4 : 1)
        }
        .padding(16)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func row<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.brandBody(.footnote, weight: .semibold))
                .foregroundStyle(Color.muted)
            content()
        }
    }
}

// MARK: - Result

private struct ResultView: View {
    @ObservedObject var vm: StatExplorerViewModel
    let result: ExplorerResult
    let props: PlayerProps?

    private var filters: ExplorerFilters { vm.filters }
    private var meta: QueryMeta { result.meta }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if !meta.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(meta.notes, id: \.self) { note in
                        Text(note)
                            .font(.brandBody(.footnote))
                            .foregroundStyle(Color.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            content
            footer
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(ExplorerFilters.scopeLabel[filters.scope] ?? filters.scope) · \(meta.sampleSize) game\(meta.sampleSize == 1 ? "" : "s")")
                .font(.brandBody(.headline, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color.ink)
            Text(subline)
                .font(.brandBody(.subheadline))
                .monospacedDigit()
                .foregroundStyle(Color.muted)
        }
        .accessibilityElement(children: .combine)
    }

    private var subline: String {
        var text = ""
        if meta.sampleSize > 0, let record = meta.record { text += "\(record) in these games · " }
        text += filters.whereText
        let n = filters.splitCount
        if n > 0 { text += " · \(n) split\(n == 1 ? "" : "s") applied" }
        return text
    }

    @ViewBuilder
    private var content: some View {
        if meta.sampleSize == 0 {
            NoGamesView(name: vm.name, filters: filters, played: vm.playedTypes,
                        onType: { vm.filters.seasonType = $0 }, onClear: { vm.filters.clearSplits() })
        } else {
            switch result.content {
            case .career(let career):
                PropCheckView(props: props, hits: result.props)
                if let career { CareerTable(entity: vm.entity, career: career) }
            case .gameLog(let rows):
                GameLogTable(entity: vm.entity, rows: rows, restBy: filters.restBy)
            case .averages(let averages):
                PropCheckView(props: props, hits: result.props)
                if let averages { StatTiles(entity: vm.entity, d: averages) }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle().fill(Color.line).frame(height: 1)
            Text("From NBA.com game logs"
                 + (Format.ago(meta.freshness?.syncedAt).map { " · synced \($0)" } ?? "")
                 + (meta.cached == true ? " · cached" : ""))
                .font(.brandBody(.footnote))
                .foregroundStyle(Color.muted)
        }
    }
}
