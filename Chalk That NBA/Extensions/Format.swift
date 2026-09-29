//
//  Format.swift
//  Chalk That NBA
//
//  Port of the web's frontend/src/lib/format.js (ios-kickoff.md §6). The
//  output must match the web character for character, so every function
//  here names its JS original. Formatting only: nothing here computes a
//  stat.
//
//  Calendar dates ("YYYY-MM-DD", the home venue's local date) are
//  formatted in a fixed UTC calendar, the same trick as the web's
//  `asDate()`, so no viewer timezone can move them a day. Only tip-off
//  times use the viewer's timezone.
//
import Foundation

enum Format {
    // MARK: - Calendar dates

    private static let utc = TimeZone(identifier: "UTC")!
    private static let usLocale = Locale(identifier: "en_US_POSIX")

    private static var utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar
    }()

    /// "2026-10-21" -> noon UTC that day, or nil if it isn't a real date (`isYmd`).
    static func calendarDate(_ ymd: String) -> Date? {
        let parts = ymd.split(separator: "-").compactMap { Int($0) }
        guard ymd.count == 10, parts.count == 3 else { return nil }
        let components = DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)
        guard let date = utcCalendar.date(from: components),
              utcCalendar.dateComponents([.year, .month, .day], from: date) == DateComponents(year: parts[0], month: parts[1], day: parts[2])
        else { return nil }
        return date
    }

    static func isYmd(_ value: String?) -> Bool {
        guard let value else { return false }
        return calendarDate(value) != nil
    }

    /// `todayLocal()`: today's date where the viewer is, as "YYYY-MM-DD".
    static func todayLocal(_ now: Date = Date(), calendar: Calendar = .current) -> String {
        ymd(calendar.dateComponents([.year, .month, .day], from: now))
    }

    /// A calendar day (from a DatePicker, in the viewer's calendar) as "YYYY-MM-DD".
    static func ymd(fromLocal date: Date, calendar: Calendar = .current) -> String {
        ymd(calendar.dateComponents([.year, .month, .day], from: date))
    }

    /// "YYYY-MM-DD" -> that day at noon in the viewer's calendar (for a DatePicker).
    static func localDate(fromYmd ymd: String, calendar: Calendar = .current) -> Date? {
        let parts = ymd.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }

    private static func ymd(_ c: DateComponents) -> String {
        String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private static func utcFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = usLocale
        formatter.timeZone = utc
        formatter.dateFormat = format
        return formatter
    }

    private static let longFormatter  = utcFormatter("EEEE, MMMM d, yyyy")
    private static let shortFormatter = utcFormatter("EEE, MMM d, yyyy")
    private static let tinyFormatter  = utcFormatter("MMM d")
    private static let tinyYearFormatter = utcFormatter("MMM d, yyyy")

    /// `longDate`: "Sunday, April 12, 2026"
    static func longDate(_ ymd: String) -> String {
        calendarDate(ymd).map(longFormatter.string(from:)) ?? ymd
    }

    /// `shortDate`: "Sun, Apr 12, 2026"
    static func shortDate(_ ymd: String) -> String {
        calendarDate(ymd).map(shortFormatter.string(from:)) ?? ymd
    }

    /// `tinyDate`: "Apr 12", or "Aug 15, 2020" when the year differs from `relativeTo`.
    static func tinyDate(_ ymd: String, relativeTo: String? = nil) -> String {
        guard let date = calendarDate(ymd) else { return ymd }
        if let relativeTo, relativeTo.prefix(4) != ymd.prefix(4) {
            return tinyYearFormatter.string(from: date)
        }
        return tinyFormatter.string(from: date)
    }

    // MARK: - Times (viewer's timezone)

    private static let tipFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = usLocale
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    /// `tipTime`: "7:30 PM" in the viewer's timezone, or "Time TBD".
    static func tipTime(_ utc: String?, timeZone: TimeZone = .current) -> String {
        guard let date = BackendDate.parse(utc) else { return "Time TBD" }
        tipFormatter.timeZone = timeZone
        return tipFormatter.string(from: date)
    }

    /// `ago`: "just now", "12 min ago", "3 h ago", "2 days ago".
    static func ago(_ iso: String?, now: Date = Date()) -> String? {
        guard let date = BackendDate.parse(iso) else { return nil }
        let s = max(0, now.timeIntervalSince(date))
        if s < 60 { return "just now" }
        if s < 3600 { return "\(Int(s / 60)) min ago" }
        if s < 86400 { return "\(Int(s / 3600)) h ago" }
        let d = Int(s / 86400)
        return "\(d) day\(d == 1 ? "" : "s") ago"
    }

    // MARK: - Labels

    /// `SEASON_TYPE` (a game's season_type).
    static func seasonType(_ type: String) -> String? {
        ["preseason": "Preseason", "regular": "Regular season", "play_in": "Play-In",
         "playoffs": "Playoffs", "cup_final": "NBA Cup Final"][type]
    }

    /// `SEASON_TYPE_LOWER` (a query's season_type).
    static func seasonTypeLower(_ type: String) -> String? {
        ["regular": "regular season", "play_in": "play-in", "playoffs": "playoffs",
         "all": "all game types", "cup": "NBA Cup"][type]
    }

    private static let rounds = ["first_round": "First round", "conf_semis": "Conf. semifinals",
                                 "conf_finals": "Conf. finals", "finals": "NBA Finals"]

    /// `gameContext`: "First round · Game 2", "Play-In", "NBA Cup group", "in Tokyo"…
    static func gameContext(seasonType: String, seriesRound: String?, seriesGameNumber: Int?,
                            cupStage: String?, isNeutralSite: Bool, arenaCity: String?) -> String {
        var bits: [String] = []
        if seasonType == "playoffs", let round = seriesRound {
            let name = rounds[round] ?? "Round \(round)"
            bits.append(seriesGameNumber.map { "\(name) · Game \($0)" } ?? name)
        } else if seasonType == "play_in" {
            bits.append("Play-In")
        } else if seasonType == "preseason" {
            bits.append("Preseason")
        } else if seasonType == "cup_final" {
            bits.append("NBA Cup Final")
        } else if let cupStage {
            bits.append(cupStage == "group" ? "NBA Cup group" : "NBA Cup \(cupStage)")
        }
        if isNeutralSite, let arenaCity, !arenaCity.isEmpty { bits.append("in \(arenaCity)") }
        return bits.joined(separator: " · ")
    }

    /// `restLabel`: "1 day rest", "0 days rest · 2nd night of a back-to-back", "no prior game this season".
    static func restLabel(_ rest: Int?, b2b: Int?) -> String {
        guard let rest else { return "no prior game this season" }
        let r = "\(rest) day\(rest == 1 ? "" : "s") rest"
        if b2b == 2 { return "\(r) · 2nd night of a back-to-back" }
        if b2b == 1 { return "\(r) · 1st night of a back-to-back" }
        return r
    }

    /// `tvLabel`: "Local TV only" or "National TV: ESPN, ABC".
    static func tvLabel(tier: String, networks: [String]) -> String {
        tier == "local" || networks.isEmpty ? "Local TV only" : "National TV: \(networks.joined(separator: ", "))"
    }

    // MARK: - Numbers

    /// `mins`: box-score minutes as a whole number; "" when missing.
    static func mins(_ m: Double?) -> String {
        guard let m else { return "" }
        return String(Int(jsRound(m)))
    }

    /// `pm`: "+5", "-3", "0"; "" when missing.
    static func pm(_ v: Int?) -> String {
        guard let v else { return "" }
        return v > 0 ? "+\(v)" : String(v)
    }

    /// `made`: "8-17"; "" when either is missing.
    static func made(_ m: Int?, _ a: Int?) -> String {
        guard let m, let a else { return "" }
        return "\(m)-\(a)"
    }

    /// `avg`: 1 decimal ("20.9", "2.0"), or "—".
    static func avg(_ v: Double?) -> String {
        guard let v else { return "—" }
        return toFixed1(v)
    }

    /// `pct`: the NBA way, ".488", "1.000" at 100%, or "—".
    static func pct(_ v: Double?) -> String {
        guard let v else { return "—" }
        if v >= 1 { return "1.000" }
        let thousandths = Int(jsRound(v * 1000))
        return "." + String(format: "%03d", thousandths)
    }

    /// `usgPct`: "28.3%", or "—".
    static func usgPct(_ v: Double?) -> String {
        guard let v else { return "—" }
        return toFixed1(v * 100) + "%"
    }

    /// `signedAvg`: "+4.2", "-1.0", "0.0", or "—".
    static func signedAvg(_ v: Double?) -> String {
        guard let v else { return "—" }
        return (v > 0 ? "+" : "") + toFixed1(v)
    }

    /// `ordinal` (lib/rankings.js): 1st, 2nd, 3rd, 11th, 22nd.
    static func ordinal(_ n: Int?) -> String {
        guard let n else { return "" }
        let v = n % 100
        if (11...13).contains(v) { return "\(n)th" }
        switch n % 10 {
        case 1: return "\(n)st"
        case 2: return "\(n)nd"
        case 3: return "\(n)rd"
        default: return "\(n)th"
        }
    }

    /// A number the way JS prints it: 25.5, 26 (not 26.0), 4.5.
    static func jsNumber(_ v: Double) -> String {
        v == v.rounded() && abs(v) < 1e15 ? String(Int(v)) : String(v)
    }

    /// Standings win %: `pct.toFixed(3).replace(/^0/, '')` -> ".683", "1.000"; "—" when missing.
    static func winPct(_ v: Double?) -> String {
        guard let v else { return "—" }
        let s = String(format: "%.3f", v)
        return s.hasPrefix("0") ? String(s.dropFirst()) : s
    }

    /// `toLocaleString()` for whole numbers: 5,280.
    static func thousands(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")   // en_US_POSIX has no grouping separator
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? String(n)
    }

    /// Team "Net rtg (est.)": off_rtg − def_rtg, signed, 1 decimal.
    /// THE ONE DERIVED NUMBER IN THE APP, on purpose: the web computes it
    /// the same way in the browser (StatExplorer.jsx Tiles / Career), and
    /// JD chose web parity over a backend change (2026-09-28). Same double
    /// subtraction as JS, same toFixed(1), so it matches the web exactly.
    static func netRating(off: Double?, def: Double?) -> String {
        guard let off, let def else { return "—" }
        return signedAvg(off - def)
    }

    // MARK: - JS-compatible rounding

    /// JavaScript's `Math.round`: nearest integer, halves go up (toward +∞).
    /// `v - floor(v)` is exact for doubles in any stat's range.
    static func jsRound(_ v: Double) -> Double {
        let f = v.rounded(.down)
        return v - f >= 0.5 ? f + 1 : f
    }

    /// JavaScript's `Number.prototype.toFixed(1)`. It rounds the double's
    /// exact decimal value, and an exact tie goes away from zero; C's
    /// "%.1f" does the same except ties go to even ("0.25" -> "0.2" vs JS
    /// "0.3"). An exact tie at one decimal is only possible for x.25 / x.75,
    /// i.e. when v * 4 is an odd integer, so those are handled here.
    static func toFixed1(_ v: Double) -> String {
        let quadrupled = v * 4
        if quadrupled == quadrupled.rounded(), Int(quadrupled.magnitude) % 2 == 1 {
            let rounded = (v * 10).rounded(.toNearestOrAwayFromZero) / 10
            return String(format: "%.1f", rounded)
        }
        return String(format: "%.1f", v)
    }
}
