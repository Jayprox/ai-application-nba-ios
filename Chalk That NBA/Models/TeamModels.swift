//
//  TeamModels.swift
//  Chalk That NBA
//
//  GET /teams (api.md §4): all 30, ordered by conference, division, name.
//  Team detail (GET /teams/:id) arrives in step 4.
//
import Foundation

struct Team: Decodable, Identifiable, Hashable {
    let id: Int
    let abbreviation: String
    let city: String?
    let name: String?
    let fullName: String
    let conference: String?
    let division: String?
    let arena: String?
    let arenaCity: String?
    let elevationFt: Int?
    let isHighAltitude: Bool?
}
