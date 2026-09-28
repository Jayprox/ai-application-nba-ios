//
//  AppRoute.swift
//  Chalk That NBA
//
//  Every push destination, one enum for all tabs (the NFL app's
//  ResearchRoute pattern). Each tab's NavigationStack registers
//  `.appDestinations()`, so a box score can be opened from Scores, a game
//  log, or anywhere else, and lands on that tab's own stack.
//  Step 3+ adds player and team cases.
//
import SwiftUI

enum AppRoute: Hashable {
    case game(id: String)
}

extension View {
    func appDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .game(let id):
                BoxScoreView(gameId: id)
            }
        }
    }
}
