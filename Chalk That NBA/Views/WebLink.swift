//
//  WebLink.swift
//  Chalk That NBA
//
//  Maps a web-app path (POST /ask's `link`, and later universal links) to
//  the matching native screen, carrying the web's URL state:
//    /players/:id?season=&type=&scope=&restby=&venue=&b2b=&rest=&tv=&alt=
//    /teams/:id?…same…
//    /games/:id
//    /leaders?season=&type=&stat=
//    /rankings?view=&season=&pos=&sort=&scope=
//    /standings?season=&view=bracket
//    /props
//  Unknown paths return nil (the link is simply not shown).
//
import Foundation

enum WebLink {
    static func route(_ link: String?) -> AppRoute? {
        guard let link, let components = URLComponents(string: "https://chalkthat.invalid" + link) else { return nil }
        var q: [String: String] = [:]
        for item in components.queryItems ?? [] { if let v = item.value { q[item.name] = v } }
        let parts = components.path.split(separator: "/").map(String.init)
        guard let first = parts.first else { return nil }

        switch (first, parts.count) {
        case ("players", 2):
            return .player(id: parts[1], filters: ExplorerFilters.fromWebQuery(q))
        case ("teams", 2):
            guard let id = Int(parts[1]) else { return nil }
            return .team(id: id, filters: ExplorerFilters.fromWebQuery(q))
        case ("games", 2):
            return .game(id: parts[1])
        case ("leaders", 1):
            return .leaders(season: q["season"], seasonType: q["type"], stat: q["stat"])
        case ("rankings", 1):
            return .rankings(view: q["view"], season: q["season"], position: q["pos"], sort: q["sort"], scope: q["scope"])
        case ("standings", 1):
            return .standings(season: q["season"], bracket: q["view"] == "bracket")
        case ("props", 1):
            return .props
        default:
            return nil
        }
    }
}
