//
//  APIEnvelope.swift
//  Chalk That NBA
//
//  Most endpoints return `{ data, meta }` (api.md §1). `meta` differs per
//  route (sample_size, notes, freshness, prev/next dates...), and those
//  values must be SHOWN, so each screen decodes its own Meta type:
//  `APIEnvelope<[Game], GamesMeta>`. `EmptyMeta` is for routes whose meta
//  the UI doesn't use.
//
import Foundation

struct APIEnvelope<T: Decodable, Meta: Decodable>: Decodable {
    let data: T
    let meta: Meta?
}

struct EmptyMeta: Decodable {}
