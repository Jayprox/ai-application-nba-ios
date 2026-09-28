//
//  AppRoute.swift
//  Chalk That NBA
//
//  Every push destination, one enum for all tabs (the NFL app's
//  ResearchRoute pattern). Each tab's NavigationStack registers
//  `.appDestinations()`, so a box score can be opened from Scores, a game
//  log, or anywhere else, and lands on that tab's own stack.
//
import SwiftUI

enum AppRoute: Hashable {
    case game(id: String)
    /// `season` / `seasonType` open the explorer on those filters (the
    /// web's `/players/:id?season=…&type=…` links from a team roster).
    case player(id: String, season: String? = nil, seasonType: String? = nil)
    /// `season` / `seasonType` open the explorer there (standings and
    /// bracket links, like the web's `/teams/:id?season=…&type=…`).
    case team(id: Int, season: String? = nil, seasonType: String? = nil)
}

extension View {
    func appDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .game(let id):
                BoxScoreView(gameId: id)
            case .player(let id, let season, let seasonType):
                PlayerDetailView(playerId: id, season: season, seasonType: seasonType)
            case .team(let id, let season, let seasonType):
                TeamDetailView(teamId: id, season: season, seasonType: seasonType)
            }
        }
    }
}
