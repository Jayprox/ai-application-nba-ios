//
//  FormatTests.swift
//  Chalk That NBATests
//
//  Format must match the web's lib/format.js character for character
//  (ios-kickoff.md §6). Expected strings are what format.js produces.
//  The rounding cases were cross-checked against Node's toFixed /
//  Math.round over 60,000 values when this was written.
//
import XCTest
@testable import Chalk_That_NBA

final class FormatTests: XCTestCase {

    // MARK: - Calendar dates: no timezone can move them

    func testDatesIgnoreViewerTimezone() {
        let original = NSTimeZone.default
        defer { NSTimeZone.default = original }
        for zone in ["Pacific/Honolulu", "America/Los_Angeles", "UTC", "Asia/Tokyo", "Pacific/Kiritimati"] {
            NSTimeZone.default = TimeZone(identifier: zone)!
            XCTAssertEqual(Format.longDate("2026-04-12"), "Sunday, April 12, 2026", zone)
            XCTAssertEqual(Format.shortDate("2026-04-12"), "Sun, Apr 12, 2026", zone)
            XCTAssertEqual(Format.tinyDate("2026-04-12"), "Apr 12", zone)
        }
    }

    func testTinyDateAddsYearAcrossSeasons() {
        XCTAssertEqual(Format.tinyDate("2020-08-15", relativeTo: "2026-10-21"), "Aug 15, 2020")
        XCTAssertEqual(Format.tinyDate("2026-10-22", relativeTo: "2026-10-21"), "Oct 22")
    }

    func testIsYmd() {
        XCTAssertTrue(Format.isYmd("2024-02-29"))
        XCTAssertFalse(Format.isYmd("2025-02-29"))
        XCTAssertFalse(Format.isYmd("2026-13-01"))
        XCTAssertFalse(Format.isYmd("tomorrow"))
        XCTAssertFalse(Format.isYmd(nil))
    }

    func testPickerRoundTripKeepsTheDay() {
        let date = Format.localDate(fromYmd: "2026-10-21")!
        XCTAssertEqual(Format.ymd(fromLocal: date), "2026-10-21")
    }

    // MARK: - Tip-off: viewer's timezone

    func testTipTime() {
        let tip = "2026-10-22T02:30:00.000Z"
        XCTAssertEqual(Format.tipTime(tip, timeZone: TimeZone(identifier: "America/New_York")!), "10:30 PM")
        XCTAssertEqual(Format.tipTime(tip, timeZone: TimeZone(identifier: "America/Los_Angeles")!), "7:30 PM")
        XCTAssertEqual(Format.tipTime(nil), "Time TBD")
    }

    // MARK: - Labels

    func testGameContext() {
        XCTAssertEqual(Format.gameContext(seasonType: "playoffs", seriesRound: "first_round", seriesGameNumber: 2,
                                          cupStage: nil, isNeutralSite: false, arenaCity: "Boston"), "First round · Game 2")
        XCTAssertEqual(Format.gameContext(seasonType: "playoffs", seriesRound: "finals", seriesGameNumber: 7,
                                          cupStage: nil, isNeutralSite: false, arenaCity: nil), "NBA Finals · Game 7")
        XCTAssertEqual(Format.gameContext(seasonType: "regular", seriesRound: nil, seriesGameNumber: nil,
                                          cupStage: "group", isNeutralSite: false, arenaCity: nil), "NBA Cup group")
        XCTAssertEqual(Format.gameContext(seasonType: "regular", seriesRound: nil, seriesGameNumber: nil,
                                          cupStage: nil, isNeutralSite: true, arenaCity: "Tokyo"), "in Tokyo")
        XCTAssertEqual(Format.gameContext(seasonType: "play_in", seriesRound: "play_in", seriesGameNumber: nil,
                                          cupStage: nil, isNeutralSite: false, arenaCity: nil), "Play-In")
        XCTAssertEqual(Format.gameContext(seasonType: "regular", seriesRound: nil, seriesGameNumber: nil,
                                          cupStage: nil, isNeutralSite: false, arenaCity: "Denver"), "")
    }

    func testRestAndTV() {
        XCTAssertEqual(Format.restLabel(1, b2b: nil), "1 day rest")
        XCTAssertEqual(Format.restLabel(0, b2b: 2), "0 days rest · 2nd night of a back-to-back")
        XCTAssertEqual(Format.restLabel(nil, b2b: nil), "no prior game this season")
        XCTAssertEqual(Format.tvLabel(tier: "major", networks: ["ESPN", "ABC"]), "National TV: ESPN, ABC")
        XCTAssertEqual(Format.tvLabel(tier: "local", networks: ["NBCS-BA"]), "Local TV only")
    }

    // MARK: - Numbers

    func testAveragesKeepOneDecimal() {
        XCTAssertEqual(Format.avg(20.9), "20.9")
        XCTAssertEqual(Format.avg(2), "2.0")
        XCTAssertEqual(Format.avg(nil), "—")
        // Exact ties round away from zero like JS toFixed, not to even like %.1f.
        XCTAssertEqual(Format.avg(0.25), "0.3")
        XCTAssertEqual(Format.avg(2.25), "2.3")
        XCTAssertEqual(Format.avg(0.15), "0.1")   // 0.15 is really 0.1499…, as in JS
    }

    func testPercentages() {
        XCTAssertEqual(Format.pct(0.488), ".488")
        XCTAssertEqual(Format.pct(1), "1.000")
        XCTAssertEqual(Format.pct(0.05), ".050")
        XCTAssertEqual(Format.pct(nil), "—")
        XCTAssertEqual(Format.usgPct(0.283), "28.3%")
    }

    func testSignedAndBoxScoreValues() {
        XCTAssertEqual(Format.signedAvg(1.5), "+1.5")
        XCTAssertEqual(Format.signedAvg(-2.6), "-2.6")
        XCTAssertEqual(Format.signedAvg(0), "0.0")
        XCTAssertEqual(Format.pm(-6), "-6")
        XCTAssertEqual(Format.pm(9), "+9")
        XCTAssertEqual(Format.pm(nil), "")
        XCTAssertEqual(Format.mins(35.5), "36")
        XCTAssertEqual(Format.mins(40.49), "40")
        XCTAssertEqual(Format.made(8, 17), "8-17")
        XCTAssertEqual(Format.made(nil, 17), "")
    }
}
