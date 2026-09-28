//
//  GameCardView.swift
//  Chalk That NBA
//
//  One game on the scoreboard (Scoreboard.jsx `GameCard`): status, away
//  then home with scores (winner bold, loser muted once final), and a
//  context line (playoff round + game, Play-In, Cup stage, "in Tokyo")
//  with national TV on the right. Final games get the heavier border.
//
import SwiftUI

struct GameCardView: View {
    let game: ScoreboardGame

    private var status: String {
        switch game.status {
        case "final": return "Final"
        case "live": return "Live"
        case "postponed": return "Postponed"
        case "cancelled": return "Cancelled"
        default: return Format.tipTime(game.tipoffUtc)
        }
    }

    private var context: String {
        Format.gameContext(seasonType: game.seasonType, seriesRound: game.seriesRound,
                           seriesGameNumber: game.seriesGameNumber, cupStage: game.cupStage,
                           isNeutralSite: game.isNeutralSite, arenaCity: game.arenaCity)
    }

    private var tv: String? {
        game.nationalTvTier != "local" && !game.nationalBroadcasters.isEmpty
            ? game.nationalBroadcasters.joined(separator: ", ") : nil
    }

    private var awayWon: Bool { game.isFinal && (game.awayScore ?? 0) > (game.homeScore ?? 0) }
    private var homeWon: Bool { game.isFinal && (game.homeScore ?? 0) > (game.awayScore ?? 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: status, color: game.isLive ? .live : .muted)
                Spacer()
                Eyebrow(text: game.isFinal ? "Box score →" : "Preview →", color: .link)
            }
            row(game.away, game.awayScore, won: awayWon)
            row(game.home, game.homeScore, won: homeWon)
            if !context.isEmpty || tv != nil {
                HStack(alignment: .top) {
                    Text(context)
                    Spacer(minLength: 12)
                    if let tv { Text(tv).multilineTextAlignment(.trailing) }
                }
                .font(.brandBody(.footnote))
                .foregroundStyle(Color.muted)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.card)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(game.isFinal ? Color.strong : Color.line, lineWidth: game.isFinal ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }

    private func row(_ team: String, _ score: Int?, won: Bool) -> some View {
        HStack {
            Text(team)
            Spacer()
            Text(score.map(String.init) ?? "")
        }
        .font(.brandBody(.title3, weight: won ? .bold : (game.isFinal ? .regular : .medium)))
        .monospacedDigit()
        .foregroundStyle(game.isFinal && !won ? Color.muted : Color.ink)
    }
}
