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
    /// `season` / `seasonType` (or full `filters`) open the explorer there,
    /// like the web's `/players/:id?season=…&type=…&venue=…` links.
    case player(id: String, season: String? = nil, seasonType: String? = nil, filters: ExplorerFilters? = nil)
    case team(id: Int, season: String? = nil, seasonType: String? = nil, filters: ExplorerFilters? = nil)
    case leaders(season: String?, seasonType: String?, stat: String?)
    case rankings(view: String?, season: String?, position: String?, sort: String?, scope: String?)
    case standings(season: String?, bracket: Bool)
    case props
    case ask
}

extension View {
    func appDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .game(let id):
                BoxScoreView(gameId: id)
            case .player(let id, let season, let seasonType, let filters):
                PlayerDetailView(playerId: id, season: season, seasonType: seasonType, filters: filters)
            case .team(let id, let season, let seasonType, let filters):
                TeamDetailView(teamId: id, season: season, seasonType: seasonType, filters: filters)
            case .leaders(let season, let seasonType, let stat):
                LeadersView(season: season, seasonType: seasonType, stat: stat)
            case .rankings(let view, let season, let position, let sort, let scope):
                RankingsView(view: view, season: season, position: position, sort: sort, scope: scope)
            case .standings(let season, let bracket):
                StandingsView(season: season, bracket: bracket)
            case .props:
                PropsBoardView()
            case .ask:
                AskView()
            }
        }
    }
}
