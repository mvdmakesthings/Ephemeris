//
//  FetchedCatalog.swift
//  EphemerisCatalog
//

import Foundation
import Ephemeris

/// A catalog returned by `ElementSetClient`, with where it came from and how old it is.
///
/// Element sets age: SGP4 errors grow by roughly 1-3 km per day in low Earth orbit. Check
/// `source` and `fetchedAt` to decide whether the data is good enough for what you are doing.
public struct FetchedCatalog: Sendable {

    /// Where the catalog came from.
    public enum Source: Equatable, Sendable {
        /// Downloaded just now
        case network

        /// Read from the cache, which was still within the refresh interval
        case cache

        /// Read from an expired cache entry because refreshing it failed. The error says why;
        /// the client will try again later on its own.
        case staleCache(CatalogFetchError)
    }

    /// The satellites. Empty when the server had no data for the query.
    public let catalog: SatelliteCatalog

    /// When this data was downloaded from the server
    public let fetchedAt: Date

    /// Where the data came from on this call
    public let source: Source

    /// Creates a fetched catalog.
    public init(catalog: SatelliteCatalog, fetchedAt: Date, source: Source) {
        self.catalog = catalog
        self.fetchedAt = fetchedAt
        self.source = source
    }

    /// Seconds between the download and `date`.
    public func age(at date: Date) -> TimeInterval {
        return date.timeIntervalSince(fetchedAt)
    }

    /// The same data with a different source, used when a cached entry is handed back.
    func withSource(_ source: Source) -> FetchedCatalog {
        return FetchedCatalog(catalog: catalog, fetchedAt: fetchedAt, source: source)
    }
}
