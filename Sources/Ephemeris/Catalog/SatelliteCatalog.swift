//
//  SatelliteCatalog.swift
//  Ephemeris
//
//  A collection of satellites loaded from TLE or OMM documents, with lookup and filters.
//

import Foundation

/// An element set that was left out of a `SatelliteCatalog`, and why.
public struct CatalogRejection: Sendable {
    /// Why an element set was left out
    public enum Reason: Error, Equatable, Sendable {
        /// The TLE text could not be parsed
        case invalidTLE(TLEParsingError)
        /// The OMM record could not be parsed
        case invalidOMM(OMMParsingError)
        /// SGP4 cannot use the elements (decayed, invalid, or SGP4-XP)
        case cannotPropagate(SGP4Error)
        /// A newer element set for the same catalog number was also present
        case superseded(byEpoch: Date)
    }

    /// The satellite's name, when it could be read
    public let name: String?

    /// The catalog number, when it could be read
    public let catalogNumber: Int?

    /// Why the element set was left out
    public let reason: Reason
}

/// A collection of satellites, ready to propagate together.
///
/// Load it from a TLE document (such as a downloaded group file), an OMM document in any
/// encoding, or element sets you already have. Each satellite gets its own `SGP4`
/// propagator, and whole-catalog questions ("where is everything?", "what is overhead?",
/// "what passes over me tonight?") run concurrently across all CPU cores.
///
/// Element sets that cannot be used are not fatal: they are listed in `rejections` with a
/// reason, and the rest of the catalog loads normally.
///
/// ## Example
/// ```swift
/// let catalog = try SatelliteCatalog(omm: ommJSON)
/// print("\(catalog.satellites.count) satellites, \(catalog.rejections.count) rejected")
///
/// let overhead = await catalog.lookAngles(from: observer, at: Date(), minElevationDeg: 10)
/// for item in overhead {
///     print(item.satellite.name, item.topocentric.elevationDeg)
/// }
/// ```
///
/// - Note: The catalog works only with data you give it; it never downloads anything.
public struct SatelliteCatalog: Sendable {

    // MARK: - Properties

    /// The usable satellites, ordered by catalog number
    public let satellites: [CatalogSatellite]

    /// Element sets that were left out, with the reason for each
    public let rejections: [CatalogRejection]

    /// Position of each catalog number in `satellites`
    private let indexByCatalogNumber: [Int: Int]

    // MARK: - Initialization

    /// Builds a catalog from element sets you already have.
    ///
    /// When the same catalog number appears more than once, the element set with the latest
    /// epoch is kept and the others are listed as superseded.
    ///
    /// - Parameters:
    ///   - elementSets: TLEs, OMMs, or any other `MeanElementSet`
    ///   - gravity: Gravity constants for SGP4 (default `.wgs72`)
    public init(elementSets: [any MeanElementSet], gravity: GravityModel = .wgs72) {
        self.init(elementSets: elementSets, gravity: gravity, earlierRejections: [])
    }

    /// Builds a catalog from a document of TLEs, such as a downloaded group file.
    ///
    /// - Parameters:
    ///   - tleText: Any number of TLEs, with or without name lines
    ///   - gravity: Gravity constants for SGP4 (default `.wgs72`)
    public init(tleText: String, gravity: GravityModel = .wgs72) {
        var elementSets: [any MeanElementSet] = []
        var rejections: [CatalogRejection] = []
        for result in TwoLineElement.parseEach(tleText) {
            switch result {
            case .success(let tle):
                elementSets.append(tle)
            case .failure(let error):
                rejections.append(CatalogRejection(name: nil, catalogNumber: nil, reason: .invalidTLE(error)))
            }
        }
        self.init(elementSets: elementSets, gravity: gravity, earlierRejections: rejections)
    }

    /// Builds a catalog from an OMM document in any encoding.
    ///
    /// - Parameters:
    ///   - omm: The document (JSON, XML, KVN or CSV)
    ///   - format: The encoding, or `nil` to detect it
    ///   - gravity: Gravity constants for SGP4 (default `.wgs72`)
    /// - Throws: `OMMParsingError` only if the document as a whole cannot be read; invalid
    ///           individual records become rejections
    public init(omm: String, format: OrbitMeanElementsMessage.Format? = nil, gravity: GravityModel = .wgs72) throws {
        var elementSets: [any MeanElementSet] = []
        var rejections: [CatalogRejection] = []
        for result in try OrbitMeanElementsMessage.parseEach(omm, format: format) {
            switch result {
            case .success(let message):
                elementSets.append(message)
            case .failure(let error):
                rejections.append(CatalogRejection(name: nil, catalogNumber: nil, reason: .invalidOMM(error)))
            }
        }
        self.init(elementSets: elementSets, gravity: gravity, earlierRejections: rejections)
    }

