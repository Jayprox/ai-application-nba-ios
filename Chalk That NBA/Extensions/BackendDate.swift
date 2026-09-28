//
//  BackendDate.swift
//  Chalk That NBA
//
//  Parses the API's timestamps (`tipoff_utc`, `*_at`, `synced_at`), which
//  are ISO-8601 UTC with milliseconds ("2026-10-22T02:30:00.000Z").
//  `ISO8601DateFormatter`'s default options don't accept fractional
//  seconds and silently return nil; the NFL app hit exactly that ("Date
//  TBD" everywhere), so this helper is copied from there.
//
//  NOT for calendar dates. `date` / `game_date_local` ("2026-10-21") is
//  the home venue's local date and must never become a `Date` in UTC, or
//  it can move a day (api.md §1). Those stay strings / calendar dates;
//  see the formatting helpers.
//
import Foundation

enum BackendDate {
    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let standard = ISO8601DateFormatter()

    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        return withFractionalSeconds.date(from: value) ?? standard.date(from: value)
    }
}
