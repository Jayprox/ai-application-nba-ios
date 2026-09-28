//
//  Font+Brand.swift
//  Chalk That NBA
//
//  Two fonts, as on the web (index.css): Oswald for display (titles, the
//  wordmark, big stat numbers) and, for everything else, the system font
//  (ios-kickoff.md §5 allows Inter or system; system keeps Dynamic Type
//  and tabular digits free).
//
//  Oswald is bundled from Resources/Fonts (static Medium/SemiBold/Bold,
//  listed under UIAppFonts in Info.plist). If a file is missing, SwiftUI
//  falls back to the system font at the same size, so nothing breaks.
//
//  Both helpers scale with Dynamic Type. Numbers should also use
//  `.monospacedDigit()` so columns line up.
//
import SwiftUI

enum OswaldWeight: String {
    case medium   = "Oswald-Medium"
    case semibold = "Oswald-SemiBold"
    case bold     = "Oswald-Bold"
}

extension Font {
    /// Oswald at `size` points, scaling with Dynamic Type relative to `style`.
    static func brandDisplay(_ size: CGFloat, weight: OswaldWeight = .semibold, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }

    /// The system font for a text style, e.g. `.brandBody(.subheadline, weight: .semibold)`.
    static func brandBody(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        .system(style).weight(weight)
    }
}
