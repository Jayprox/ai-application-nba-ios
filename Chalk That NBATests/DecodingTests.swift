//
//  DecodingTests.swift
//  Chalk That NBATests
//
//  The wire models decode api.md's own example responses (§4), including
//  nulls where the API sends them. If the contract changes, these break
//  before a screen does.
//
import XCTest
@testable import Chalk_That_NBA

final class DecodingTests: XCTestCase {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder.chalkThatNBA.decode(T.self, from: Data(json.utf8))
    }

    func testScoreboard() throws {
        let json = """
        { "data": [ { "id": "3f1c", "season": "2003-04", "season_type": "regular", "cup_stage": null, "date": "2003-10-30",
          "tipoff_utc": "2003-10-31T03:30:00.000Z", "status": "final", "is_neutral_site": false,
          "national_tv_tier": "major", "national_broadcasters": ["TNT"], "home": "PHX", "home_score": 95,
          "away": "CLE", "away_score": 86, "arena": "US Airways Center", "arena_city": "Phoenix",
          "series_round": null, "series_game_number": null } ],
          "meta": { "date": "2003-10-30", "count": 1, "prev_date": "2003-10-29", "next_date": null } }
        """
        let envelope = try decode(APIEnvelope<[ScoreboardGame], GamesMeta>.self, json)
        let game = try XCTUnwrap(envelope.data.first)
        XCTAssertEqual(game.date, "2003-10-30")
        XCTAssertEqual(game.nationalBroadcasters, ["TNT"])
        XCTAssertEqual(game.homeScore, 95)
        XCTAssertTrue(game.isFinal)
        XCTAssertEqual(envelope.meta?.prevDate, "2003-10-29")
        XCTAssertNil(envelope.meta?.nextDate)
    }

    func testScheduledGameHasNullScores() throws {
        let json = """
        { "data": [ { "id": "x", "season": "2026-27", "season_type": "regular", "cup_stage": null, "date": "2026-10-21",
          "tipoff_utc": null, "status": "scheduled", "is_neutral_site": false, "national_tv_tier": "local",
          "national_broadcasters": [], "home": "NYK", "home_score": null, "away": "BOS", "away_score": null,
          "arena": null, "arena_city": null, "series_round": null, "series_game_number": null } ],
          "meta": { "date": "2026-10-21", "count": 1, "prev_date": null, "next_date": "2026-10-22" } }
        """
        let game = try XCTUnwrap(try decode(APIEnvelope<[ScoreboardGame], GamesMeta>.self, json).data.first)
        XCTAssertNil(game.homeScore)
        XCTAssertNil(game.tipoffUtc)
    }

    func testBoxScore() throws {
        let json = """
        { "data": {
          "game": { "id": "g1", "season": "2003-04", "season_type": "regular", "cup_stage": null, "playoff_series_id": null,
            "series_game_number": null, "game_date_local": "2003-10-30", "tipoff_utc": "2003-10-30T10:00:00.000Z",
            "home_team_id": 1, "away_team_id": 18, "is_neutral_site": true, "national_tv_tier": "nba_tv",
            "national_broadcasters": ["NBA TV"], "status": "final", "home_score": 109, "away_score": 100,
            "arena": "Saitama Super Arena", "arena_city": "Tokyo", "is_high_altitude": false, "box_score_checks": 2 },
          "teams": [ {
            "game_id": "g1", "team_id": 18, "abbreviation": "LAC", "full_name": "LA Clippers", "opponent_team_id": 1,
            "venue_split": "neutral", "rest_days": null, "b2b_night": 1, "won": false,
            "minutes": 240, "pts": 100, "fgm": 38, "fga": 91, "fg3m": 5, "fg3a": 14, "ftm": 19, "fta": 25,
            "oreb": 12, "dreb": 30, "reb": 42, "ast": 20, "stl": 7, "blk": 4, "tov": 15, "pf": 22, "plus_minus": -9,
            "players": [
              { "game_id": "g1", "player_id": "p1", "full_name": "Elton Brand", "team_id": 18, "started": true, "dnp": false,
                "dnp_reason": null, "minutes": 41.5, "pts": 21, "fgm": 9, "fga": 17, "fg3m": 0, "fg3a": 0, "ftm": 3, "fta": 4,
                "oreb": 3, "dreb": 8, "reb": 11, "ast": 2, "stl": 1, "blk": 2, "tov": 3, "pf": 3, "plus_minus": -4,
                "player_rest_days": null, "player_b2b_night": 1, "source": "nba_stats" },
              { "game_id": "g1", "player_id": "p2", "full_name": "Bench Guy", "team_id": 18, "started": null, "dnp": true,
                "dnp_reason": "Coach's decision", "minutes": null, "pts": null, "fgm": null, "fga": null, "fg3m": null,
                "fg3a": null, "ftm": null, "fta": null, "oreb": null, "dreb": null, "reb": null, "ast": null, "stl": null,
                "blk": null, "tov": null, "pf": null, "plus_minus": null, "player_rest_days": null, "player_b2b_night": null,
                "source": "nba_stats" } ] } ] } }
        """
        let box = try decode(APIEnvelope<BoxScore, EmptyMeta>.self, json).data
        XCTAssertEqual(box.game.gameDateLocal, "2003-10-30")
        XCTAssertEqual(box.game.arenaCity, "Tokyo")
        let team = try XCTUnwrap(box.teams.first)
        XCTAssertEqual(team.b2bNight, 1)
        XCTAssertEqual(team.plusMinus, -9)
        XCTAssertEqual(team.minutes, 240)
        XCTAssertEqual(team.players[0].minutes, 41.5)
        XCTAssertEqual(team.players[0].playerB2bNight, 1)
        XCTAssertTrue(team.players[1].dnp)
        XCTAssertNil(team.players[1].pts)
    }

    func testErrorBody() throws {
        let body = try decode(APIErrorResponse.self, #"{ "error": "too_many_attempts", "retry_after_seconds": 840 }"#)
        XCTAssertEqual(body.error, "too_many_attempts")
        XCTAssertEqual(body.retryAfterSeconds, 840)
    }
}
