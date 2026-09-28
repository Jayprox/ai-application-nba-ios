//
//  PropsAndRankingsTests.swift
//  Chalk That NBATests
//
//  Ports of the web's lib/props.test.js and lib/rankings.test.js, the
//  decodedKey gotcha (z["ts_pct"] arrives as "tsPct"), rankings payloads,
//  and the guide's structure (the web's Guide.test.jsx idea).
//
import XCTest
@testable import Chalk_That_NBA

final class PropsAndRankingsTests: XCTestCase {

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder.chalkThatNBA.decode(T.self, from: Data(json.utf8))
    }

    private func hit(_ over: Int, _ games: Int) throws -> HitRate {
        try decode(HitRate.self, #"{ "over": \#(over), "under": \#(games - over), "push": 0, "games": \#(games), "avg": null }"#)
    }

    // MARK: - props.test.js

    func testPricesHitsMovement() throws {
        XCTAssertEqual([Markets.price(105), Markets.price(-110), Markets.price(nil)], ["+105", "-110", ""])
        XCTAssertEqual(PropText.hits(try hit(7, 10)), "7/10")
        XCTAssertEqual(PropText.hits(try hit(0, 0)), "—")
        XCTAssertEqual(PropText.ratePct(try hit(7, 10)), "70%")
        XCTAssertEqual(PropText.ratePct(nil), "—")
        let down = try XCTUnwrap(PropText.movement(open: 24.5, line: 23.5))
        XCTAssertFalse(down.up)
        XCTAssertEqual(down.by, 1)
        XCTAssertNil(PropText.movement(open: 24.5, line: 24.5))
        XCTAssertNil(PropText.movement(open: nil, line: 24.5))
    }

    private func row(_ name: String, _ over: Int, _ games: Int, line: Double = 20.5, game: String = "g1") throws -> PropBoardRow {
        let h = #"{ "over": \#(over), "under": \#(games - over), "push": 0, "games": \#(games), "avg": null }"#
        return try decode(PropBoardRow.self, """
        { "game_id": "\(game)", "player_id": "\(name)", "name": "\(name)", "line": \(line),
          "last10": \(h), "season": \(h) }
        """)
    }

    func testBoardSort() throws {
        let rows = [try row("A", 1, 1), try row("B", 9, 10), try row("C", 10, 10), try row("D", 0, 0), try row("E", 9, 10, line: 25.5, game: "g0")]
        XCTAssertEqual(PropText.sortRows(rows, by: .l10).map(\.name), ["C", "A", "E", "B", "D"])
        XCTAssertEqual(PropText.sortRows(rows, by: .line).first?.name, "E")
        XCTAssertEqual(PropText.sortRows(rows, by: .game, gameOrder: ["g0": 0, "g1": 1]).map(\.name), ["E", "A", "B", "C", "D"])
    }

    func testSeasonFallsBackToLastSeason() throws {
        let r = try decode(PropBoardRow.self, """
        { "game_id": "g", "player_id": "p", "name": "Rookie", "line": 12.5,
          "last10": { "over": 0, "under": 0, "push": 0, "games": 0, "avg": null },
          "season": { "over": 0, "under": 0, "push": 0, "games": 0, "avg": null },
          "last_season": { "over": 30, "under": 40, "push": 0, "games": 70, "avg": 11.8 } }
        """)
        let s = PropText.seasonOf(r)
        XCTAssertTrue(s.isLastSeason)
        XCTAssertEqual(PropText.hits(s.rate), "30/70")
        XCTAssertEqual(Format.avg(s.rate?.avg), "11.8")
    }

    // MARK: - rankings.test.js

    func testOrdinalsIncludingTheTeens() {
        XCTAssertEqual([1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 30, 101, 111].map { Format.ordinal($0) },
                       ["1st", "2nd", "3rd", "4th", "11th", "12th", "13th", "21st", "22nd", "23rd", "30th", "101st", "111th"])
        XCTAssertEqual(Format.ordinal(nil), "")
    }

    func testMatchupText() throws {
        let m = try decode(MatchupNote.self, #"{ "opponent": "BOS", "rank": 27, "of": 30, "position_label": "Guards" }"#)
        XCTAssertEqual(PropText.matchupText(m), "BOS: 27th of 30 vs guards")
        XCTAssertNil(PropText.matchupText(nil))
    }

    // MARK: - Decoded dictionary keys

    func testDecodedKey() {
        XCTAssertEqual(Format.decodedKey("ts_pct"), "tsPct")
        XCTAssertEqual(Format.decodedKey("off_rtg"), "offRtg")
        XCTAssertEqual(Format.decodedKey("pts"), "pts")
        XCTAssertEqual(Format.decodedKey("fg3m"), "fg3m")
    }

    func testPlayerRankingsReadZScoresBySnakeCaseStatName() throws {
        let e = try decode(APIEnvelope<[PlayerRankingRow], PlayerRankingsMeta>.self, """
        { "data": [ { "rank": 1, "player_id": "p", "name": "Nikola Jokić", "team": "DEN", "listed_position": "C", "gp": 65,
            "pts": 27.7, "reb": 12.9, "ast": 10.7, "stl": 1.4, "blk": 0.8, "fg3m": 1.8, "tov": 3.3, "minutes": 36.2, "ts_pct": 0.66,
            "z": { "pts": 2.1, "reb": 1.5, "ast": 2.8, "stl": 0.9, "blk": 0.1, "fg3m": 0.6, "ts_pct": 1.7, "tov": -1.2 }, "score": 1.63 } ],
          "meta": { "position_label": "Centers", "stats": ["pts", "reb", "ast", "stl", "blk", "fg3m", "ts_pct", "tov"], "count": 31, "notes": ["n"] } }
        """)
        let r = try XCTUnwrap(e.data.first)
        XCTAssertEqual(Format.signedAvg(r.zScore("ts_pct")), "+1.7")
        XCTAssertEqual(Format.pct(r.value("ts_pct")), ".660")
        XCTAssertEqual(Format.signedAvg(r.score), "+1.6")
        XCTAssertEqual(e.meta?.stats.count, 8)
    }

    func testTeamRankingsReadRanksBySnakeCaseName() throws {
        let r = try decode(TeamRankingRow.self, """
        { "team_id": 24, "abbr": "DAL", "name": "Dallas Mavericks", "gp": 82, "w": 50, "l": 32, "pts": 117.9,
          "opp_pts": 115.4, "off_rtg": 116.2, "def_rtg": 113.8, "net_rtg": 2.4, "pace": 101.4,
          "ranks": { "off_rtg": 5, "def_rtg": 12, "net_rtg": 8, "pace": 9 } }
        """)
        XCTAssertEqual(r.rank("off_rtg"), 5)
        XCTAssertEqual(r.rank("net_rtg"), 8)
        XCTAssertEqual(r.rank("pace"), 9)
    }

    func testPropsBoardDecodes() throws {
        let r = try decode(PropBoardResponse.self, """
        { "data": [ { "game_id": "g", "player_id": "p", "name": "Jayson Tatum", "team": "BOS", "opponent": "NYK", "venue": "away",
            "line": 26.5, "over_price": -115, "under_price": -105, "snapshot": "close", "fetched_at": "2026-10-21T22:00:00.000Z", "open_line": 25.5,
            "actual": null, "result": null,
            "last10": { "over": 6, "under": 4, "push": 0, "games": 10, "avg": 27.9 },
            "season": { "over": 0, "under": 0, "push": 0, "games": 0, "avg": null },
            "last_season": { "over": 40, "under": 30, "push": 2, "games": 72, "avg": 26.8 },
            "matchup": { "position": "F", "position_label": "Forwards", "rank": 27, "of": 30, "allowed": 51.2,
                         "vs_avg": 3.1, "label": "weak", "games": 12, "opponent": "NYK" } } ],
          "games": [ { "id": "g", "tipoff_utc": "2026-10-21T23:30:00.000Z", "status": "scheduled", "home": "NYK", "away": "BOS",
                       "home_score": null, "away_score": null, "season_type": "regular", "lines": 14, "open_pulled": true, "close_pulled": false } ],
          "meta": { "date": "2026-10-21", "market": "pts", "market_label": "Points", "markets": [["pts", "Points"]], "season": "2026-27",
                    "prev_date": null, "next_date": "2026-10-22", "book": "DraftKings", "count": 1, "notes": ["a", "b", "c"] } }
        """)
        let row = try XCTUnwrap(r.data.first)
        XCTAssertEqual(PropText.matchup(row), "BOS @ NYK")
        XCTAssertEqual(PropText.matchupText(row.matchup), "NYK: 27th of 30 vs forwards")
        XCTAssertEqual(PropText.movement(open: row.openLine, line: row.line)?.up, true)
        XCTAssertEqual(r.meta.notes.count, 3)
    }

    // MARK: - Guide

    func testGuideHasTheWebSectionsInOrder() {
        XCTAssertEqual(GuideContent.sections.map(\.id),
                       ["principles", "scoreboard", "standings", "teams", "players", "splits",
                        "leaders", "rankings", "props", "ask", "glossary", "data"])
        for section in GuideContent.sections {
            XCTAssertFalse(section.blocks.isEmpty, section.id)
        }
    }

    func testGuideMarkdownParses() throws {
        for section in GuideContent.sections {
            for block in section.blocks {
                switch block {
                case .paragraph(let text):
                    XCTAssertNoThrow(try AttributedString(markdown: text), section.id)
                case .terms(let items):
                    for item in items { XCTAssertNoThrow(try AttributedString(markdown: item.definition), item.term) }
                }
            }
        }
    }
}
