//
//  AskTests.swift
//  Chalk That NBATests
//
//  Ask: the plan survives a round trip byte for byte (snake_case keys,
//  integer values), chip removal / clarification edits, answer decoding
//  per view type, and "Open the full view" link mapping.
//
import XCTest
@testable import Chalk_That_NBA

final class AskTests: XCTestCase {

    private let statsAnswer = """
    { "question": "lebron away 2003-04", "plan": { "kind": "player_stats", "player": "LeBron James", "season": "2003-04",
        "venue": "away", "season_type": "regular", "rest_by": "team", "b2b": 2 },
      "cached": false, "model": "claude-haiku-4-5",
      "subject": { "player": { "id": "p", "name": "LeBron James" }, "team": null, "opponent": null },
      "sentence": "LeBron James averaged 20.6 points, 5.3 rebounds and 5.8 assists in 41 2003-04 regular season games on the road (his team went 12-29).",
      "view": { "type": "stats", "query": {
        "query": { "entity": "player", "id": "p", "scope": "season", "season": "2003-04", "seasonType": "regular", "splits": { "venue": "away" } },
        "subject": { "type": "player", "id": "p", "name": "LeBron James" },
        "data": { "gp": 41, "pts": 20.6, "reb": 5.3, "ast": 5.8, "fg3m": 0.8, "fg_pct": 0.41, "ts_pct": 0.481, "minutes": 40.1 },
        "meta": { "sample_size": 41, "record": "12-29", "notes": ["Neutral-site games are excluded from home/away."], "freshness": { "synced_at": null } } } },
      "chips": [ { "key": "season", "label": "2003-04", "removable": true }, { "key": "venue", "label": "Away", "removable": true },
                 { "key": "rest_by", "label": "Rest by team schedule", "removable": true } ],
      "link": "/players/p?season=2003-04&venue=away&restby=team&b2b=2",
      "season": "2003-04" }
    """

    func testStatsAnswerDecodes() throws {
        let a = try JSONDecoder.chalkThatNBA.decode(AskAnswer.self, from: Data(statsAnswer.utf8))
        XCTAssertTrue(a.sentence.hasPrefix("LeBron James averaged 20.6"))
        guard case .stats(let scope, let subject, let content, let meta) = a.view else { return XCTFail("expected stats") }
        XCTAssertEqual(scope, "season")
        XCTAssertEqual(subject, "player")
        XCTAssertEqual(meta.sampleSize, 41)
        guard case .averages(let d) = content else { return XCTFail("expected averages") }
        XCTAssertEqual(Format.pct(d?.tsPct), ".481")
        XCTAssertEqual(a.chips?.map(\.key), ["season", "venue", "rest_by"])
    }

    func testPlanKeepsItsKeysAndIntegers() throws {
        let raw = try JSONDecoder().decode(AskRawPlan.self, from: Data(statsAnswer.utf8))
        let plan = try XCTUnwrap(raw.plan)
        XCTAssertEqual(plan.object?["season_type"], .string("regular"))
        XCTAssertEqual(plan.object?["b2b"], .int(2))

        // Removing the rest_by chip deletes exactly that key; the rest goes back unchanged.
        let edited = plan.removing("rest_by")
        let body = try JSONEncoder().encode(["plan": edited])
        let sent = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let sentPlan = try XCTUnwrap(sent["plan"] as? [String: Any])
        XCTAssertNil(sentPlan["rest_by"])
        XCTAssertEqual(sentPlan["season_type"] as? String, "regular")
        XCTAssertEqual(sentPlan["b2b"] as? Int, 2)
        XCTAssertFalse(String(decoding: body, as: UTF8.self).contains("seasonType"))
    }

    func testClarificationSetsTheField() {
        let plan = JSONValue.object(["kind": .string("player_stats"), "player": .string("Williams")])
        XCTAssertEqual(plan.setting("player", to: "Jalen Williams").object?["player"], .string("Jalen Williams"))
    }

    func testClarifyAnswerDecodes() throws {
        let json = """
        { "plan": { "kind": "player_stats", "player": "Williams" }, "sentence": "Which Williams?",
          "clarify": { "field": "player", "options": [ { "id": "a", "name": "Jalen Williams" }, { "id": "b", "name": "Jaylin Williams" } ] },
          "view": { "type": "clarify" }, "chips": [] }
        """
        let a = try JSONDecoder.chalkThatNBA.decode(AskAnswer.self, from: Data(json.utf8))
        XCTAssertEqual(a.clarify?.options.map(\.name), ["Jalen Williams", "Jaylin Williams"])
        guard case .clarify = a.view else { return XCTFail("expected clarify") }
    }

