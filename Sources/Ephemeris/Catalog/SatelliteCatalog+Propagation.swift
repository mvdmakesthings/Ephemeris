//
//  SatelliteCatalog+Propagation.swift
//  Ephemeris
//
//  Whole-catalog questions, computed concurrently: where is everything, what is
//  overhead, and what passes over an observer.
//

import Foundation

// MARK: - Result Types

/// A catalog satellite's inertial state at an instant.
public struct SatelliteState: Sendable {
    /// The satellite
    public let satellite: CatalogSatellite
    /// Position (km) and velocity (km/s) in the TEME frame
    public let state: StateVector
}

/// A catalog satellite's geodetic position at an instant.
public struct SatellitePosition: Sendable {
    /// The satellite
    public let satellite: CatalogSatellite
    /// Latitude, longitude and altitude above the WGS-84 ellipsoid
    public let position: GeodeticPosition
}

/// Where a catalog satellite appears from an observer at an instant.
public struct SatelliteLookAngles: Sendable {
    /// The satellite
    public let satellite: CatalogSatellite
    /// Azimuth, elevation, range and range rate
    public let topocentric: Topocentric
}

/// One pass of a catalog satellite over an observer.
public struct SatellitePass: Sendable {
    /// The satellite
    public let satellite: CatalogSatellite
    /// Rise, culmination and set
    public let pass: PassWindow
}

// MARK: - Whole-Catalog Queries

extension SatelliteCatalog {
    /// Every satellite's TEME state vector at an instant.
    ///
    /// - Parameter date: The instant
    /// - Returns: One state per satellite, in catalog order. Satellites SGP4 cannot propagate
    ///            to `date` (for example, decayed by then) are left out.
    public func stateVectors(at date: Date) async -> [SatelliteState] {
        await concurrentCompactMap { satellite in
            (try? satellite.propagator.stateVector(at: date)).map { SatelliteState(satellite: satellite, state: $0) }
        }
    }

    /// Every satellite's latitude, longitude and altitude at an instant, for drawing a map.
    ///
    /// - Parameter date: The instant
    /// - Returns: One position per satellite, in catalog order. Satellites SGP4 cannot
    ///            propagate to `date` are left out.
    public func positions(at date: Date) async -> [SatellitePosition] {
        await concurrentCompactMap { satellite in
            (try? satellite.propagator.calculatePosition(at: date)).map { SatellitePosition(satellite: satellite, position: $0) }
        }
    }

    /// What is above an observer's horizon at an instant.
    ///
    /// - Parameters:
    ///   - observer: The observer's location
    ///   - date: The instant
    ///   - minElevationDeg: Lowest elevation to include (default 0°, the geometric horizon)
    /// - Returns: Satellites at or above `minElevationDeg`, highest first
    ///
    /// ## Example
    /// ```swift
    /// let overhead = await catalog.lookAngles(from: observer, at: Date(), minElevationDeg: 10)
    /// ```
    public func lookAngles(from observer: Observer, at date: Date, minElevationDeg: Degrees = 0) async -> [SatelliteLookAngles] {
        let results = await concurrentCompactMap { satellite -> SatelliteLookAngles? in
            // Cheap geometric test first: skip orbits that can never reach this observer's sky
            guard satellite.canRise(forLatitudeDeg: observer.latitudeDeg, minElevationDeg: minElevationDeg),
                  let topocentric = try? satellite.propagator.topocentric(at: date, for: observer),
                  topocentric.elevationDeg >= minElevationDeg else {
                return nil
            }
            return SatelliteLookAngles(satellite: satellite, topocentric: topocentric)
        }
        return results.sorted { $0.topocentric.elevationDeg > $1.topocentric.elevationDeg }
    }

    /// Every pass over an observer in a time window, for the whole catalog.
    ///
    /// Satellites whose orbits can never rise above `minElevationDeg` at the observer's
    /// latitude are skipped without propagating them (see `CatalogSatellite.canRise`).
    ///
    /// - Parameters:
    ///   - observer: The observer's location
    ///   - start: Start of the search window
    ///   - end: End of the search window
    ///   - minElevationDeg: Elevation that counts as a pass (default 10°)
    ///   - stepSeconds: Coarse sampling interval (default 60 s). Passes shorter than the
    ///     step are still found by the peak check in `predictPasses`.
    /// - Returns: All passes, ordered by rise time. Satellites SGP4 cannot propagate across
    ///            the window are left out.
    public func passes(for observer: Observer, from start: Date, to end: Date,
                       minElevationDeg: Degrees = 10, stepSeconds: Double = 60) async -> [SatellitePass] {
        let perSatellite = await concurrentCompactMap { satellite -> [SatellitePass]? in
            guard satellite.canRise(forLatitudeDeg: observer.latitudeDeg, minElevationDeg: minElevationDeg),
                  let windows = try? satellite.propagator.predictPasses(
                      for: observer, from: start, to: end, minElevationDeg: minElevationDeg, stepSeconds: stepSeconds
                  ) else {
                return nil
            }
            return windows.map { SatellitePass(satellite: satellite, pass: $0) }
        }
        return perSatellite.flatMap { $0 }.sorted { $0.pass.aos.time < $1.pass.aos.time }
    }
}

// MARK: - Concurrency

extension SatelliteCatalog {
    /// Applies a transform to every satellite on all CPU cores and returns the non-nil
    /// results in catalog order.
    ///
    /// Satellites are split into a few chunks per core rather than one task each: a single
    /// SGP4 call takes about a microsecond, so per-task overhead would otherwise dominate.
    /// Results are reassembled by chunk index, so the output order (and therefore every
    /// result) is identical to a serial loop.
    func concurrentCompactMap<T: Sendable>(_ transform: @escaping @Sendable (CatalogSatellite) -> T?) async -> [T] {
        let satellites = self.satellites
        guard !satellites.isEmpty else { return [] }

        let chunkCount = min(satellites.count, ProcessInfo.processInfo.activeProcessorCount * 4)
        let chunkSize = (satellites.count + chunkCount - 1) / chunkCount

        return await withTaskGroup(of: (Int, [T]).self) { group in
            for chunk in 0..<chunkCount {
                let range = (chunk * chunkSize)..<min((chunk + 1) * chunkSize, satellites.count)
                guard !range.isEmpty else { continue }
                group.addTask {
                    (chunk, satellites[range].compactMap(transform))
                }
            }

            var chunks = [[T]](repeating: [], count: chunkCount)
            for await (index, results) in group {
                chunks[index] = results
            }
            return chunks.flatMap { $0 }
        }
    }
}
