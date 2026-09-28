//
//  ScoreboardView.swift
//  Chalk That NBA
//
//  The Scores tab (the web's pages/Scoreboard.jsx): one calendar date's
//  games. Header = eyebrow (season · season type), the long date, and
//  prev / date picker / next. The arrows use meta.prev_date / next_date,
//  so they skip empty days (All-Star break, offseason). Live games
//  refresh about every 60 s while this screen is showing.
//
import SwiftUI

struct ScoreboardView: View {
    @StateObject private var vm = ScoreboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                content
            }
            .padding(16)
        }
        .background(Color.paper)
        .refreshable { await vm.load(quietly: vm.isCurrent) }
        .task(id: vm.date) { await vm.run() }
        .navigationTitle("Scores")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { Wordmark(size: 20) }
        }
    }

    // MARK: - Header

    private var meta: GamesMeta? { vm.isCurrent ? vm.meta : nil }

    private var eyebrow: String {
        guard vm.isCurrent, let first = vm.games.first else { return "Scoreboard" }
        return "\(first.season) · \(Format.seasonType(first.seasonType) ?? first.seasonType)"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: eyebrow)
            Text(Format.longDate(vm.date))
                .font(.brandDisplay(30, weight: .bold, relativeTo: .largeTitle))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                arrow(systemImage: "chevron.left", target: meta?.prevDate,
                      label: meta?.prevDate.map { "Previous game day, \(Format.tinyDate($0, relativeTo: vm.date))" } ?? "No earlier games")

                DatePicker("Date", selection: pickerBinding, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Color.accent)

                arrow(systemImage: "chevron.right", target: meta?.nextDate,
                      label: meta?.nextDate.map { "Next game day, \(Format.tinyDate($0, relativeTo: vm.date))" } ?? "No later games")
            }
        }
    }

    private var pickerBinding: Binding<Date> {
        Binding(
            get: { Format.localDate(fromYmd: vm.date) ?? Date() },
            set: { vm.go(to: Format.ymd(fromLocal: $0)) }
        )
    }

    private func arrow(systemImage: String, target: String?, label: String) -> some View {
        Button {
            vm.go(to: target)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.field, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(target == nil)
        .opacity(target == nil ? 0.4 : 1)
        .accessibilityLabel(label)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if vm.isCurrent {
            if vm.games.isEmpty {
                emptyDay
            } else {
                VStack(spacing: 12) {
                    ForEach(vm.games) { game in
                        NavigationLink(value: AppRoute.game(id: game.id)) {
                            GameCardView(game: game)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Divider().overlay(Color.line)
                Text("\(vm.games.count) game\(vm.games.count == 1 ? "" : "s") · tip-off times in your time zone")
                    .font(.brandBody(.footnote))
                    .foregroundStyle(Color.muted)
            }
        } else if let error = vm.error {
            ErrorCard(error: error) { Task { await vm.load(quietly: false) } }
        } else {
            LoadingCard(label: "Loading games…")
        }
    }

    private var emptyDay: some View {
        EmptyCard {
            Text("No NBA games on \(Format.longDate(vm.date)).")
            VStack(alignment: .leading, spacing: 10) {
                if let prev = meta?.prevDate {
                    linkButton("← Previous game day (\(Format.tinyDate(prev, relativeTo: vm.date)))") { vm.go(to: prev) }
                }
                if let next = meta?.nextDate {
                    linkButton("Next game day (\(Format.tinyDate(next, relativeTo: vm.date))) →") { vm.go(to: next) }
                }
            }
        }
    }

    private func linkButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.brandBody(.subheadline, weight: .medium))
                .underline()
                .foregroundStyle(Color.link)
        }
        .buttonStyle(.plain)
    }
}
