//
//  AskDisplayView.swift
//  Chalk That NBA
//
//  Draws an Ask answer's `view` (the web's `View` in pages/Ask.jsx), same
//  columns and tiles per type. Team "Net rtg (est.)" uses the one derived
//  number, Format.netRating, exactly as the web does here too.
//
import SwiftUI

struct AskDisplayView<Examples: View>: View {
    let display: AskDisplay
    let season: String?
    let examples: Examples

    var body: some View {
        switch display {
        case .stats(let scope, let subjectType, let content, let meta):
            stats(scope: scope, isPlayer: subjectType == "player", content: content, meta: meta)
        case .leaders(let stat, let rows):
            leaders(stat: stat, rows: rows)
        case .playerRankings(let rows):
            playerRankings(rows)
        case .teamRankings(let stat, let rows):
            teamRankings(stat: stat, rows: rows)
        case .matchups(let stat, let rows):
            matchups(stat: stat, rows: rows)
        case .props(let upcoming, let market, let hits, let record):
            props(upcoming: upcoming, market: market, hits: hits, record: record)
        case .standings(let rows):
            standings(rows)
        case .game(let games):
            gameList(games)
        case .series(let rows):
            seriesList(rows)
        case .unsupported:
            examples
        case .clarify, .other:
            EmptyView()
        }
    }

    // MARK: - Tiles

