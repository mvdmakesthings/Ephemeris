//
//  CatalogFetchError.swift
//  EphemerisCatalog
//

import Foundation

/// Why a request to an element-set server could not produce a catalog.
public enum CatalogFetchError: Error, Equatable, Sendable {

    /// The query was rejected before sending (bad catalog number, designator or name)
    case invalidQuery(String)

    /// The server refused the request because of request volume (HTTP 403 or 429).
    /// Every request is paused until the given time, including after an app relaunch.
    case rateLimited(until: Date)

    /// An earlier request for this query failed, and the client is waiting before trying
    /// again so a failing request is not repeated in a loop.
    case backingOff(until: Date)

    /// The server answered with an unexpected HTTP status
    case httpStatus(Int)

    /// The response was not an OMM document or a recognized "no data" message
    case invalidResponse(String)

    /// The request did not complete (no connection, timeout, TLS failure)
    case transport(String)

    /// No cached copy exists, and `cachedCatalog(for:)` never goes to the network
    case notCached
}
