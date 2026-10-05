//
//  SyntheticCatalog.swift
//  EphemerisTests
//
//  A deterministic, realistic-looking satellite catalog for tests and benchmarks, so no
//  test ever needs to download data from a public server.
//

import Foundation
@testable import Ephemeris

/// SplitMix64: a tiny, fast, seedable random number generator. The same seed always
/// produces the same catalog, on every platform.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum SyntheticCatalog {

    /// The shape of one generated orbit
    private struct OrbitShape {
        let meanMotion: Double
        let eccentricity: Double
        let inclination: Double
        let bstar: Double
    }

    /// Epoch shared by the synthetic element sets (each is offset by up to two days)
    static let epoch = Date(timeIntervalSince1970: 1_790_000_000) // 2026-09-21

    /// Builds `count` OMM element sets with a mix of orbits similar to the public catalog:
    /// about 70% low Earth orbit (constellation shells, sun-synchronous, ISS-like, debris),
    /// 10% medium Earth orbit, 12% geosynchronous and 8% highly elliptical.
    static func elementSets(count: Int, seed: UInt64 = 42) -> [OrbitMeanElementsMessage] {
        // The generated values are always valid, so parsing cannot fail
        // swiftlint:disable:next force_try
        return fieldSets(count: count, seed: seed).map { try! OrbitMeanElementsMessage(fields: $0) }
    }

    /// The OMM keyword → value records behind `elementSets(count:seed:)`.
    static func fieldSets(count: Int, seed: UInt64 = 42) -> [[String: String]] {
        var rng = SeededGenerator(seed: seed)
        return (0..<count).map { index in
            let roll = Double.random(in: 0..<1, using: &rng)
            let orbit: OrbitShape
            switch roll {
            case ..<0.70:
                // Low Earth orbit: 300-1200 km altitude
                let altitude = Double.random(in: 300...1200, using: &rng)
                let inclinations = [53.0, 97.6, 51.6, 70.0, 87.9, 43.0, Double.random(in: 0...100, using: &rng)]
                orbit = OrbitShape(meanMotion: meanMotion(altitudeKm: altitude),
                                   eccentricity: Double.random(in: 0...0.01, using: &rng),
                                   inclination: inclinations.randomElement(using: &rng) ?? 53,
                                   bstar: Double.random(in: 1e-5...5e-4, using: &rng))
            case ..<0.80:
                // Medium Earth orbit: navigation constellations, 19,000-23,300 km
                let altitude = Double.random(in: 19_000...23_300, using: &rng)
                orbit = OrbitShape(meanMotion: meanMotion(altitudeKm: altitude),
                                   eccentricity: Double.random(in: 0...0.02, using: &rng),
                                   inclination: Double.random(in: 54...65, using: &rng), bstar: 0)
            case ..<0.92:
                // Geosynchronous: one revolution per sidereal day, small inclination
                orbit = OrbitShape(meanMotion: 1.0027 + Double.random(in: -0.002...0.002, using: &rng),
                                   eccentricity: Double.random(in: 0...0.001, using: &rng),
                                   inclination: Double.random(in: 0...6, using: &rng), bstar: 0)
            default:
                // Highly elliptical: Molniya (12 h, e 0.7) or transfer orbits
                let isMolniya = Bool.random(using: &rng)
                orbit = isMolniya
                    ? OrbitShape(meanMotion: 2.006, eccentricity: Double.random(in: 0.68...0.74, using: &rng),
                                 inclination: 63.4, bstar: 1e-4)
                    : OrbitShape(meanMotion: Double.random(in: 2.2...2.4, using: &rng),
                                 eccentricity: Double.random(in: 0.70...0.73, using: &rng),
                                 inclination: Double.random(in: 5...28, using: &rng), bstar: 1e-4)
            }

            let epoch = Self.epoch.addingTimeInterval(Double.random(in: 0...172_800, using: &rng))
            return [
                "OBJECT_NAME": "SYNTHETIC \(index)",
                "OBJECT_ID": String(format: "2020-%03d%@", index % 999 + 1, "A"),
                "EPOCH": epochText(epoch),
                "MEAN_MOTION": String(orbit.meanMotion),
                "ECCENTRICITY": String(orbit.eccentricity),
                "INCLINATION": String(orbit.inclination),
                "RA_OF_ASC_NODE": String(Double.random(in: 0..<360, using: &rng)),
                "ARG_OF_PERICENTER": String(Double.random(in: 0..<360, using: &rng)),
                "MEAN_ANOMALY": String(Double.random(in: 0..<360, using: &rng)),
                "NORAD_CAT_ID": String(100_000 + index),
                "BSTAR": String(orbit.bstar)
            ]
        }
    }

    /// Mean motion (rev/day) of a circular orbit at an altitude, from Kepler's third law.
    private static func meanMotion(altitudeKm: Double) -> Double {
        return KeplerianOrbit.meanMotion(semimajorAxis: PhysicalConstants.Earth.semiMajorAxis + altitudeKm)
    }

    /// An OMM epoch string with microseconds.
    private static func epochText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter.string(from: date)
    }
}
