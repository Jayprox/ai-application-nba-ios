//
//  LeagueTests.swift
//  Chalk That NBATests
//
//  Leaders and standings: the bracket order (the web's Standings.test.js,
//  ported case for case), win % and games-back formatting, and the
//  leaderboard / standings / bracket payloads.
//
import XCTest
@testable import Chalk_That_NBA

final class LeagueTests: XCTestCase {

    private func series(_ id: Int, _ round: String, _ conference: String?, _ higher: Int, _ lower: Int, slot: String? = nil) throws -> Series {
        let slotValue = slot ?? "\(conference?.prefix(1) ?? "")-\(higher)v\(lower)"
        let conf = conference.map { "\"\($0)\"" } ?? "null"
        let json = """
        { "id": \(id), "round": "\(round)", "conference": \(conf), "bracket_slot": "\(slotValue)",
          "higher_seed": \(higher), "lower_seed": \(lower) }
        """
        return try JSONDecoder.chalkThatNBA.decode(Series.self, from: Data(json.utf8))
    }

    func testBracketOrder() throws {
        let b = Bracket([
            try series(1, "first_round", "East", 2, 7), try series(2, "first_round", "East", 1, 8),
            try series(3, "first_round", "East", 3, 6), try series(4, "first_round", "East", 4, 5),
            try series(5, "conf_semis", "East", 2, 3), try series(6, "conf_semis", "East", 1, 4),
            try series(7, "finals", nil, 1, 1, slot: "FINALS"),
            try series(8, "play_in", "East", 9, 10), try series(9, "play_in", "East", 7, 8),
            try series(10, "play_in", "East", 8, 9, slot: "E-8seed")
        ])
        XCTAssertEqual(b.east.first.map { "\($0.higherSeed!)v\($0.lowerSeed!)" }, ["1v8", "4v5", "3v6", "2v7"])
        XCTAssertEqual(b.east.semis.map { $0.higherSeed! }, [1, 2])
        XCTAssertEqual(b.east.playIn.map { $0.bracketSlot! }, ["E-7v8", "E-9v10", "E-8seed"])
        XCTAssertEqual(b.finals?.id, 7)
        XCTAssertTrue(b.west.first.isEmpty)
    }

    func testStableSortKeepsEqualElementsInOrder() {
        let items = [(1, "a"), (0, "b"), (1, "c"), (0, "d")]
        XCTAssertEqual(items.stableSorted { $0.0 < $1.0 }.map(\.1), ["b", "d", "a", "c"])
    }

    func testStandingsNumbers() {
        XCTAssertEqual(Format.winPct(0.683), ".683")
        XCTAssertEqual(Format.winPct(1), "1.000")
        XCTAssertEqual(Format.winPct(0), ".000")
        XCTAssertEqual(Format.winPct(nil), "—")
        XCTAssertEqual(Format.jsNumber(4), "4")
        XCTAssertEqual(Format.jsNumber(4.5), "4.5")
    }

    func testLeaderboardDecodes() throws {
        let json = """
        { "query": {}, "subject": { "type": "league" },
          "data": [ { "rank": 1, "player_id": "p", "full_name": "Luka Dončić", "gp": 64, "value": 33.5, "team": "LAL" } ],
          "meta": { "sample_size": 142, "record": null, "notes": ["Qualifier: played in at least 70% of team games (58 of 82) — Chalk That's rule, not the NBA's official one."],
            "qualifier": { "min_games": 58, "team_games": 82, "qualified_players": 142 },
            "freshness": { "synced_at": null }, "cached": false } }
        """
        let r = try JSONDecoder.chalkThatNBA.decode(QueryResponse<[LeaderRow]>.self, from: Data(json.utf8))
        XCTAssertEqual(Format.avg(r.data?.first?.value), "33.5")
        XCTAssertEqual(r.meta.qualifier?.minGames, 58)
        XCTAssertEqual(r.meta.qualifier?.teamGames, 82)
        XCTAssertNil(r.meta.qualifier?.minMinutes)
    }

    func testLeaderboardBodyHasNoId() throws {
        let q = StatQuery(entity: .player, id: "", scope: "leaderboard", season: "2025-26", seasonType: "regular",
                          splits: QuerySplits(), stat: "usg_pct", limit: 25)
        let body = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder.chalkThatNBA.encode(q)) as? [String: Any])
        XCTAssertNil(body["id"])
        XCTAssertEqual(body["stat"] as? String, "usg_pct")
        XCTAssertEqual(body["limit"] as? Int, 25)
    }

    func testStandingsDecode() throws {
        let json = """
        { "data": { "East": [ { "team_id": 4, "abbreviation": "BOS", "name": "Boston Celtics", "conference": "East",
            "division": "Atlantic", "wins": 56, "losses": 26, "pct": 0.683, "home": "31-10", "road": "25-16",
            "conf": "36-16", "last10": "7-3", "streak": "W 2", "rank": 2, "rank_source": "nba_stats", "clinch": "x", "gb": 4 } ],
            "West": [] },
          "meta": { "season": "2025-26", "games": 1230, "format": { "playoff_seeds": 6, "play_in_seeds": [7, 8, 9, 10] },
            "notes": ["Home/road leave out neutral-site games, as NBA.com does."] } }
        """
        let e = try JSONDecoder.chalkThatNBA.decode(APIEnvelope<StandingsData, StandingsMeta>.self, from: Data(json.utf8))
        XCTAssertEqual(e.data.east.first?.clinch, "x")
        XCTAssertEqual(e.data.east.first?.gb, 4)
        XCTAssertEqual(e.meta?.format?.playInSeeds, [7, 8, 9, 10])
    }

    func testStandingsWithNoSeason() throws {
        let json = #"{ "data": { "East": [], "West": [] }, "meta": { "season": null } }"#
        let e = try JSONDecoder.chalkThatNBA.decode(APIEnvelope<StandingsData, StandingsMeta>.self, from: Data(json.utf8))
        XCTAssertTrue(e.data.east.isEmpty)
        XCTAssertNil(e.meta?.format)
    }
}
