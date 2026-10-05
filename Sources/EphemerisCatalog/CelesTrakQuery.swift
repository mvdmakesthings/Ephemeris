//
//  CelesTrakQuery.swift
//  EphemerisCatalog
//
//  What to ask CelesTrak for, and how that becomes a request URL and a cache file name.
//

import Foundation

/// A request for element sets from CelesTrak's GP (general perturbations) API.
///
/// CelesTrak serves the public catalog at `https://celestrak.org/NORAD/elements/gp.php`
/// with one query parameter that picks the satellites and `FORMAT` that picks the encoding.
/// `CelesTrakClient` always asks for OMM in JSON, the format CelesTrak recommends, because it
/// has no catalog-number limit and a full-precision epoch (see `docs/element-sets.md`).
///
/// ## Which Query to Use
/// - `.group`: the normal choice. One request returns a whole set such as every active
///   satellite or every amateur radio satellite.
/// - `.catalogNumber`: one satellite that is not in a group you already have, such as an
///   object launched yesterday. `CelesTrakClient` answers it from a cached group when it can.
/// - `.internationalDesignator`: every object from one launch (`"2024-123"`).
/// - `.name`: every satellite whose name contains the text.
///
/// ## Example
/// ```swift
/// let amateur = try await client.catalog(for: .group(.amateur))
/// let newCubeSat = try await client.catalog(for: .catalogNumber(61000))
/// ```
public enum CelesTrakQuery: Hashable, Sendable {

    /// A named group of satellites, such as `.active` or `.amateur`
    case group(CelesTrakGroup)

    /// One satellite by NORAD catalog number (1 to 999,999,999)
    case catalogNumber(Int)

    /// Every object from one launch, by launch designator in `YYYY-NNN` form (`"1998-067"`)
    case internationalDesignator(String)

    /// Every satellite whose name contains the text (CelesTrak matches without regard to case)
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
    /// - Throws: `CelesTrakError.invalidQuery` describing the problem
    func validate() throws {
        switch self {
        case .group(let group):
            // Group names are short lowercase words with hyphens ("last-30-days")
            let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
            guard !group.rawValue.isEmpty, group.rawValue.unicodeScalars.allSatisfy(allowed.contains) else {
                throw CelesTrakError.invalidQuery("Group name \"\(group.rawValue)\" must be letters, digits and hyphens")
            }
        case .catalogNumber(let number):
            guard (1...999_999_999).contains(number) else {
                throw CelesTrakError.invalidQuery("Catalog number \(number) is out of range")
            }
        case .internationalDesignator(let designator):
            // Launch year, hyphen, launch number of the year: "1998-067"
            guard designator.range(of: #"^\d{4}-\d{3}$"#, options: .regularExpression) != nil else {
                throw CelesTrakError.invalidQuery("International designator \"\(designator)\" must look like 1998-067")
            }
        case .name(let text):
            // A one- or two-letter name matches a large part of the catalog; use a group instead
            guard text.trimmingCharacters(in: .whitespaces).count >= 3 else {
                throw CelesTrakError.invalidQuery("Name searches need at least 3 characters")
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

/// A CelesTrak satellite group, as used in `GROUP=` queries.
///
/// The common groups are provided as constants. Any other group from CelesTrak's
/// "Current GP Element Sets" page works too, as a string literal: `.group("iridium-NEXT")`.
public struct CelesTrakGroup: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {

    /// The group name exactly as CelesTrak spells it
    public let rawValue: String

    /// Creates a group from its CelesTrak name.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a group from a string literal, such as `"iridium-NEXT"`.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Every active satellite (about 10,000 or more). The largest download; fetch it rarely.
    public static let active: CelesTrakGroup = "active"

    /// Space stations (ISS, Tiangong) and the vehicles visiting them
    public static let stations: CelesTrakGroup = "stations"

    /// The brightest satellites, easy to see with the naked eye
    public static let visual: CelesTrakGroup = "visual"

    /// Objects launched in the last 30 days
    public static let lastThirtyDays: CelesTrakGroup = "last-30-days"

    /// Amateur radio satellites
    public static let amateur: CelesTrakGroup = "amateur"

    /// Satellites tracked by the SatNOGS ground station network
    public static let satnogs: CelesTrakGroup = "satnogs"

    /// Weather satellites
    public static let weather: CelesTrakGroup = "weather"

    /// NOAA polar-orbiting weather satellites (APT and HRPT downlinks)
    public static let noaa: CelesTrakGroup = "noaa"

    /// GOES geostationary weather satellites
    public static let goes: CelesTrakGroup = "goes"

    /// CubeSats
    public static let cubesat: CelesTrakGroup = "cubesat"

    /// All navigation satellites (GPS, GLONASS, Galileo, BeiDou and others)
    public static let gnss: CelesTrakGroup = "gnss"

    /// Operational GPS satellites
    public static let gpsOperational: CelesTrakGroup = "gps-ops"

    /// Active geosynchronous satellites
    public static let geosynchronous: CelesTrakGroup = "geo"

    /// Starlink (several thousand satellites)
    public static let starlink: CelesTrakGroup = "starlink"
}
