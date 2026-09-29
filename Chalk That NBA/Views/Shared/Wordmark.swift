//
//  Wordmark.swift
//  Chalk That NBA
//
//  "CHALK THAT HARDWOOD" with HARDWOOD in `faint`. The public name is
//  Chalk That Hardwood (2026-09-29): Apple rejects "NBA" in an app's name
//  or branding under Guideline 4.1(a), as it did "NFL" for the sister app
//  (now Chalk That Gridiron). Factual mentions (NBA.com, NBA Finals) stay.
//
import SwiftUI

struct Wordmark: View {
    var size: CGFloat = 22

    var body: some View {
        (Text("CHALK THAT ").foregroundColor(.ink) + Text("HARDWOOD").foregroundColor(.faint))
            .font(.brandDisplay(size, weight: .bold))
            .tracking(size * 0.04)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityLabel("Chalk That Hardwood")
    }
}

#Preview {
    Wordmark(size: 30)
        .padding()
        .background(Color.paper)
}
