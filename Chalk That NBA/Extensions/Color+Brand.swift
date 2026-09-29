//
//  Color+Brand.swift
//  Chalk That NBA
//
//  Single source of truth for design tokens: ios-kickoff.md §5, which
//  matches the web's frontend/src/index.css `@theme` block (and the Chalk
//  That NFL palette). Token names follow the web so a web class like
//  `text-muted` or `bg-card` maps to `Color.muted` / `Color.card`.
//
//  Rule: no hex values anywhere else in the app. Keep this file in sync
//  with index.css by hand; there's no build-time link between the repos.
//
//  `Color.accent` (#F4762B) is NOT declared here: Assets.xcassets'
//  AccentColor colorset generates it (ASSETCATALOG_COMPILER_GENERATE_
//  SWIFT_ASSET_SYMBOL_EXTENSIONS), and declaring it again is an
//  "Invalid redeclaration" error. Same as the NFL app.
//
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }

    // MARK: - Surfaces
    static let paper      = Color(hex: "#0B0F14")  // app background
    static let card       = Color(hex: "#121820")  // cards / surfaces, nav + tab bars
    static let card2      = Color(hex: "#1A222C")  // raised surface, selected rows
    static let rule       = Color(hex: "#1A222C")  // row dividers
    static let line       = Color(hex: "#2A3540")  // borders
    static let strong     = Color(hex: "#3E4B58")  // heavy table rules
    static let field      = Color(hex: "#3A4652")  // input borders

    // MARK: - Text
    static let ink        = Color(hex: "#F5F7FA")  // primary text
    static let muted      = Color(hex: "#9AA7B4")  // secondary text
    static let faint      = Color(hex: "#62717D")  // tertiary text, "HARDWOOD" in the wordmark

    // MARK: - Interactive
    static let link       = Color(hex: "#4D9FEC")  // links / tappable names
    static let onAccent   = Color(hex: "#0B0F14")  // text on the accent color

    // MARK: - Semantic
    static let altBg      = Color(hex: "#3A2415")  // highlight chip background
    static let altInk     = Color(hex: "#FFB27A")  // highlight chip text
    static let live       = Color(hex: "#F2545B")  // live games
    static let positive   = Color(hex: "#34D399")  // over / strong
    static let positiveBg = Color(hex: "#0F2E24")
    static let caution    = Color(hex: "#E8B64A")  // warnings, estimates
}
