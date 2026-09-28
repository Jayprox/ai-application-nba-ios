//
//  PropsBoardView.swift
//  Chalk That NBA
//
//  The Props tab (the web's pages/Props.jsx, phone layout: one card per
//  player). DraftKings lines for a date and market, each next to how
//  often he went over that exact line in his last 10 and this season
//  (last season before he has played), his average, the matchup note,
//  line movement from the open, and the graded result after the final.
//  Counts, not picks.
//
import SwiftUI

struct PropsBoardView: View {
    @StateObject private var vm = PropsBoardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                UnderlineTabs(options: Markets.all.map { (value: $0.key, label: $0.short) }, selected: vm.key.market) {
                    vm.key.market = $0
                }
                content
            }
            .padding(16)
        }
        .background(Color.paper)
        .navigationTitle("Props")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await vm.load() }
        .task(id: vm.key) { await vm.load() }
    }

    // MARK: - Header (date navigation, like the scoreboard)

    private var meta: PropBoardMeta? { vm.isCurrent ? vm.response?.meta : nil }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Props · DraftKings")
            Text(vm.shownDate.map(Format.longDate) ?? "Props")
                .font(.brandDisplay(30, weight: .bold, relativeTo: .largeTitle))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                arrow("chevron.left", meta?.prevDate,
                      meta?.prevDate.map { "Previous date with lines, \(Format.tinyDate($0, relativeTo: vm.shownDate))" } ?? "No earlier lines")
                if let shown = vm.shownDate {
                    DatePicker("Date", selection: Binding(
                        get: { Format.localDate(fromYmd: shown) ?? Date() },
                        set: { vm.go(to: Format.ymd(fromLocal: $0)) }
                    ), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Color.accent)
                }
                arrow("chevron.right", meta?.nextDate,
                      meta?.nextDate.map { "Next date with lines, \(Format.tinyDate($0, relativeTo: vm.shownDate))" } ?? "No later lines")
            }
        }
    }

    private func arrow(_ icon: String, _ target: String?, _ label: String) -> some View {
        Button { vm.go(to: target) } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.field, lineWidth: 1))
        }
        .disabled(target == nil)
        .opacity(target == nil ? 0.4 : 1)
        .accessibilityLabel(label)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if vm.isCurrent, let response = vm.response {
            filters(response)
            let rows = vm.rows
            if rows.isEmpty {
                noLines(response)
            } else {
                summary(rows, label: response.meta.marketLabel)
                LazyVStack(spacing: 10) {
                    ForEach(rows) { PropCard(row: $0) }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Rectangle().fill(Color.line).frame(height: 1).padding(.bottom, 6)
                ForEach(response.meta.notes, id: \.self) { Text($0) }
            }
            .font(.brandBody(.footnote))
            .foregroundStyle(Color.muted)
            .fixedSize(horizontal: false, vertical: true)
        } else if let error = vm.error {
            ErrorCard(error: error) { Task { await vm.load() } }
        } else {
            LoadingCard(label: "Loading lines…")
        }
    }

    private func gameLabel(_ g: PropBoardGame) -> String {
        "\(g.away) @ \(g.home) · \(g.status == "final" ? "Final" : g.status == "live" ? "Live" : Format.tipTime(g.tipoffUtc))"
    }

    private func filters(_ response: PropBoardResponse) -> some View {
        let games = response.games
        let selectedGame = games.first { $0.id == vm.gameFilter }
        return HStack(spacing: 10) {
            labeledMenu("Game", value: selectedGame.map(gameLabel) ?? "All games (\(games.count))") {
                Button("All games (\(games.count))") { vm.gameFilter = "all" }
                ForEach(games) { g in Button(gameLabel(g)) { vm.gameFilter = g.id } }
            }
            labeledMenu("Sort by", value: vm.sort.label) {
                ForEach(PropText.Sort.allCases, id: \.self) { s in Button(s.label) { vm.sort = s } }
            }
        }
    }

    private func labeledMenu<Items: View>(_ label: String, value: String, @ViewBuilder items: () -> Items) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.brandBody(.footnote, weight: .semibold))
                .foregroundStyle(Color.ink)
            Menu {
                items()
            } label: {
                HStack(spacing: 6) {
                    Text(value).lineLimit(1)
                    Spacer(minLength: 2)
                    Image(systemName: "chevron.up.chevron.down").font(.caption)
                }
                .font(.brandBody(.subheadline))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.field, lineWidth: 1))
            }
            .accessibilityLabel("\(label): \(value)")
        }
    }

    private func summary(_ rows: [PropBoardRow], label: String) -> some View {
        let closed = rows.filter { $0.snapshot == "close" }.count
        let note = closed == rows.count ? "Closing lines"
            : closed > 0 ? "Closing lines for \(closed) of \(rows.count), opening lines for the rest"
            : "Opening lines (closing lines come ~30 min before tip)"
        return VStack(alignment: .leading, spacing: 2) {
            Text("\(label) · \(rows.count) player\(rows.count == 1 ? "" : "s")")
                .font(.brandBody(.headline, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color.ink)
            Text(note)
                .font(.brandBody(.subheadline))
                .foregroundStyle(Color.muted)
        }
    }

    /// The web's `NoLines`, same three messages.
    private func noLines(_ r: PropBoardResponse) -> some View {
        let m = r.meta
        let any = m.prevDate != nil || m.nextDate != nil
        let date = m.date.map(Format.longDate) ?? ""
        let text = !any && m.count == 0 && r.games.isEmpty
            ? "No prop lines yet. The worker pulls DraftKings lines on game days, starting with the regular season."
            : !r.games.isEmpty
                ? "No \(m.marketLabel.lowercased()) lines for \(date) yet. Opening lines are pulled from 9 am ET on game day, closing lines about 30 minutes before tip."
                : "No games with lines on \(date)."
        return EmptyCard {
            Text(text).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                if let prev = m.prevDate { link("← \(Format.tinyDate(prev, relativeTo: m.date))") { vm.go(to: prev) } }
                if let next = m.nextDate { link("\(Format.tinyDate(next, relativeTo: m.date)) →") { vm.go(to: next) } }
            }
        }
    }

    private func link(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.brandBody(.subheadline, weight: .medium)).underline().foregroundStyle(Color.link)
        }
        .buttonStyle(.plain)
    }
}