    /// Builds a catalog from UTF-8 OMM data in any encoding, such as a GP server download.
    ///
    /// - Parameters:
    ///   - ommData: The document
    ///   - format: The encoding, or `nil` to detect it
    ///   - gravity: Gravity constants for SGP4 (default `.wgs72`)
    /// - Throws: `OMMParsingError` if the document as a whole cannot be read
    public init(ommData: Data, format: OrbitMeanElementsMessage.Format? = nil, gravity: GravityModel = .wgs72) throws {
        guard let text = String(data: ommData, encoding: .utf8) else {
            throw OMMParsingError.invalidFormat("document is not UTF-8 text")
        }
        try self.init(omm: text, format: format, gravity: gravity)
    }

    /// Shared builder: keeps the newest element set per catalog number and builds propagators.
    private init(elementSets: [any MeanElementSet], gravity: GravityModel, earlierRejections: [CatalogRejection]) {
        var rejections = earlierRejections

        // Newest element set wins for each catalog number
        var newest: [Int: any MeanElementSet] = [:]
        for elements in elementSets {
            let key = elements.catalogNumber
            if let existing = newest[key] {
                let (kept, dropped) = elements.epoch > existing.epoch ? (elements, existing) : (existing, elements)
                newest[key] = kept
                rejections.append(CatalogRejection(name: dropped.name, catalogNumber: key,
                                            reason: .superseded(byEpoch: kept.epoch)))
            } else {
                newest[key] = elements
            }
        }

        // Build a propagator for each; SGP4 checks the elements at epoch
        var satellites: [CatalogSatellite] = []
        for key in newest.keys.sorted() {
            guard let elements = newest[key] else { continue }
            do {
                satellites.append(try CatalogSatellite(elements: elements, gravity: gravity))
            } catch let error as SGP4Error {
                rejections.append(CatalogRejection(name: elements.name, catalogNumber: key, reason: .cannotPropagate(error)))
            } catch {
                // SGP4's initializer only throws SGP4Error
                continue
            }
        }
        self.init(satellites: satellites, rejections: rejections)
    }

    /// Wraps an already-built list of satellites.
    private init(satellites: [CatalogSatellite], rejections: [CatalogRejection]) {
        self.satellites = satellites
        self.rejections = rejections
        self.indexByCatalogNumber = Dictionary(uniqueKeysWithValues: satellites.enumerated().map { ($1.catalogNumber, $0) })
    }

    // MARK: - Lookup

    /// The satellite with a NORAD catalog number, if present.
    ///
    /// ```swift
    /// let iss = catalog[catalogNumber: 25544]
    /// ```
    public subscript(catalogNumber catalogNumber: Int) -> CatalogSatellite? {
        guard let index = indexByCatalogNumber[catalogNumber] else { return nil }
        return satellites[index]
    }

    /// The satellite with an international (COSPAR) designator, in either the "1998-067A"
    /// or the TLE "98067A" form.
    public func satellite(internationalDesignator designator: String) -> CatalogSatellite? {
        guard let wanted = CatalogSatellite.cosparForm(designator) else { return nil }
        return satellites.first { $0.internationalDesignator == wanted }
    }

    /// Satellites whose name contains the text, ignoring case and diacritics.
    ///
    /// ```swift
    /// let stations = catalog.satellites(named: "iss")
    /// ```
    public func satellites(named text: String) -> [CatalogSatellite] {
        return satellites.filter { $0.name.range(of: text, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    // MARK: - Filters

    /// A catalog containing only the satellites that match a condition. Rejections are kept.
    ///
    /// ```swift
    /// let geostationary = catalog.filter { $0.regime == .geosynchronous }
    /// ```
    public func filter(_ isIncluded: (CatalogSatellite) throws -> Bool) rethrows -> SatelliteCatalog {
        return SatelliteCatalog(satellites: try satellites.filter(isIncluded), rejections: rejections)
    }

    /// A catalog without satellites whose element sets are older than a limit.
    ///
    /// Predictions degrade by roughly 1-3 km per day of element-set age in low Earth orbit;
    /// for antenna pointing, a few days is a sensible limit.
    ///
    /// - Parameters:
    ///   - maximumAge: Oldest acceptable element set, in seconds
    ///   - date: The time the age is measured at
    public func excludingStale(olderThan maximumAge: TimeInterval, at date: Date) -> SatelliteCatalog {
        return filter { $0.age(at: date) <= maximumAge }
    }
}
