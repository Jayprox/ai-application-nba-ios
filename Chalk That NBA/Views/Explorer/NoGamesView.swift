//
//  NoGamesView.swift
//  Chalk That NBA
//
//  Why there are no games, in plain words, with the one-tap way out (the
//  web's `NoGames`, same wording). `NoGamesMessage` is pure so tests can
//  pin every case:
//    - NBA Cup before 2023-24
//    - a season type he didn't play (Curry 2025-26 playoffs), with
//      "Show …" buttons for the types he did play
//    - splits that match nothing, with "Clear splits"
//    - otherwise "No games for X in the 2025-26 regular season."
//
import SwiftUI

struct NoGamesMessage: Equatable {
    enum Action: Equatable {
        case showType(value: String, label: String)
        case clearSplits
    }
    let text: String
    let actions: [Action]

    private static let typeName = ["regular": "regular season", "play_in": "play-in", "playoffs": "playoffs", "cup": "NBA Cup"]
    private static let typeButton = ["regular": "Regular season", "play_in": "Play-In", "playoffs": "Playoffs", "cup": "NBA Cup"]
    private static let typeOrder = ["regular", "play_in", "playoffs", "cup"]

    static func make(name: String, filters f: ExplorerFilters, played: [String]?) -> NoGamesMessage {
        let capitalized = name.prefix(1).uppercased() + name.dropFirst()
        let possessive = name.hasSuffix("s") ? "\(name)'" : "\(name)'s"
        let season = f.season ?? ""

        if f.seasonType == "cup", f.scope != "career", season < "2023-24" {
            return NoGamesMessage(text: "The NBA Cup started in 2023-24, so there are no Cup games in \(season).", actions: [])
        }
        if f.splitCount == 0, let played, f.seasonType != "all", !played.contains(f.seasonType) {
            // Keep the API's order for the sentence, as the web does.
            let other = played.filter { typeName[$0] != nil }
            var text = "\(capitalized) didn't play in the \(season) \(typeName[f.seasonType] ?? f.seasonType)."
            if !other.isEmpty {
                text += " Games that season: \(other.compactMap { typeName[$0] }.joined(separator: ", "))."
            }
            return NoGamesMessage(text: text, actions: other.map { .showType(value: $0, label: "Show \(typeButton[$0] ?? $0)") })
        }
        if f.splitCount > 0 {
            return NoGamesMessage(
                text: "None of \(possessive) \(f.whereText) games match \(f.splitCount == 1 ? "this split" : "these splits").",
                actions: [.clearSplits])
        }
        return NoGamesMessage(text: "No games for \(name) in the \(f.whereText).", actions: [])
    }
}

struct NoGamesView: View {
    let name: String
    let filters: ExplorerFilters
    let played: [String]?
    let onType: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        let message = NoGamesMessage.make(name: name, filters: filters, played: played)
        EmptyCard {
            Text(message.text).fixedSize(horizontal: false, vertical: true)
            if !message.actions.isEmpty {
                FlowLayout(spacing: 16, lineSpacing: 10) {
                    ForEach(Array(message.actions.enumerated()), id: \.offset) { _, action in
                        switch action {
                        case .showType(let value, let label):
                            link(label) { onType(value) }
                        case .clearSplits:
                            link("Clear splits", action: onClear)
                        }
                    }
                }
            }
        }
    }

    private func link(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.brandBody(.subheadline, weight: .medium))
                .underline()
                .foregroundStyle(Color.link)
        }
        .buttonStyle(.plain)
    }
}
