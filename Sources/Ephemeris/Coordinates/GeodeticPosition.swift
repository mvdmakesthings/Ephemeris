//
//  GeodeticPosition.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/21/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// A position on or above the Earth in WGS-84 geodetic coordinates.
///
/// Latitude is geodetic: the angle between the equatorial plane and the normal to the
/// WGS-84 ellipsoid, which is what GPS receivers and maps report. Altitude is the height
/// above the ellipsoid along that normal.
///
/// ## Example Usage
/// ```swift
/// let position = try sgp4.calculatePosition(at: Date())
/// print("Latitude: \(position.latitudeDeg)°")
/// print("Longitude: \(position.longitudeDeg)°")
/// print("Altitude: \(position.altitudeKm) km")
/// ```
public struct GeodeticPosition: Hashable, Codable, Sendable {

    // MARK: - Properties

    /// Geodetic latitude in degrees (-90 to 90), positive north
    public let latitudeDeg: Degrees

    /// Longitude in degrees (-180 to 180), positive east
    public let longitudeDeg: Degrees

    /// Height above the WGS-84 ellipsoid in kilometers
    public let altitudeKm: Double

    // MARK: - Initialization

    /// Creates a geodetic position.
    ///
    /// - Parameters:
    ///   - latitudeDeg: Geodetic latitude in degrees (-90 to 90), positive north
    ///   - longitudeDeg: Longitude in degrees (-180 to 180), positive east
    ///   - altitudeKm: Height above the WGS-84 ellipsoid in kilometers
    public init(latitudeDeg: Degrees, longitudeDeg: Degrees, altitudeKm: Double) {
        self.latitudeDeg = latitudeDeg
        self.longitudeDeg = longitudeDeg
        self.altitudeKm = altitudeKm
    }
}