    private func tiles(_ items: [(String, String)]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Eyebrow(text: item.0, color: item.0.contains("est.") ? .caution : .muted)
                    Text(item.1)
                        .font(.brandDisplay(28, weight: .bold, relativeTo: .title))
                        .monospacedDigit()
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: - stats

    @ViewBuilder
    private func stats(scope: String, isPlayer: Bool, content: ExplorerResult.Content, meta: QueryMeta) -> some View {
        if meta.sampleSize > 0 {
            switch content {
            case .gameLog(let rows):
                let columns: [DataTable.Column] = [.init(title: "Opp", width: 64, leading: true), .init(title: "Result", width: 48, leading: true)]
                    + (isPlayer ? [.init(title: "Pts", width: 36), .init(title: "Reb", width: 36), .init(title: "Ast", width: 36)]
                                : [.init(title: "Score", width: 64)])
                DataTable(pinnedTitle: "Date", pinnedWidth: 76, columns: columns, rows: rows.prefix(10).map { g in
                    let opp = "\(g.venue == "away" ? "@" : "vs") \(g.opponent)"
                    let result = g.won == true ? "W" : "L"
                    let rest = isPlayer ? [g.pts.map(String.init) ?? "", g.reb.map(String.init) ?? "", g.ast.map(String.init) ?? ""]
                                        : ["\(g.pts.map(String.init) ?? "")-\(g.oppPts.map(String.init) ?? "")"]
                    return DataTable.Row(id: g.gameId, pinned: Format.tinyDate(g.date), cells: [opp, result] + rest,
                                         route: .game(id: g.gameId),
                                         spoken: ([Format.shortDate(g.date), opp, result] + rest).joined(separator: ", "))
                })
            case .career(let career):
                if let d = career?.totals { tiles(statTiles(d, isPlayer: isPlayer, meta: meta)) }
            case .averages(let averages):
                if let d = averages { tiles(statTiles(d, isPlayer: isPlayer, meta: meta)) }
            }
        }
    }

    private func statTiles(_ d: Averages, isPlayer: Bool, meta: QueryMeta) -> [(String, String)] {
        isPlayer
            ? [("Points", Format.avg(d.pts)), ("Rebounds", Format.avg(d.reb)), ("Assists", Format.avg(d.ast)), ("3PM", Format.avg(d.fg3m)),
               ("FG%", Format.pct(d.fgPct)), ("TS%", Format.pct(d.tsPct)), ("Minutes", Format.avg(d.minutes)), ("Games", String(meta.sampleSize))]
            : [("Points", Format.avg(d.pts)), ("Opp points", Format.avg(d.oppPts)),
               ("Net rtg (est.)", d.offRtg == nil ? "—" : Format.netRating(off: d.offRtg, def: d.defRtg)),
               ("Rebounds", Format.avg(d.reb)), ("Assists", Format.avg(d.ast)), ("Record", meta.record ?? "—")]
    }

    // MARK: - tables

    private func leaders(stat: String?, rows: [LeaderRow]) -> some View {
        let usage = stat == "usg_pct"
        return DataTable(pinnedTitle: "Player", pinnedWidth: 180,
                         columns: [.init(title: "Team", width: 44, leading: true), .init(title: "GP", width: 32),
                                   .init(title: usage ? "Usage (est.)" : "Per game", width: 84, bold: true)],
                         rows: rows.map { r in
            let value = usage ? Format.usgPct(r.value) : Format.avg(r.value)
            return DataTable.Row(id: r.playerId, pinned: r.fullName, cells: [r.team ?? "", String(r.gp), value],
                                 route: .player(id: r.playerId, season: season),
                                 spoken: "\(r.rank), \(r.fullName), \(r.team ?? ""), \(r.gp) games, \(value)",
                                 prefix: String(r.rank))
        })
    }

    private func playerRankings(_ rows: [PlayerRankingRow]) -> some View {
        DataTable(pinnedTitle: "Player", pinnedWidth: 180,
                  columns: [.init(title: "Team", width: 44, leading: true), .init(title: "Score", width: 48, bold: true),
                            .init(title: "Pts", width: 40), .init(title: "Reb", width: 40), .init(title: "Ast", width: 40)],
                  rows: rows.map { r in
            DataTable.Row(id: r.playerId, pinned: r.name,
                          cells: [r.team ?? "", Format.signedAvg(r.score), Format.avg(r.pts), Format.avg(r.reb), Format.avg(r.ast)],
                          route: .player(id: r.playerId, season: season),
                          spoken: "\(r.rank), \(r.name), score \(Format.signedAvg(r.score))",
                          prefix: String(r.rank))
        })
    }

    private func teamRankings(stat: String?, rows: [TeamRankingRow]) -> some View {
        DataTable(pinnedTitle: "Team", pinnedWidth: 196,
                  columns: [.init(title: "W-L", width: 48), .init(title: "Off", width: 48), .init(title: "Def", width: 48),
                            .init(title: "Net", width: 48, bold: true), .init(title: "Pace", width: 48)],
                  rows: rows.map { r in
            DataTable.Row(id: String(r.teamId), pinned: r.name,
                          cells: ["\(r.w)-\(r.l)", Format.avg(r.offRtg), Format.avg(r.defRtg), Format.signedAvg(r.netRtg), Format.avg(r.pace)],
                          route: .team(id: r.teamId, season: season),
                          spoken: "\(r.name), net \(Format.signedAvg(r.netRtg))",
                          prefix: stat.flatMap { r.rank($0) }.map(String.init) ?? "")
        })
    }

    private func matchups(stat: String?, rows: [MatchupRow]) -> some View {
        let s = stat ?? "pts"
        return DataTable(pinnedTitle: "Defense", pinnedWidth: 110,
                         columns: [.init(title: "GP", width: 32), .init(title: "\(Markets.short(s)) allowed", width: 96, bold: true),
                                   .init(title: "Vs avg", width: 56)],
                         rows: rows.map { r in
            DataTable.Row(id: String(r.teamId), pinned: r.abbr,
                          cells: [String(r.games), Format.avg(r.allowed[s] ?? nil), Format.signedAvg(r.vsAvg[s] ?? nil)],
                          route: .team(id: r.teamId, season: season),
                          spoken: "\(r.abbr), \(Format.avg(r.allowed[s] ?? nil)) allowed, \(Format.signedAvg(r.vsAvg[s] ?? nil)) versus average",
                          prefix: (r.rank[s] ?? nil).map(String.init) ?? "")
        })
    }

    @ViewBuilder
    private func props(upcoming: PlayerProps.Upcoming?, market: String?, hits: PropHits?, record: PlayerProps.RecordLine?) -> some View {
        let m = market ?? "pts"
        let dk = upcoming?.lines.first { $0.market == m }
        let items = Self.propTiles(upcoming: upcoming, market: m, dk: dk, hits: hits, record: record)
        if !items.isEmpty { tiles(items) }
    }

    static func propTiles(upcoming: PlayerProps.Upcoming?, market m: String, dk: PlayerProps.Line?,
                          hits: PropHits?, record: PlayerProps.RecordLine?) -> [(String, String)] {
        var items: [(String, String)] = []
        if let dk, let game = upcoming?.game {
            items.append(("DraftKings \(Markets.short(m)) · \(game.away) @ \(game.home)",
                          "\(Format.jsNumber(dk.line))  o\(Markets.price(dk.overPrice)) / u\(Markets.price(dk.underPrice))"))
        }
        if let hits, hits.games > 0 {
            items.append(("Over \(Format.jsNumber(hits.line))", "\(hits.over) of \(hits.games)"))
        }
        if let record, record.games > 0 {
            items.append(("Vs past DraftKings lines", "\(record.over)–\(record.under)\(record.push > 0 ? "–\(record.push)" : "")"))
        }
        return items
    }

    private func standings(_ rows: [AskStandingRow]) -> some View {
        DataTable(pinnedTitle: "Team", pinnedWidth: 196,
                  columns: [.init(title: "Conf", width: 44, leading: true), .init(title: "W", width: 30, bold: true),
                            .init(title: "L", width: 30, bold: true), .init(title: "GB", width: 36)],
                  rows: rows.map { r in
            DataTable.Row(id: String(r.teamId), pinned: r.name,
                          cells: [r.conference ?? "", String(r.wins), String(r.losses), r.gb == 0 ? "—" : (r.gb.map(Format.jsNumber) ?? "")],
                          route: .team(id: r.teamId, season: season),
                          spoken: "\(r.rank), \(r.name), \(r.wins) and \(r.losses)",
                          prefix: String(r.rank))
        })
    }

    @ViewBuilder
    private func gameList(_ games: [AskGameRow]) -> some View {
        if !games.isEmpty {
            DataTable(pinnedTitle: "Date", pinnedWidth: 76,
                      columns: [.init(title: "Game", width: 110, leading: true), .init(title: "Result", width: 84)],
                      rows: games.map { g in
                let game = "\(g.team ?? "") \(g.venue == "away" ? "@" : "vs") \(g.opponent)"
                let result = "\(g.won == true ? "W" : "L") \(g.pts.map(String.init) ?? "")-\(g.oppPts.map(String.init) ?? "")"
                return DataTable.Row(id: g.gameId, pinned: Format.tinyDate(g.date), cells: [game, result],
                                     route: .game(id: g.gameId), spoken: "\(Format.shortDate(g.date)), \(game), \(result)")
            })
        }
    }

    @ViewBuilder
    private func seriesList(_ rows: [Series]) -> some View {
        if !rows.isEmpty {
            DataTable(pinnedTitle: "Round", pinnedWidth: 150,
                      columns: [.init(title: "Series", width: 90, leading: true), .init(title: "Result", width: 70)],
                      rows: rows.map { x in
                let series = "\(x.higherAbbr ?? "TBD") vs \(x.lowerAbbr ?? "TBD")"
                return DataTable.Row(id: String(x.id), pinned: AskText.seriesRound(x), cells: [series, AskText.seriesResult(x)],
                                     spoken: "\(AskText.seriesRound(x)), \(series), \(AskText.seriesResult(x))")
            })
        }
    }
}
