//
//  BoxScoreView.swift
//  Chalk That NBA
//
//  The web's pages/BoxScore.jsx: a result header (AWAY score @ HOME
//  score, status, arena · season type, extra context), the split tags
//  each team carried into this game (the same tags the filters use), then
//  one table per team, away first. Refreshes about every 60 s while live.
//
import SwiftUI

struct BoxScoreView: View {
    @StateObject private var vm: BoxScoreViewModel

    init(gameId: String) {
        _vm = StateObject(wrappedValue: BoxScoreViewModel(gameId: gameId))
    }

    private var title: String {
        guard let teams = vm.box?.teams, teams.count >= 2 else { return "Box score" }
        return "\(teams[0].abbreviation) @ \(teams[1].abbreviation)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let box = vm.box {
                    BoxScoreContent(box: box)
                } else if let error = vm.error {
                    if ErrorCard.isNotFound(error) {
                        ErrorCard(error: error)
                    } else {
                        ErrorCard(error: error) { Task { await vm.load(quietly: false) } }
                    }
                } else {
                    LoadingCard(label: "Loading box score…")
                }
            }
            .padding(16)
        }
        .background(Color.paper)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await vm.load(quietly: vm.box != nil) }
        .task { await vm.run() }
    }
}

private struct BoxScoreContent: View {
    let box: BoxScore

    private var game: BoxScoreGame { box.game }

    var body: some View {
        if box.teams.count >= 2 {
            let away = box.teams[0]
            let home = box.teams[1]
            header(away: away, home: home)
            splitTags(away: away, home: home)
            if away.players.isEmpty && home.players.isEmpty {
                EmptyCard { Text(emptyMessage) }
            } else {
                ForEach([away, home]) { team in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(team.fullName)
                            .font(.brandDisplay(24, weight: .bold, relativeTo: .title2))
                            .foregroundStyle(Color.ink)
                        BoxScoreTable(team: team)
                        if team.players.contains(where: { $0.started == true }) {
                            Text("S = starter")
                                .font(.brandBody(.footnote))
                                .foregroundStyle(Color.muted)
                        }
                    }
                }
            }
        } else {
            statusBlock
            EmptyCard { Text(emptyMessage) }
        }
    }

    private var emptyMessage: String {
        game.isFinal ? "No player box score in the source data for this game."
                     : "The box score appears here once the game is played."
    }

    // MARK: - Header

    private func header(away: BoxScoreTeam, home: BoxScoreTeam) -> some View {
        let winner: Int? = game.isFinal ? ((game.homeScore ?? 0) > (game.awayScore ?? 0) ? home.teamId : away.teamId) : nil
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                side(away, score: game.awayScore, dim: winner != nil && winner != away.teamId)
                Text("@")
                    .font(.brandBody(.headline))
                    .foregroundStyle(Color.muted)
                side(home, score: game.homeScore, dim: winner != nil && winner != home.teamId)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityElement(children: .combine)

            statusBlock
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func side(_ team: BoxScoreTeam, score: Int?, dim: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(team.abbreviation)
                .font(.brandDisplay(30, weight: dim ? .semibold : .bold, relativeTo: .title))
            if let score {
                Text(String(score))
                    .font(.brandDisplay(42, weight: dim ? .semibold : .bold, relativeTo: .largeTitle))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(dim ? Color.muted : Color.ink)
    }

    /// Status line, arena · season type, and extra context (Cup stage,
    /// neutral city). Mirrors BoxScore.jsx's `statusLine` / `context`.
    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(statusLine)
                .font(.brandBody(.subheadline, weight: .semibold))
                .foregroundStyle(Color.ink)
            if !arenaLine.isEmpty {
                Text(arenaLine)
            }
            if !context.isEmpty {
                Text(context)
            }
        }
        .font(.brandBody(.subheadline))
        .foregroundStyle(Color.muted)
    }

    private var statusLine: String {
        let date = Format.shortDate(game.gameDateLocal)
        if game.isFinal { return "Final · \(date)" }
        if game.isLive { return "Live" }
        return "\(game.status == "postponed" ? "Postponed" : Format.tipTime(game.tipoffUtc)) · \(date)"
    }

    private var arenaLine: String {
        var bits: [String] = []
        if let arena = game.arena { bits.append("\(arena), \(game.arenaCity ?? "")") }
        if let type = Format.seasonType(game.seasonType) { bits.append(type) }
        return bits.joined(separator: " · ")
    }

    /// The season type is already on the arena line, so keep only the extra bits.
    private var context: String {
        let full = Format.gameContext(seasonType: game.seasonType, seriesRound: nil,
                                      seriesGameNumber: game.seriesGameNumber, cupStage: game.cupStage,
                                      isNeutralSite: game.isNeutralSite, arenaCity: game.arenaCity)
        let typeLabel = Format.seasonType(game.seasonType)
        return full.components(separatedBy: " · ")
            .filter { !$0.isEmpty && $0 != typeLabel && $0 != "Play-In" }
            .joined(separator: " · ")
    }

    // MARK: - Split tags

    private func splitTags(away: BoxScoreTeam, home: BoxScoreTeam) -> some View {
        let altitude = game.isHighAltitude == true
        return FlowLayout(spacing: 8, lineSpacing: 8) {
            Text("Split tags:")
                .font(.brandBody(.footnote, weight: .semibold))
                .foregroundStyle(Color.muted)
                .padding(.vertical, 4)
            ForEach([away, home]) { team in
                Chip(text: "\(team.abbreviation): \(team.venueSplit) · \(Format.restLabel(team.restDays, b2b: team.b2bNight))")
            }
            Chip(text: "Altitude: \(altitude ? "yes" : "no")", highlighted: altitude)
            Chip(text: Format.tvLabel(tier: game.nationalTvTier, networks: game.nationalBroadcasters))
        }
    }
}
