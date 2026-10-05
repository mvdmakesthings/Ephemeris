//
//  MeanElementSet.swift
//  Ephemeris
//
//  The data shared by every format for publishing SGP4 orbits.
//

import Foundation

/// A set of SGP4 mean orbital elements, whatever text format it arrived in.
///
/// Space-Track and CelesTrak publish each satellite's orbit as a *General Perturbations
/// (GP) element set*: a handful of numbers fitted so that the SGP4 model reproduces the
/// satellite's observed motion. The same numbers can be written in two formats:
///
/// - **TLE** (`TwoLineElement`): the classic 69-column, two-line text format from the 1960s
/// - **OMM** (`OrbitMeanElementsMessage`): the international CCSDS standard, written as
///   JSON, XML, KVN or CSV, with named fields and room for larger catalog numbers
///
/// Both conform to this protocol, so `SGP4` and `KeplerianOrbit` accept either one.
///
/// ## Example
/// ```swift
/// let fromTLE = try SGP4(elements: try TwoLineElement(from: tleText))
/// let fromOMM = try SGP4(elements: try OrbitMeanElementsMessage.parse(ommJSON)[0])
/// ```
///
/// - Note: These are *mean* elements: averages defined by SGP4's theory, not the
///         instantaneous (osculating) orbit. Only SGP4 turns them back into accurate positions.
public protocol MeanElementSet: Sendable {

    // MARK: - Identification

    /// Common name of the object (may be empty)
    var name: String { get }

    /// NORAD satellite catalog number
    var catalogNumber: Int { get }

    // MARK: - Epoch

    /// The instant the elements describe (UTC)
    var epoch: Date { get }

    // MARK: - Orbital Elements

    /// Mean motion (revolutions per day)
    var meanMotion: Double { get }

    /// Eccentricity (0 ≤ e < 1)
    var eccentricity: Double { get }

    /// Inclination (degrees)
    var inclination: Degrees { get }

    /// Right ascension of the ascending node (degrees)
    var rightAscensionOfAscendingNode: Degrees { get }

    /// Argument of perigee (degrees)
    var argumentOfPerigee: Degrees { get }

    /// Mean anomaly at epoch (degrees)
    var meanAnomaly: Degrees { get }

    // MARK: - SGP4 Parameters

    /// B* drag term (1 / Earth radii)
    var bstarDragTerm: Double { get }

    /// Which theory the elements were fitted with. 0 means standard SGP4/SDP4; 4 means
    /// SGP4-XP, a newer model whose elements standard SGP4 cannot propagate.
    var ephemerisType: Int { get }
}
