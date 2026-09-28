//
//  DefenseByPositionView.swift
//  Chalk That NBA
//
//  "Defense by position" on team detail (TeamDetail.jsx +
//  Rankings.jsx `MatchupTable`, firstCol "position"): what opponents'
//  guards, forwards and centers average against this team, with the rank
//  (1 = allows the fewest) and the difference from league average, plus
//  "strong" / "weak" when the API labels it. On a phone each position is
//  a card of Points / Rebounds / Assists / 3PM instead of a wide table;
//  the numbers are the same.
//
import SwiftUI

struct DefenseByPositionView: View {
    let teamId: Int
    let teamName: String
    let season: String
    let seasonType: String

    @StateObject private var vm = DefenseByPositionViewModel()

    private var key: DefenseByPositionViewModel.Key {
        .init(season: season, seasonType: seasonType == "playoffs" ? "playoffs" : "regular")
    }

    private static let stats: [(key: String, label: String)] = [("pts", "Points"), ("reb", "Rebounds"), ("ast", "Assists"), ("fg3m", "3PM")]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Defense by position",
                         note: "What opponents score against the \(teamName), \(key.season) \(key.seasonType == "playoffs" ? "playoffs" : "regular season")")
            if vm.loadedKey == key {
                if vm.rows.isEmpty {
                    EmptyCard { Text("No \(key.seasonType == "playoffs" ? "playoff" : "regular-season") games for the \(teamName) in \(key.season).") }
                } else {
                    ForEach(vm.rows, id: \.position) { item in
                        positionCard(item.title, item.row)
                    }
                    Text("Per game to opposing guards, forwards and centers; small number = vs league average. Rank 1 = allows the fewest.")
                        .font(.brandBody(.caption))
                        .foregroundStyle(Color.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if let error = vm.error {
                ErrorCard(error: error) { Task { await vm.load(teamId: teamId, key: key) } }
            } else {
                LoadingCard()
            }
        }
        .task(id: key) { await vm.load(teamId: teamId, key: key) }
    }

    private func positionCard(_ title: String, _ row: MatchupRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.brandBody(.headline, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("\(row.games) GP")
                    .font(.brandBody(.footnote))
                    .monospacedDigit()
                    .foregroundStyle(Color.muted)
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(Self.stats, id: \.key) { stat in
                    statCell(stat.label, stat.key, row)
                }
            }
        }
        .padding(14)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statCell(_ label: String, _ key: String, _ row: MatchupRow) -> some View {
        let allowed = row.allowed[key] ?? nil
        let vsAvg = row.vsAvg[key] ?? nil
        let rank = row.rank[key] ?? nil
        let tag = row.label[key] ?? nil
        let sub = Format.signedAvg(vsAvg) + (tag.map { " · \($0)" } ?? "")
        return VStack(alignment: .leading, spacing: 2) {
            Eyebrow(text: label)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Format.avg(allowed))
                    .font(.brandBody(.title3, weight: .semibold))
                    .foregroundStyle(Color.ink)
                if let rank {
                    Text(Format.ordinal(rank))
                        .font(.brandBody(.caption))
                        .foregroundStyle(Color.muted)
                }
            }
            .monospacedDigit()
            Text(sub)
                .font(.brandBody(.caption))
                .monospacedDigit()
                .foregroundStyle(tag == "weak" ? Color.altInk : Color.muted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(Format.avg(allowed)) allowed"
            + (rank.map { ", \(Format.ordinal($0)) of \(vm.teamCount)" } ?? "")
            + ", \(Format.signedAvg(vsAvg)) versus league average" + (tag.map { ", \($0)" } ?? ""))
    }
}