    func testTeamClarifyWithNumericIds() throws {
        let json = #"{ "sentence": "Which team — LA Clippers or Los Angeles Lakers?", "clarify": { "field": "team", "options": [ { "id": 13, "name": "LA Clippers" } ] }, "view": { "type": "clarify" } }"#
        let a = try JSONDecoder.chalkThatNBA.decode(AskAnswer.self, from: Data(json.utf8))
        XCTAssertEqual(a.clarify?.field, "team")
    }

    func testLeadersAndSeriesAnswers() throws {
        let leaders = #"{ "sentence": "s", "view": { "type": "leaders", "stat": "usg_pct", "rows": [ { "rank": 1, "player_id": "p", "full_name": "A", "gp": 70, "value": 0.353, "team": "DAL" } ] } }"#
        let a = try JSONDecoder.chalkThatNBA.decode(AskAnswer.self, from: Data(leaders.utf8))
        guard case .leaders(let stat, let rows) = a.view else { return XCTFail("expected leaders") }
        XCTAssertEqual(stat, "usg_pct")
        XCTAssertEqual(Format.usgPct(rows.first?.value), "35.3%")

        let series = """
        { "sentence": "s", "view": { "type": "series", "rows": [ { "id": 7, "round": "finals", "conference": null, "higher_id": 1, "higher_abbr": "OKC",
          "lower_id": 2, "lower_abbr": "IND", "winner_team_id": 1, "higher_wins": 4, "lower_wins": 3 } ] } }
        """
        let b = try JSONDecoder.chalkThatNBA.decode(AskAnswer.self, from: Data(series.utf8))
        guard case .series(let rows2) = b.view, let x = rows2.first else { return XCTFail("expected series") }
        XCTAssertEqual(AskText.seriesResult(x), "OKC 4-3")
        XCTAssertEqual(AskText.seriesRound(x), "Finals")
    }

    func testUnknownViewTypeDoesNotFailDecoding() throws {
        let a = try JSONDecoder.chalkThatNBA.decode(AskAnswer.self, from: Data(#"{ "sentence": "s", "view": { "type": "something_new" } }"#.utf8))
        guard case .other = a.view else { return XCTFail("expected other") }
    }

    // MARK: - Web links -> native screens

    func testPlayerLinkCarriesTheFilters() {
        guard case .player(let id, _, _, let filters) = WebLink.route("/players/p?season=2003-04&venue=away&restby=team&b2b=2&scope=last10") else {
            return XCTFail("expected player")
        }
        XCTAssertEqual(id, "p")
        XCTAssertEqual(filters?.season, "2003-04")
        XCTAssertEqual(filters?.venue, "away")
        XCTAssertEqual(filters?.restBy, "team")
        XCTAssertEqual(filters?.b2b, "2")
        XCTAssertEqual(filters?.scope, "last10")
    }

    func testInvalidFilterValuesAreDropped() {
        let f = ExplorerFilters.fromWebQuery(["venue": "moon", "type": "preseason", "scope": "forever", "rest": "3+"])
        XCTAssertNil(f.venue)
        XCTAssertEqual(f.seasonType, "regular")
        XCTAssertEqual(f.scope, "season")
        XCTAssertEqual(f.rest, "3+")
    }

    func testOtherLinks() {
        guard case .team(let tid, _, _, let tf) = WebLink.route("/teams/8?season=2025-26&type=playoffs") else { return XCTFail("team") }
        XCTAssertEqual(tid, 8)
        XCTAssertEqual(tf?.seasonType, "playoffs")
        guard case .game(let gid) = WebLink.route("/games/abc") else { return XCTFail("game") }
        XCTAssertEqual(gid, "abc")
        guard case .leaders(let s, _, let stat) = WebLink.route("/leaders?season=2025-26&stat=stl") else { return XCTFail("leaders") }
        XCTAssertEqual(s, "2025-26")
        XCTAssertEqual(stat, "stl")
        guard case .rankings(let view, _, let pos, let sort, _) = WebLink.route("/rankings?view=matchups&season=2025-26&pos=C&sort=reb") else { return XCTFail("rankings") }
        XCTAssertEqual(view, "matchups")
        XCTAssertEqual(pos, "C")
        XCTAssertEqual(sort, "reb")
        guard case .standings(_, let bracket) = WebLink.route("/standings?season=2019-20&view=bracket") else { return XCTFail("standings") }
        XCTAssertTrue(bracket)
        XCTAssertNil(WebLink.route("/somewhere/else"))
        XCTAssertNil(WebLink.route(nil))
    }
}
