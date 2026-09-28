//
//  LeadersView.swift
//  Chalk That NBA
//
//  The Leaders tab (the web's pages/Leaders.jsx): top 25 per game for
//  Points, Rebounds, Assists, 3-pointers, Steals, Blocks and Usage, by
//  season and Regular / Playoffs / All. The "Who qualifies" card comes
//  from meta.qualifier (70% of team games; usage also 15+ min). Usage
//  shows as "28.3%" with the "estimated" explanation.
//
import SwiftUI

struct LeadersView: View {
    @StateObject private var vm: LeadersViewModel

    init(season: String? = nil, seasonType: String? = nil, stat: String? = nil) {
        _vm = StateObject(wrappedValue: LeadersViewModel(season: season, seasonType: seasonType, stat: stat))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let key = vm.key {
                    header(key)
                    controls(key)
                    UnderlineTabs(options: LeadersViewModel.stats, selected: key.stat) { vm.key?.stat = $0 }
                    list(key)
                    qualifierCard(key)
                    Text(key.stat == "usg_pct"
                         ? "Usage: the share of his team's plays (shots, free-throw trips, turnovers) he used while on the floor. Estimated from box scores; NBA.com counts on-floor plays from play-by-play, so it can differ by about a point."
                         : "\(label(key.stat)) per game · computed from NBA.com game logs")
                        .font(.brandBody(.footnote))
                        .foregroundStyle(Color.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let error = vm.error {
                    ErrorCard(error: error) { Task { await vm.loadSeasons() } }
                } else {
                    LoadingCard()
                }
            }
            .padding(16)
        }
        .background(Color.paper)
        .navigationTitle("Leaders")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadSeasons() }
        .task(id: vm.key) { await vm.load() }
    }

    private func label(_ stat: String) -> String {
        LeadersViewModel.stats.first { $0.value == stat }?.label ?? stat
    }

    private func typeName(_ type: String) -> String {
        type == "all" ? "All game types" : (Format.seasonType(type) ?? type)
    }

    private func header(_ key: LeadersViewModel.Key) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: "\(key.season) · \(typeName(key.seasonType)) · \(key.stat == "usg_pct" ? "usage rate" : "per game")")
            Text("League leaders")
                .font(.brandDisplay(32, weight: .bold, relativeTo: .largeTitle))
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func controls(_ key: LeadersViewModel.Key) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SeasonMenu(seasons: vm.seasons, selected: key.season) { vm.key?.season = $0 }
            VStack(alignment: .leading, spacing: 6) {
                Text("Season type")
                    .font(.brandBody(.footnote, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Pills(label: "Season type", options: LeadersViewModel.types, selected: key.seasonType) { vm.key?.seasonType = $0 }
            }
        }
    }

    @ViewBuilder
    private func list(_ key: LeadersViewModel.Key) -> some View {
        if vm.isCurrent {
            if vm.rows.isEmpty {
                EmptyCard { Text("No qualified players for \(key.season) (\(typeName(key.seasonType).lowercased())).") }
            } else {
                VStack(spacing: 0) {
                    ForEach(vm.rows) { row in
                        NavigationLink(value: AppRoute.player(id: row.playerId, season: key.season,
                                                              seasonType: key.seasonType == "regular" ? nil : key.seasonType)) {
                            leaderRow(row, usage: key.stat == "usg_pct")
                        }
                        .buttonStyle(.plain)
                        if row.id != vm.rows.last?.id { Rectangle().fill(Color.rule).frame(height: 1) }
                    }
                }
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        } else if let error = vm.error {
            ErrorCard(error: error) { Task { await vm.load() } }
        } else {
            LoadingCard()
        }
    }

    private func leaderRow(_ row: LeaderRow, usage: Bool) -> some View {
        HStack(spacing: 12) {
            Text(String(row.rank))
                .font(.brandBody(.headline, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.muted)
                .frame(minWidth: 28, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.fullName)
                    .font(.brandBody(.body, weight: .semibold))
                    .foregroundStyle(Color.link)
                Text("\(row.team ?? "") · \(row.gp) GP")
                    .font(.brandBody(.subheadline))
                    .monospacedDigit()
                    .foregroundStyle(Color.muted)
            }
            Spacer()
            Text(usage ? Format.usgPct(row.value) : Format.avg(row.value))
                .font(.brandDisplay(26, weight: .bold, relativeTo: .title2))
                .monospacedDigit()
                .foregroundStyle(Color.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// The web's "Who qualifies" card, same wording.
    private func qualifierCard(_ key: LeadersViewModel.Key) -> some View {
        let q = vm.isCurrent ? vm.meta?.qualifier : nil
        return VStack(alignment: .leading, spacing: 8) {
            Text("Who qualifies")
                .font(.brandDisplay(22, weight: .bold, relativeTo: .title3))
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            qualifierText(q, season: key.season)
                .font(.brandBody(.subheadline))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("This is Chalk That's rule, not the NBA's official qualifier. It scales with games played, so it works early in the season too, and a 1-game outlier can't top the list.")
                .font(.brandBody(.footnote))
                .foregroundStyle(Color.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func qualifierText(_ q: QueryMeta.Qualifier?, season: String) -> Text {
        let base = Text("Played in at least ") + Text("70% of the team's games").bold()
        guard let q else { return base + Text(".") }
        var text = base + Text(": \(q.minGames) of \(q.teamGames)\(season == vm.currentSeason ? " so far" : "")")
        if let minutes = q.minMinutes {
            text = text + Text(", and ") + Text("\(minutes)+ minutes per game").bold()
        }
        text = text + Text(". ")
        if let n = q.qualifiedPlayers {
            text = text + Text("\(n) player\(n == 1 ? "" : "s")").bold() + Text(" \(n == 1 ? "qualifies" : "qualify").")
        }
        return text
    }
}

/// A labeled season picker (the web's `<Select id="season">`).
struct SeasonMenu: View {
    let seasons: [String]
    let selected: String?
    var dimmed = false
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Season")
                .font(.brandBody(.footnote, weight: .semibold))
                .foregroundStyle(Color.ink)
            Menu {
                ForEach(seasons, id: \.self) { season in
                    Button(season) { onSelect(season) }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(selected ?? "—").monospacedDigit()
                    Image(systemName: "chevron.up.chevron.down").font(.caption)
                }
                .font(.brandBody(.body))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.field, lineWidth: 1))
            }
            .opacity(dimmed ? 0.5 : 1)
            .accessibilityLabel("Season: \(selected ?? "none")")
        }
    }
}
