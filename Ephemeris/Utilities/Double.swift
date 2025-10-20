//
//  Double.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/22/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// Extensions to `Double` for mathematical operations used in orbital mechanics.
///
/// These extensions provide utility methods for:
/// - Rounding to a specific number of decimal places
/// - Converting between degrees and radians
///
/// ## Example Usage
/// ```swift
/// let rounded = 3.14159.round(to: 2)  // 3.14
/// let radians = 45.0.inRadians()       // π/4
/// let degrees = (Double.pi / 2).inDegrees()  // 90.0
/// ```
extension Double {
    /// Rounds the value to a specified number of decimal places.
    ///
    /// - Parameter places: Number of decimal places to round to
    /// - Returns: The rounded value
    ///
    /// ## Example
    /// ```swift
    /// let pi = 3.14159265359
    /// print(pi.round(to: 2))  // 3.14
    /// print(pi.round(to: 4))  // 3.1416
    /// ```
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// Converts degrees to radians.
    ///
    /// - Returns: The angle in radians
    ///
    /// ## Example
    /// ```swift
    /// let degrees = 180.0
    /// let radians = degrees.inRadians()  // π
    /// ```
    func inRadians() -> Radians {
        return self * .pi / 180
    }
    
    /// Converts radians to degrees.
    ///
    /// - Returns: The angle in degrees
    ///
    /// ## Example
    /// ```swift
    /// let radians = Double.pi
    /// let degrees = radians.inDegrees()  // 180.0
    /// ```
    func inDegrees() -> Degrees {
        return self * 180 / .pi
    }
}
