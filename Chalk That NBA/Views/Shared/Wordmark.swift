//
//  Wordmark.swift
//  Chalk That NBA
//
//  "CHALK THAT NBA" with NBA in `faint`, as in the web header and Login.
//
import SwiftUI

struct Wordmark: View {
    var size: CGFloat = 22

    var body: some View {
        (Text("CHALK THAT ").foregroundColor(.ink) + Text("NBA").foregroundColor(.faint))
            .font(.brandDisplay(size, weight: .bold))
            .tracking(size * 0.04)
            .accessibilityLabel("Chalk That NBA")
    }
}

#Preview {
    Wordmark(size: 30)
        .padding()
        .background(Color.paper)
}
