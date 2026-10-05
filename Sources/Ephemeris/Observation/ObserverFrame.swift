//
//  ObserverFrame.swift
//  Ephemeris
//
//  An observer's Earth-fixed position and local axes, computed once and reused.
//

import Foundation

/// An observer's position and local East-North-Up axes in the Earth-fixed frame.
///
/// Turning a satellite position into look angles needs the observer's ECEF position and
/// the directions of east, north and up at that spot. Those depend only on the observer,
/// so pass searches and sky tracks build this once and reuse it for every time step
/// instead of recomputing a dozen sines and cosines per sample.
///
/// The unit vectors are the rows of the ECEF → ENU rotation (Montenbruck & Gill, 5.4.1):
/// ```
/// east  = (−sin λ,        cos λ,        0    )
/// north = (−sin φ·cos λ, −sin φ·sin λ,  cos φ)
/// up    = ( cos φ·cos λ,  cos φ·sin λ,  sin φ)
/// ```
/// where φ is geodetic latitude and λ longitude. The ENU components of any vector `d` are
/// then just `d·east`, `d·north` and `d·up`.
struct ObserverFrame: Sendable {

    /// Observer position in ECEF (km)
    let position: Vector3D

    /// Unit vector pointing east, in ECEF
    let east: Vector3D

    /// Unit vector pointing north, in ECEF
    let north: Vector3D

    /// Unit vector pointing up (along the ellipsoid normal), in ECEF
    let up: Vector3D

    /// Builds the frame for an observer.
    init(_ observer: Observer) {
        let station = observer.geodeticPosition
        let lat = station.latitudeDeg.inRadians()
        let lon = station.longitudeDeg.inRadians()
        let sinLat = sin(lat)
        let cosLat = cos(lat)
        let sinLon = sin(lon)
        let cosLon = cos(lon)

        self.position = CoordinateTransforms.geodeticToECEF(station)
        self.east = Vector3D(x: -sinLon, y: cosLon, z: 0)
        self.north = Vector3D(x: -sinLat * cosLon, y: -sinLat * sinLon, z: cosLat)
        self.up = Vector3D(x: cosLat * cosLon, y: cosLat * sinLon, z: sinLat)
    }

    /// Look angles to a satellite whose Earth-fixed state is known.
    ///
    /// - Parameters:
    ///   - satellite: Satellite position (km) and Earth-relative velocity (km/s) in ECEF
    ///   - applyRefraction: Whether to report apparent (refracted) elevation
    /// - Returns: Azimuth, elevation, range and range rate
    func topocentric(of satellite: StateVector, applyRefraction: Bool) -> Topocentric {
        // Line of sight from observer to satellite, then its components along the local axes
        let lineOfSight = satellite.position - position
        let enu = Vector3D(x: lineOfSight.dot(east), y: lineOfSight.dot(north), z: lineOfSight.dot(up))
        let (azimuth, elevation, range) = CoordinateTransforms.enuToAzEl(enu)

        // Range rate: Earth-relative velocity projected onto the line of sight. Positive
        // means the satellite is moving away; Doppler shift is −(range rate / c)·frequency.
        let rangeRate = lineOfSight.dot(satellite.velocity) / range

        return Topocentric(
            azimuthDeg: azimuth,
            elevationDeg: applyRefraction ? CoordinateTransforms.apparentElevation(fromTrueElevationDeg: elevation) : elevation,
            rangeKm: range,
            rangeRateKmPerSec: rangeRate
        )
    }
}
