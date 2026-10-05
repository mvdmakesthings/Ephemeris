//
//  Vector3D.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/20/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// A three-dimensional vector for positions (km) and velocities (km/s).
///
/// Used in every Cartesian frame in the library: ECI/TEME, ECEF, and the observer's
/// local East-North-Up (ENU) frame. The vector itself does not record its frame; the
/// API that produces it documents which one it is in.
///
/// ## Example
/// ```swift
/// let a = Vector3D(x: 1, y: 2, z: 2)
/// let b = Vector3D(x: 0, y: 0, z: 1)
/// let length = a.magnitude    // 3
/// let difference = a - b      // (1, 2, 1)
/// let projection = a.dot(b)   // 2
/// ```
public struct Vector3D: Hashable, Codable, Sendable {

    // MARK: - Properties

    /// X component
    public let x: Double

    /// Y component
    public let y: Double

    /// Z component
    public let z: Double

    /// The length of the vector, √(x² + y² + z²)
    public var magnitude: Double {
        return sqrt(x * x + y * y + z * z)
    }

    // MARK: - Initialization

    /// Creates a vector from its components.
    ///
    /// - Parameters:
    ///   - x: X component
    ///   - y: Y component
    ///   - z: Z component
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    // MARK: - Operations

    /// The dot (scalar) product with another vector.
    ///
    /// - Parameter other: The other vector
    /// - Returns: x₁x₂ + y₁y₂ + z₁z₂
    public func dot(_ other: Vector3D) -> Double {
        return x * other.x + y * other.y + z * other.z
    }

    /// Component-wise sum of two vectors.
    public static func + (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        return Vector3D(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    /// Component-wise difference of two vectors.
    public static func - (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        return Vector3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    /// The vector scaled by a constant.
    public static func * (vector: Vector3D, scalar: Double) -> Vector3D {
        return Vector3D(x: vector.x * scalar, y: vector.y * scalar, z: vector.z * scalar)
    }
}
