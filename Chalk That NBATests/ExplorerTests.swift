//
//  ExplorerTests.swift
//  Chalk That NBATests
//
//  The stat explorer's pure parts, pinned to the web's own tests:
//  - ExplorerFilters.query  = StatExplorer.test.js (buildQuery)
//  - NoGamesMessage         = NoGames.test.jsx
//  - PropCheckView text     = PropCheck.test.jsx
//  - GameLogText            = StatExplorer.jsx tags() / opp()
//  Bodies are compared as encoded JSON, i.e. exactly what goes over the wire.
//
import XCTest
@testable import Chalk_That_NBA

final class ExplorerTests: XCTestCase {

    private func json(_ query: StatQuery) throws -> [String: Any] {
        let data = try JSONEncoder.chalkThatNBA.encode(query)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func splits(_ query: StatQuery) throws -> NSDictionary {
        try XCTUnwrap(try json(query)["splits"] as? NSDictionary)
    }

    private var base: ExplorerFilters {
        var f = ExplorerFilters()
        f.season = "2025-26"
        return f
    }

    // MARK: - buildQuery (StatExplorer.test.js)

    func testPlayerRestUsesHisOwnGamesByDefault() throws {
        var f = base; f.rest = "3+"; f.b2b = "2"
        XCTAssertEqual(try splits(f.query(entity: .player, id: "p1")), ["player_rest": "3+", "player_b2b": 2] as NSDictionary)
    }

    func testTeamScheduleSwitchesAPlayerQueryToTeamRest() throws {
        var f = base; f.restBy = "team"; f.rest = "1"
        XCTAssertEqual(try splits(f.query(entity: .player, id: "p1")), ["rest": 1] as NSDictionary)
    }

    func testTeamQueriesAlwaysUseTeamRest() throws {
        var f = base; f.rest = "0"; f.b2b = "1"
        XCTAssertEqual(try splits(f.query(entity: .team, id: "7")), ["rest": 0, "b2b": 1] as NSDictionary)
        XCTAssertEqual(try json(f.query(entity: .team, id: "7"))["id"] as? Int, 7, "team ids go out as numbers")
    }

    func testOtherSplitsMapToAPINamesAndTypes() throws {
        var f = base; f.venue = "home"; f.tv = "nba_tv"; f.alt = "no"
        XCTAssertEqual(try splits(f.query(entity: .player, id: "p1")),
                       ["venue": "home", "national_tv": "nba_tv", "altitude": false] as NSDictionary)
    }

    func testCareerDropsTheSeasonOtherScopesKeepIt() throws {
        var career = base; career.scope = "career"
        XCTAssertNil(try json(career.query(entity: .player, id: "p1"))["season"])
        var last10 = base; last10.scope = "last10"
        let body = try json(last10.query(entity: .player, id: "p1"))
        XCTAssertEqual(body["season"] as? String, "2025-26")
        XCTAssertEqual(body["scope"] as? String, "last10")
        XCTAssertEqual(body["season_type"] as? String, "regular")
    }

    func testPropLinesRideAlongOnAveragedPlayerScopesOnly() throws {
        let lines = ["pts": 25.5, "pra": 38.5]
        var last10 = base; last10.scope = "last10"
        XCTAssertEqual(try json(last10.query(entity: .player, id: "p1", lines: lines))["lines"] as? NSDictionary, lines as NSDictionary)
        var log = base; log.scope = "game_log"
        XCTAssertNil(try json(log.query(entity: .player, id: "p1", lines: lines))["lines"])
        XCTAssertNil(try json(base.query(entity: .team, id: "7", lines: lines))["lines"])
        XCTAssertNil(try json(base.query(entity: .player, id: "p1", lines: [:]))["lines"])
        XCTAssertNil(try json(base.query(entity: .player, id: "p1", lines: nil))["lines"])
    }

    func testNoSplitsSendsAnEmptyObject() throws {
        XCTAssertEqual(try splits(base.query(entity: .player, id: "p1")), [:] as NSDictionary)
    }

    func testSettingASplitToAllClearsIt() {
        var f = base
        f[.venue] = "away"
        XCTAssertEqual(f.splitCount, 1)
        f[.venue] = "all"
        XCTAssertEqual(f.splitCount, 0)
    }

    // MARK: - NoGames (NoGames.test.jsx)

    func testSeasonTypeHeDidntPlay() {
        var f = base; f.seasonType = "playoffs"
        let m = NoGamesMessage.make(name: "Stephen Curry", filters: f, played: ["play_in", "regular"])
        XCTAssertTrue(m.text.hasPrefix("Stephen Curry didn't play in the 2025-26 playoffs."), m.text)
        XCTAssertTrue(m.actions.contains(.showType(value: "play_in", label: "Show Play-In")))
    }

    func testSplitsAreTheReasonAndTeamPossessiveReadsRight() {
        var f = base; f.venue = "away"; f.tv = "major"
        let m = NoGamesMessage.make(name: "the Golden State Warriors", filters: f, played: ["regular"])
        XCTAssertEqual(m.text, "None of the Golden State Warriors' 2025-26 regular season games match these splits.")
        XCTAssertEqual(m.actions, [.clearSplits])
    }

    func testCupBeforeItExisted() {
        var f = base; f.season = "2019-20"; f.seasonType = "cup"
        XCTAssertEqual(NoGamesMessage.make(name: "LeBron James", filters: f, played: ["regular"]).text,
                       "The NBA Cup started in 2023-24, so there are no Cup games in 2019-20.")
    }

    func testPlainNoGames() {
        XCTAssertEqual(NoGamesMessage.make(name: "a rookie", filters: base, played: nil).text,
                       "No games for a rookie in the 2025-26 regular season.")
    }

    // MARK: - PropCheck (PropCheck.test.jsx)

    private func playerProps(_ json: String) throws -> PlayerProps {
        try JSONDecoder.chalkThatNBA.decode(PlayerProps.self, from: Data(json.utf8))
    }

    func testPropCheckText() throws {
        let props = try playerProps("""
        { "upcoming": { "game": { "id": "g", "date": "2026-10-21", "tipoff_utc": "2026-10-21T23:30:00Z", "status": "scheduled", "home": "DEN", "away": "OKC" },
            "lines": [ { "market": "pts", "label": "Points", "line": 27.5, "over_price": -115, "under_price": -105, "snapshot": "close", "open_line": 28.5 },
                       { "market": "pra", "label": "Pts + Reb + Ast", "line": 50.5, "over_price": -110, "under_price": -110, "snapshot": "close", "open_line": null } ] },
          "record": { "pts": { "label": "Points", "over": 5, "under": 3, "push": 1, "games": 9 } } }
        """)
        let view = PropCheckView(props: props, hits: ["pts": PropHits(line: 27.5, over: 7, under: 3, push: 0, games: 10)])
        XCTAssertTrue(view.title.contains("OKC @ DEN"), view.title)
        XCTAssertTrue(view.bookLine.contains("closing lines"))
        XCTAssertTrue(view.footnote.contains("PTS 5–3–1"), view.footnote)
        XCTAssertTrue(view.footnote.contains("(over–under–push)"))
    }

    // MARK: - Game log text (tags / opp)

    private func row(_ extra: String) throws -> GameLogRow {
        let json = """
        { "game_id": "g", "date": "2004-04-14", "season": "2003-04", "season_type": "regular", "venue": "away",
          "opponent": "NYK", "won": true, "rest_days": 1, "b2b_night": null, "national_tv_tier": "local",
          "altitude": false, "player_rest_days": 0, "player_b2b_night": 2, "started": null,
          "pts": 17, "reb": 1, "ast": 5, "stl": 3, "blk": 0, "tov": 5, "fg3m": 0, "fgm": 8, "fga": 17,
          "fg3a": 3, "ftm": 1, "fta": 1, "oreb": 0, "dreb": 1, "pf": 1, "plus_minus": -6, "minutes": 35\(extra) }
        """
        return try JSONDecoder.chalkThatNBA.decode(GameLogRow.self, from: Data(json.utf8))
    }

    func testGameLogTagsFollowRestMeasuredBy() throws {
        let r = try row(#", "props": { "pts": { "line": 25.5, "result": "under" } }"#)
        XCTAssertEqual(GameLogText.opponent(r), "@ NYK")
        XCTAssertEqual(GameLogText.tags(r, restBy: "player"), "B2B night 2 · 0d rest")
        XCTAssertEqual(GameLogText.tags(r, restBy: "team"), "1d rest")
        XCTAssertEqual(GameLogText.pointsLine(r), "25.5 U")
        XCTAssertEqual(r.plusMinus, -6)
    }

    func testGameLogWithoutLines() throws {
        XCTAssertEqual(GameLogText.pointsLine(try row(#", "props": null"#)), "")
        XCTAssertEqual(GameLogText.pointsLine(try row(#", "props": { "reb": { "line": 7.5, "result": "over" } }"#)), "lines")
    }

    // MARK: - Query responses decode

    func testSeasonAverageResponse() throws {
        let json = """
        { "query": {}, "subject": { "type": "player", "id": "p", "name": "LeBron James" },
          "data": { "gp": 79, "pts": 20.9, "reb": 5.5, "ast": 5.9, "stl": 1.6, "blk": 0.7, "tov": 3.5, "fg3m": 0.8,
            "fgm": 7.9, "fga": 18.9, "fg3a": 2.7, "ftm": 4.4, "fta": 5.8, "oreb": 1.3, "dreb": 4.2, "pf": 1.9,
            "plus_minus": -1.5, "minutes": 39.5, "fg_pct": 0.417, "fg3_pct": 0.29, "ft_pct": 0.754,
            "ts_pct": 0.488, "efg_pct": 0.438, "ft_rate": 0.307, "pts_per36": 19.1, "reb_per36": 5, "ast_per36": 5.4, "usg_pct": 0.283 },
          "props": { "pts": { "line": 20.5, "over": 40, "under": 39, "push": 0, "games": 79 } },
          "meta": { "sample_size": 79, "record": "33-46", "filters_applied": { "season": "2003-04" }, "notes": [],
            "freshness": { "synced_at": "2026-09-27T04:05:06.873Z", "source": "nba_stats" }, "cached": false } }
        """
        let r = try JSONDecoder.chalkThatNBA.decode(QueryResponse<Averages>.self, from: Data(json.utf8))
        let d = try XCTUnwrap(r.data)
        XCTAssertEqual(Format.avg(d.pts), "20.9")
        XCTAssertEqual(Format.pct(d.tsPct), ".488")
        XCTAssertEqual(Format.usgPct(d.usgPct), "28.3%")
        XCTAssertEqual(Format.avg(d.rebPer36), "5.0")
        XCTAssertEqual(Format.signedAvg(d.plusMinus), "-1.5")
        XCTAssertEqual(r.meta.sampleSize, 79)
        XCTAssertEqual(r.meta.record, "33-46")
        XCTAssertEqual(r.props?["pts"]?.over, 40)
    }

    func testEmptySampleDecodesNullData() throws {
        let json = #"{ "data": null, "meta": { "sample_size": 0, "record": "0-0", "notes": ["Neutral-site games are excluded."], "freshness": { "synced_at": null } } }"#
        let r = try JSONDecoder.chalkThatNBA.decode(QueryResponse<Averages>.self, from: Data(json.utf8))
        XCTAssertNil(r.data)
        XCTAssertEqual(r.meta.sampleSize, 0)
        XCTAssertEqual(r.meta.notes.count, 1)
    }

    func testCareerResponse() throws {
        let json = """
        { "data": { "totals": { "gp": 2, "pts": 25.1 },
                    "by_season": [ { "season": "2003-04", "team": "CLE", "gp": 1, "pts": 20.9 },
                                   { "season": "2010-11", "team": "MIA", "gp": 1, "pts": 26.7 } ] },
          "meta": { "sample_size": 2, "record": "1-1", "notes": [] } }
        """
        let r = try JSONDecoder.chalkThatNBA.decode(QueryResponse<CareerData>.self, from: Data(json.utf8))
        XCTAssertEqual(r.data?.bySeason.map(\.team), ["CLE", "MIA"])
        XCTAssertEqual(r.data?.totals.gp, 2)
    }

    func testPlayerDetailDecodes() throws {
        let json = """
        { "data": { "id": "p", "full_name": "LeBron James", "first_name": "LeBron", "last_name": "James", "birth_date": "1984-12-30",
          "listed_position": "F", "height_in": 81, "weight_lb": 250, "current_team_id": 14, "is_active": true,
          "first_season_start": 2003, "team": "LAL", "team_name": "Los Angeles Lakers",
          "seasons": ["2025-26", "2003-04"], "season_types": { "2025-26": ["regular", "playoffs", "cup"], "2003-04": ["regular"] },
          "current_injury": null } }
        """
        let p = try JSONDecoder.chalkThatNBA.decode(APIEnvelope<PlayerDetail, EmptyMeta>.self, from: Data(json.utf8)).data
        XCTAssertEqual(p.subtitle, "F · Los Angeles Lakers · 6'9\" · 250 lb")
        XCTAssertEqual(p.seasonTypes["2025-26"], ["regular", "playoffs", "cup"])
        XCTAssertNil(p.currentInjury)
    }
}