/// One player's line (Props.jsx `Cards`).
struct PropCard: View {
    let row: PropBoardRow

    var body: some View {
        let r = row
        let move = PropText.movement(open: r.openLine, line: r.line)
        let season = PropText.seasonOf(r)
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    NavigationLink(value: AppRoute.player(id: r.playerId)) {
                        Text(r.name)
                            .font(.brandBody(.body, weight: .semibold))
                            .foregroundStyle(Color.link)
                    }
                    .buttonStyle(.plain)
                    Text(PropText.matchup(r))
                        .font(.brandBody(.caption))
                        .foregroundStyle(Color.muted)
                    if let note = PropText.matchupText(r.matchup) {
                        HStack(spacing: 4) {
                            Text(note)
                            if let tag = r.matchup?.label {
                                Text("\(tag) D")
                                    .font(.brandBody(.caption2, weight: .semibold))
                                    .foregroundStyle(tag == "weak" ? Color.altInk : Color.ink)
                                    .padding(.horizontal, 5)
                                    .background(tag == "weak" ? Color.altBg : Color.clear)
                                    .overlay(Capsule().stroke(tag == "weak" ? Color.clear : Color.line, lineWidth: 1))
                                    .clipShape(Capsule())
                            }
                        }
                        .font(.brandBody(.caption))
                        .foregroundStyle(Color.muted)
                        .accessibilityElement(children: .combine)
                        .accessibilityHint(matchupHint(r.matchup))
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Format.jsNumber(r.line))
                        .font(.brandDisplay(24, weight: .bold, relativeTo: .title2))
                        .foregroundStyle(Color.ink)
                    Text("o\(Markets.price(r.overPrice)) / u\(Markets.price(r.underPrice))"
                         + (move.map { " · \($0.up ? "▲" : "▼") \(Format.jsNumber(r.openLine ?? 0))" } ?? ""))
                        .font(.brandBody(.caption))
                        .foregroundStyle(Color.muted)
                }
                .monospacedDigit()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Line \(Format.jsNumber(r.line)), over \(Markets.price(r.overPrice)), under \(Markets.price(r.underPrice))"
                                    + (move.map { ", \($0.up ? "up" : "down") from \(Format.jsNumber(r.openLine ?? 0))" } ?? ""))
            }
            Rectangle().fill(Color.rule).frame(height: 1)
            HStack(alignment: .top) {
                stat("Last 10", PropText.hits(r.last10), bold: true)
                stat(season.isLastSeason ? "Last szn" : "Season", PropText.hits(season.rate), bold: true)
                stat("Avg", Format.avg(season.rate?.avg), bold: false)
                VStack(alignment: .trailing, spacing: 2) {
                    Eyebrow(text: "Result")
                    if let result = r.result {
                        Text(Markets.resultLabel[result] ?? result)
                            .font(.brandBody(.subheadline, weight: .semibold))
                            .foregroundStyle(Color.ink)
                        if let actual = r.actual {
                            Text(Format.jsNumber(actual)).font(.brandBody(.caption)).foregroundStyle(Color.muted)
                        }
                    } else {
                        Text(r.snapshot == "close" ? "Closing" : "Opening")
                            .font(.brandBody(.subheadline))
                            .foregroundStyle(Color.muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityElement(children: .combine)
            }
            .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func stat(_ label: String, _ value: String, bold: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Eyebrow(text: label)
            Text(value)
                .font(.brandBody(.subheadline, weight: bold ? .semibold : .regular))
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// The web's title tooltip on the matchup note.
    private func matchupHint(_ m: MatchupNote?) -> String {
        guard let m else { return "" }
        let vs = m.vsAvg.map { "\($0 > 0 ? "+" : "")\(Format.jsNumber($0))" } ?? ""
        return "\(m.opponent) allows \(m.allowed.map(Format.jsNumber) ?? "—") per game to \(m.positionLabel.lowercased()) in this stat (\(vs) vs league average), \(m.games ?? 0) games"
    }
}
