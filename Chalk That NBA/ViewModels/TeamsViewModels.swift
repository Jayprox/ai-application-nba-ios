//
//  TeamsViewModels.swift
//  Chalk That NBA
//
//  Teams list (GET /teams) and team detail (GET /teams/:id + GET /seasons,
//  then the explorer, defense by position and the season roster), as in
//  the web's pages/Teams.jsx and pages/TeamDetail.jsx.
//
import Foundation
import Combine

@MainActor
final class TeamsViewModel: ObservableObject {
    @Published private(set) var teams: [Team] = []
    @Published private(set) var loaded = false
    @Published private(set) var error: Error?

    func load() async {
        error = nil
        do {
            let envelope: APIEnvelope<[Team], EmptyMeta> = try await APIClient.shared.get(Endpoints.teams)
            teams = envelope.data
            loaded = true
        } catch {
            if !Task.isCancelled { self.error = error }
        }
    }

    /// East then West; divisions alphabetical; teams in the API's order.
    var conferences: [(name: String, divisions: [(name: String, teams: [Team])])] {
        ["East", "West"].map { conf -> (name: String, divisions: [(name: String, teams: [Team])]) in
            let inConf = teams.filter { $0.conference == conf }
            let divisions = Set(inConf.compactMap(\.division)).sorted()
            let groups = divisions.map { d -> (name: String, teams: [Team]) in
                (name: d, teams: inConf.filter { $0.division == d })
            }
            return (name: "\(conf)ern Conference", divisions: groups)
        }
    }

    var altitudeCities: [String] {
        teams.filter { $0.isHighAltitude == true }.compactMap(\.city)
    }
}

@MainActor
final class TeamDetailViewModel: ObservableObject {
    let teamId: Int
    @Published private(set) var team: TeamDetail?
    @Published private(set) var seasons: [String] = []
    @Published private(set) var latestSeason: String?
    @Published private(set) var loaded = false
    @Published private(set) var error: Error?

    /// The explorer's current season and type; the sections below follow it.
    @Published var season: String?
    @Published var seasonType = "regular"

    init(teamId: Int) {
        self.teamId = teamId
    }

    func load() async {
        guard !loaded else { return }
        error = nil
        do {
            async let detail: APIEnvelope<TeamDetail, EmptyMeta> = APIClient.shared.get(Endpoints.team(teamId))
            async let seasonList: APIEnvelope<[SeasonRow], SeasonsMeta> = APIClient.shared.get(Endpoints.seasons)
            let (t, s) = try await (detail, seasonList)
            team = t.data
            seasons = s.data.map(\.season)
            latestSeason = s.meta?.latestWithGames
            loaded = true
        } catch {
            if !Task.isCancelled { self.error = error }
        }
    }
}

/// "Defense by position": this team's row for G / F / C from
/// GET /rankings/matchups. Regular season unless the explorer is on
/// playoffs (the endpoint only takes regular / playoffs / all).
@MainActor
final class DefenseByPositionViewModel: ObservableObject {
    struct Key: Hashable { let season: String; let seasonType: String }

    @Published private(set) var rows: [(position: String, title: String, row: MatchupRow)] = []
    @Published private(set) var teamCount = 30
    @Published private(set) var loadedKey: Key?
    @Published private(set) var error: Error?

    func load(teamId: Int, key: Key) async {
        error = nil
        do {
            let envelope: MatchupsData = try await APIClient.shared.get(Endpoints.matchups(season: key.season, seasonType: key.seasonType))
            guard !Task.isCancelled else { return }
            let titles = ["G": "Guards", "F": "Forwards", "C": "Centers"]
            rows = ["G", "F", "C"].compactMap { pos in
                envelope.data[pos]?.first { $0.teamId == teamId }.map { row -> (position: String, title: String, row: MatchupRow) in
                    (position: pos, title: titles[pos] ?? pos, row: row)
                }
            }
            teamCount = envelope.data["G"]?.count ?? 30
            loadedKey = key
        } catch {
            if !Task.isCancelled { self.error = error }
        }
    }
}

@MainActor
final class TeamRosterViewModel: ObservableObject {
    struct Key: Hashable { let season: String; let seasonType: String }

    @Published private(set) var players: [TeamSeasonPlayer] = []
    @Published private(set) var loadedKey: Key?
    @Published private(set) var error: Error?

    func load(teamId: Int, key: Key) async {
        error = nil
        do {
            let envelope: APIEnvelope<[TeamSeasonPlayer], EmptyMeta> = try await APIClient.shared.get(
                Endpoints.teamPlayers(teamId, season: key.season, seasonType: key.seasonType))
            guard !Task.isCancelled else { return }
            players = envelope.data
            loadedKey = key
        } catch {
            if !Task.isCancelled { self.error = error }
        }
    }
}
