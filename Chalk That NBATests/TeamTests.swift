//
//  TeamTests.swift
//  Chalk That NBATests
//
//  Team detail's pieces: the Net rtg exception (matches the web's
//  signedAvg(off_rtg - def_rtg); cross-checked against Node over 50,000
//  pairs when written), ordinal ranks, thousands separators, and the
//  team / matchups / roster payloads decoding.
//
import XCTest
@testable import Chalk_That_NBA

final class TeamTests: XCTestCase {

    func testNetRatingMatchesTheWeb() {
        XCTAssertEqual(Format.netRating(off: 116.2, def: 113.8), "+2.4")
        XCTAssertEqual(Format.netRating(off: 108.0, def: 112.5), "-4.5")
        XCTAssertEqual(Format.netRating(off: 110.0, def: 110.0), "0.0")
        XCTAssertEqual(Format.netRating(off: nil, def: 110.0), "—")
    }

    func testOrdinal() {
        XCTAssertEqual(Format.ordinal(1), "1st")
        XCTAssertEqual(Format.ordinal(2), "2nd")
        XCTAssertEqual(Format.ordinal(3), "3rd")
        XCTAssertEqual(Format.ordinal(11), "11th")
        XCTAssertEqual(Format.ordinal(13), "13th")
        XCTAssertEqual(Format.ordinal(22), "22nd")
        XCTAssertEqual(Format.ordinal(nil), "")
    }

    func testThousands() {
        XCTAssertEqual(Format.thousands(5280), "5,280")
        XCTAssertEqual(Format.thousands(46), "46")
    }

    func testTeamDetailDecodes() throws {
        let json = """
        { "data": { "id": 8, "abbreviation": "DEN", "city": "Denver", "name": "Nuggets", "full_name": "Denver Nuggets",
          "conference": "West", "division": "Northwest", "home_arena_id": 3, "arena": "Ball Arena", "arena_city": "Denver",
          "elevation_ft": 5280, "is_high_altitude": true,
          "roster": [ { "id": "p", "full_name": "Nikola Jokić", "listed_position": "C", "height_in": 83, "weight_lb": 284, "birth_date": "1995-02-19" } ],
          "season_types": { "2025-26": ["play_in", "playoffs", "regular", "cup"] } } }
        """
        let t = try JSONDecoder.chalkThatNBA.decode(APIEnvelope<TeamDetail, EmptyMeta>.self, from: Data(json.utf8)).data
        XCTAssertEqual(t.subtitle, "Western Conference · Northwest · Ball Arena")
        XCTAssertEqual(t.elevationFt, 5280)
        XCTAssertEqual(t.seasonTypes["2025-26"]?.contains("cup"), true)
    }

    func testMatchupsDecodeWithNullLabels() throws {
        let json = """
        { "data": { "G": [ { "team_id": 11, "abbr": "ATL", "games": 82, "allowed": { "pts": 49.1, "reb": 14.2 },
                             "vs_avg": { "pts": 1.3, "reb": -0.4 }, "rank": { "pts": 24, "reb": 10 }, "label": { "pts": "weak", "reb": null } } ],
                    "F": [], "C": [] },
          "league_avg": { "G": { "pts": 47.8 } },
          "meta": { "teams": 30, "unlisted_share": 0, "notes": [] } }
        """
        let m = try JSONDecoder.chalkThatNBA.decode(MatchupsData.self, from: Data(json.utf8))
        let row = try XCTUnwrap(m.data["G"]?.first)
        XCTAssertEqual(row.rank["pts"] ?? nil, 24)
        XCTAssertEqual(row.label["pts"] ?? nil, "weak")
        XCTAssertNil(row.label["reb"] ?? nil)
        XCTAssertEqual(Format.signedAvg(row.vsAvg["reb"] ?? nil), "-0.4")
    }

    func testTeamGameLogRow() throws {
        let json = """
        { "game_id": "g", "date": "2026-01-05", "season": "2025-26", "season_type": "regular", "venue": "home",
          "opponent": "LAL", "won": true, "pts": 118, "opp_pts": 110, "rest_days": 0, "b2b_night": 2,
          "national_tv_tier": "major", "altitude": true }
        """
        let r = try JSONDecoder.chalkThatNBA.decode(GameLogRow.self, from: Data(json.utf8))
        XCTAssertEqual(GameLogText.opponent(r), "vs LAL")
        XCTAssertEqual(GameLogText.tags(r, restBy: "team"), "B2B night 2 · 0d rest · Altitude · National TV")
        XCTAssertEqual(r.oppPts, 110)
    }

    func testTeamNoGamesPossessive() {
        var f = ExplorerFilters()
        f.season = "2025-26"
        f.b2b = "2"
        XCTAssertEqual(NoGamesMessage.make(name: "the Denver Nuggets", filters: f, played: ["regular"]).text,
                       "None of the Denver Nuggets' 2025-26 regular season games match this split.")
    }
}
