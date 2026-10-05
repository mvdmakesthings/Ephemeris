//
//  Observer.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/20/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// A ground station or observer on the Earth.
///
/// Coordinates are WGS-84 geodetic, the same system GPS uses, so a phone's location can
/// be used directly. Altitude is in meters because that is how GPS and elevation maps
/// report it.
///
/// ## Example Usage
/// ```swift
/// // Louisville, Kentucky
/// let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
/// let lookAngles = try sgp4.topocentric(at: Date(), for: observer)
/// ```
public struct Observer: Hashable, Codable, Sendable {

    // MARK: - Properties

    /// Geodetic latitude in degrees (-90 to 90), positive north
    public let latitudeDeg: Degrees

    /// Longitude in degrees (-180 to 180), positive east
    public let longitudeDeg: Degrees

    /// Height above the WGS-84 ellipsoid in meters
    public let altitudeMeters: Double

    /// The observer's location as a `GeodeticPosition` (altitude in kilometers)
    public var geodeticPosition: GeodeticPosition {
        return GeodeticPosition(latitudeDeg: latitudeDeg, longitudeDeg: longitudeDeg, altitudeKm: altitudeMeters / 1000.0)
    }

    // MARK: - Initialization

    /// Creates an observer.
    ///
    /// - Parameters:
    ///   - latitudeDeg: Geodetic latitude in degrees (-90 to 90), positive north
    ///   - longitudeDeg: Longitude in degrees (-180 to 180), positive east
    ///   - altitudeMeters: Height above the WGS-84 ellipsoid in meters
    public init(latitudeDeg: Degrees, longitudeDeg: Degrees, altitudeMeters: Double) {
        self.latitudeDeg = latitudeDeg
        self.longitudeDeg = longitudeDeg
        self.altitudeMeters = altitudeMeters
    }
}
