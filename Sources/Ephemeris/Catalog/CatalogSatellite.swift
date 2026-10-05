//
//  CatalogSatellite.swift
//  Ephemeris
//
//  One satellite in a SatelliteCatalog: its element set, a ready-to-use SGP4 propagator,
//  and orbit facts derived once from the elements.
//

import Foundation

/// The broad class of an orbit, from its size and shape.
public enum OrbitRegime: String, CaseIterable, Sendable {
    /// Apogee below 2,000 km: the ISS, Starlink, weather and Earth-imaging satellites
    case lowEarth
    /// Between low Earth orbit and geosynchronous: GPS, Galileo, GLONASS
    case mediumEarth
    /// About one revolution per sidereal day: geostationary and inclined geosynchronous
    case geosynchronous
    /// Eccentricity of 0.25 or more: Molniya, Tundra, transfer orbits
    case highlyElliptical
    /// Near-circular and above geosynchronous altitude: graveyard orbits, high science missions
    case highEarth
}

/// A satellite in a `SatelliteCatalog`.
///
/// Holds the element set it was loaded from and an `SGP4` propagator built from it, so
/// every `Propagator` feature (position, look angles, passes, tracks) is available
/// through `propagator`.
///
/// ## Example
/// ```swift
/// if let iss = catalog[25544] {
///     print(iss.name, iss.regime, iss.age(at: Date()) / 3600, "hours old")
///     let lookAngles = try iss.propagator.topocentric(at: Date(), for: observer)
/// }
/// ```
public struct CatalogSatellite: Identifiable, Sendable {

    // MARK: - Properties

    /// The element set this satellite was loaded from (`TwoLineElement` or `OrbitMeanElementsMessage`)
    public let elements: any MeanElementSet

    /// SGP4 propagator for the element set
    public let propagator: SGP4

    /// NORAD catalog number (also the `id`)
    public var id: Int { elements.catalogNumber }

    /// NORAD catalog number
    public var catalogNumber: Int { elements.catalogNumber }

    /// Common name, which may be empty
    public var name: String { elements.name }

    /// International (COSPAR) designator in the "1998-067A" form, or `nil` if the element
    /// set has none. TLE designators ("98067A") are converted to this form.
    public let internationalDesignator: String?

    /// Broad orbit class
    public let regime: OrbitRegime

    /// Perigee distance from Earth's center (km)
    public let perigeeRadiusKm: Double

    /// Apogee distance from Earth's center (km)
    public let apogeeRadiusKm: Double

    // MARK: - Initialization

    /// Creates a catalog entry and its SGP4 propagator.
    ///
    /// - Parameters:
    ///   - elements: The satellite's element set
    ///   - gravity: Gravity constants for SGP4 (default `.wgs72`)
    /// - Throws: `SGP4Error` if SGP4 cannot use the elements
    public init(elements: any MeanElementSet, gravity: GravityModel = .wgs72) throws {
        self.elements = elements
        self.propagator = try SGP4(elements: elements, gravity: gravity)
        self.internationalDesignator = Self.cosparDesignator(for: elements)

        // Size of the orbit from Kepler's third law: a = (μ / n²)^(1/3), n in rad/s
        let semimajorAxis = KeplerianOrbit.semimajorAxis(meanMotion: elements.meanMotion)
        self.perigeeRadiusKm = semimajorAxis * (1 - elements.eccentricity)
        self.apogeeRadiusKm = semimajorAxis * (1 + elements.eccentricity)
        self.regime = Self.regime(meanMotion: elements.meanMotion, eccentricity: elements.eccentricity,
                                  apogeeAltitudeKm: apogeeRadiusKm - PhysicalConstants.Earth.semiMajorAxis)
    }

    // MARK: - Data Freshness

    /// How old the element set is at a given time (seconds; negative if the time is before
    /// the epoch).
    ///
    /// SGP4 error grows with distance from the epoch, roughly 1-3 km per day in low Earth
    /// orbit, so age is the best single indicator of how far to trust a prediction.
    ///
    /// - Parameter date: The time of interest
    /// - Returns: Seconds from the element set's epoch to `date`
    public func age(at date: Date) -> TimeInterval {
        return date.timeIntervalSince(elements.epoch)
    }

