//
//  ComingSoonView.swift
//  Chalk That NBA
//
//  Placeholder for screens not built yet; each one names its build step.
//  Removed screen by screen as the build order progresses.
//
import SwiftUI

struct ComingSoonView: View {
    let title: String
    let step: String

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            VStack(spacing: 8) {
                Text(title)
                    .font(.brandDisplay(24, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Text("Coming in \(step).")
                    .font(.brandBody(.subheadline))
                    .foregroundStyle(Color.muted)
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
