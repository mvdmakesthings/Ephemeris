//
//  ElementSetQuery.swift
//  EphemerisCatalog
//
//  What to ask an element-set server for, and how that becomes a request URL and a cache file name.
//

import Foundation

/// A request for element sets from a GP (general perturbations) data server.
///
/// GP servers take one query parameter that picks the satellites and `FORMAT` that picks the
/// encoding. `ElementSetClient` always asks for OMM in JSON, because it has no catalog-number
/// limit and a full-precision epoch (see `docs/element-sets.md`).
///
/// ## Which Query to Use
/// - `.group`: the normal choice. One request returns a whole set such as every active
///   satellite or every amateur radio satellite.
/// - `.catalogNumber`: one satellite that is not in a group you already have, such as an
///   object launched yesterday. `ElementSetClient` answers it from a cached group when it can.
/// - `.internationalDesignator`: every object from one launch (`"2024-123"`).
/// - `.name`: every satellite whose name contains the text.
///
/// ## Example
/// ```swift
/// let amateur = try await client.catalog(for: .group(.amateur))
/// let newCubeSat = try await client.catalog(for: .catalogNumber(61000))
/// ```
public enum ElementSetQuery: Hashable, Sendable {

    /// A named group of satellites, such as `.active` or `.amateur`
    case group(SatelliteGroup)

    /// One satellite by NORAD catalog number (1 to 999,999,999)
    case catalogNumber(Int)

    /// Every object from one launch, by launch designator in `YYYY-NNN` form (`"1998-067"`)
    case internationalDesignator(String)

    /// Every satellite whose name contains the text (servers match without regard to case)
    case name(String)

    // MARK: - Request

    /// The `gp.php` query parameter for this query, for example `GROUP=amateur`.
    var queryItem: URLQueryItem {
        switch self {
        case .group(let group):
            return URLQueryItem(name: "GROUP", value: group.rawValue)
        case .catalogNumber(let number):
            return URLQueryItem(name: "CATNR", value: String(number))
        case .internationalDesignator(let designator):
            return URLQueryItem(name: "INTDES", value: designator)
        case .name(let text):
            return URLQueryItem(name: "NAME", value: text.trimmingCharacters(in: .whitespaces))
        }
    }

    /// Checks the query before anything is sent, so a typo never becomes a request.
    ///
    /// - Throws: `CatalogFetchError.invalidQuery` describing the problem
    func validate() throws {
        switch self {
        case .group(let group):
            // Group names are short lowercase words with hyphens ("last-30-days")
            let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
            guard !group.rawValue.isEmpty, group.rawValue.unicodeScalars.allSatisfy(allowed.contains) else {
                throw CatalogFetchError.invalidQuery("Group name \"\(group.rawValue)\" must be letters, digits and hyphens")
            }
        case .catalogNumber(let number):
            guard (1...999_999_999).contains(number) else {
                throw CatalogFetchError.invalidQuery("Catalog number \(number) is out of range")
            }
        case .internationalDesignator(let designator):
            // Launch year, hyphen, launch number of the year: "1998-067"
            guard designator.range(of: #"^\d{4}-\d{3}$"#, options: .regularExpression) != nil else {
                throw CatalogFetchError.invalidQuery("International designator \"\(designator)\" must look like 1998-067")
            }
        case .name(let text):
            // A one- or two-letter name matches a large part of the catalog; use a group instead
            guard text.trimmingCharacters(in: .whitespaces).count >= 3 else {
                throw CatalogFetchError.invalidQuery("Name searches need at least 3 characters")
            }
        }
    }

    // MARK: - Cache Key

    /// A file-system-safe name for this query's cache entry, such as `group-amateur` or
    /// `catnr-25544`. Name searches are hex-encoded so any text makes a valid file name.
    var cacheKey: String {
        switch self {
        case .group(let group):
            return "group-\(group.rawValue.lowercased())"
        case .catalogNumber(let number):
            return "catnr-\(number)"
        case .internationalDesignator(let designator):
            return "intdes-\(designator)"
        case .name(let text):
            let normalized = text.trimmingCharacters(in: .whitespaces).uppercased()
            return "name-" + normalized.utf8.map { String(format: "%02x", $0) }.joined()
        }
    }
}

// MARK: - Groups

/// A named group of satellites, as used in `GROUP=` queries.
///
/// The constants below are group names in common use by public GP servers. Group names are
/// chosen by each server, so check your provider's list; any other name works as a string
/// literal: `.group("iridium-NEXT")`.
public struct SatelliteGroup: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {

    /// The group name exactly as the server spells it
    public let rawValue: String

    /// Creates a group from the server's name for it.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a group from a string literal, such as `"iridium-NEXT"`.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Every active satellite (about 10,000 or more). The largest download; fetch it rarely.
    public static let active: SatelliteGroup = "active"

    /// Space stations (ISS, Tiangong) and the vehicles visiting them
    public static let stations: SatelliteGroup = "stations"

    /// The brightest satellites, easy to see with the naked eye
    public static let visual: SatelliteGroup = "visual"

    /// Objects launched in the last 30 days
    public static let lastThirtyDays: SatelliteGroup = "last-30-days"

    /// Amateur radio satellites
    public static let amateur: SatelliteGroup = "amateur"

    /// Satellites tracked by the SatNOGS ground station network
    public static let satnogs: SatelliteGroup = "satnogs"

    /// Weather satellites
    public static let weather: SatelliteGroup = "weather"

    /// NOAA polar-orbiting weather satellites (APT and HRPT downlinks)
    public static let noaa: SatelliteGroup = "noaa"

    /// GOES geostationary weather satellites
    public static let goes: SatelliteGroup = "goes"

    /// CubeSats
    public static let cubesat: SatelliteGroup = "cubesat"

    /// All navigation satellites (GPS, GLONASS, Galileo, BeiDou and others)
    public static let gnss: SatelliteGroup = "gnss"

    /// Operational GPS satellites
    public static let gpsOperational: SatelliteGroup = "gps-ops"

    /// Active geosynchronous satellites
    public static let geosynchronous: SatelliteGroup = "geo"

    /// Starlink (several thousand satellites)
    public static let starlink: SatelliteGroup = "starlink"
}