    // MARK: - Visibility

    /// Whether this satellite can ever rise above an elevation for an observer at a
    /// given latitude, judged from the orbit's geometry alone.
    ///
    /// A satellite's ground track never goes farther from the equator than its inclination
    /// `i` (or 180° − `i` for retrograde orbits). From altitude `h`, it can be seen above
    /// elevation `ε` from anywhere within an Earth central angle `λ` of the point beneath it:
    /// ```
    /// λ = arccos(R⊕·cos ε / (R⊕ + h)) − ε
    /// ```
    /// So an observer at latitude `φ` can only see it if `|φ| ≤ i + λ`, with `h` at apogee
    /// for the widest reach.
    ///
    /// The test is conservative: it uses the polar radius (which gives the largest `λ`) and
    /// adds a 1° margin for geodetic vs. geocentric latitude, element variations and observer
    /// height. It never rejects a satellite that can rise; it only skips ones that can't.
    ///
    /// - Parameters:
    ///   - latitudeDeg: Observer's geodetic latitude in degrees
    ///   - minElevationDeg: Elevation that counts as visible
    /// - Returns: `false` only if the satellite can never reach that elevation for the observer
    ///
    /// - Note: Reference: Wertz, "Space Mission Analysis and Design" (3rd ed.), Section 5.2
    public func canRise(forLatitudeDeg latitudeDeg: Degrees, minElevationDeg: Degrees) -> Bool {
        // Below the horizon the visibility circle keeps growing; don't try to bound it
        guard minElevationDeg >= 0 else { return true }

        let polarRadius = 6356.752   // km; smallest Earth radius, largest visibility circle
        let marginDeg = 1.0

        // Earth central angle of the visibility circle at apogee, in degrees
        let elevation = minElevationDeg.inRadians()
        let ratio = polarRadius * cos(elevation) / max(apogeeRadiusKm, polarRadius)
        let reachDeg = (acos(min(ratio, 1)) - elevation).inDegrees()

        // Highest latitude the ground track reaches
        let inclination = elements.inclination
        let maxGroundTrackLatitude = inclination <= 90 ? inclination : 180 - inclination

        return abs(latitudeDeg) <= maxGroundTrackLatitude + reachDeg + marginDeg
    }

    // MARK: - Helpers

    /// Classifies an orbit by its shape and size.
    static func regime(meanMotion: Double, eccentricity: Double, apogeeAltitudeKm: Double) -> OrbitRegime {
        if eccentricity >= 0.25 {
            return .highlyElliptical
        }
        if apogeeAltitudeKm < 2000 {
            return .lowEarth
        }
        // One revolution per sidereal day is 1.0027 rev/day
        if abs(meanMotion - 1.0027) < 0.05 {
            return .geosynchronous
        }
        return meanMotion > 1.0027 ? .mediumEarth : .highEarth
    }

    /// The COSPAR form ("1998-067A") of an element set's international designator.
    static func cosparDesignator(for elements: any MeanElementSet) -> String? {
        switch elements {
        case let tle as TwoLineElement:
            return cosparForm(tle.internationalDesignator)
        case let omm as OrbitMeanElementsMessage:
            return cosparForm(omm.internationalDesignator)
        default:
            return nil
        }
    }

    /// Converts an international designator to the COSPAR form "1998-067A".
    ///
    /// OMM already uses this form. TLEs use a compressed "98067A" (2-digit year, 3-digit
    /// launch number, piece), with the same 1957 century pivot as TLE epochs.
    ///
    /// - Parameter designator: "1998-067A" or "98067A"
    /// - Returns: The COSPAR form, or `nil` for an empty designator
    static func cosparForm(_ designator: String) -> String? {
        let trimmed = designator.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        guard !trimmed.contains("-"), trimmed.count >= 5, let year = Int(trimmed.prefix(2)) else {
            return trimmed
        }
        return "\(TwoLineElement.parse2DigitYear(year))-\(trimmed.dropFirst(2))"
    }
}
