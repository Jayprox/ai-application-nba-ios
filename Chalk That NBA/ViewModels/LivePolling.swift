//
//  LivePolling.swift
//  Chalk That NBA
//
//  While a screen shows a live game, re-fetch about every 60 seconds
//  (ios-kickoff.md §3: optional; the worker updates live scores about
//  every 5 minutes, so this is plenty). Runs inside a view's
//  `.task(id:)`, so it stops when the screen goes away or its key
//  changes. Re-fetches are quiet: a failed one keeps what's on screen.
//
import Foundation

enum LivePolling {
    static let interval: UInt64 = 60 * 1_000_000_000

    @MainActor
    static func run(isLive: @escaping () -> Bool, refresh: @escaping () async -> Void) async {
        while !Task.isCancelled, isLive() {
            try? await Task.sleep(nanoseconds: interval)
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }
}
