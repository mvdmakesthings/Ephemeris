//
//  Date+AstronomicalTime.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/22/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// Astronomical time scales used to turn the Earth: Julian dates and sidereal time.
///
/// ## Julian Date
/// A continuous count of days, so time differences are a simple subtraction with no
/// calendar rules involved.
///
/// ## Sidereal Time
/// Greenwich Mean Sidereal Time (GMST) is the angle between the vernal equinox and the
/// Greenwich meridian. Rotating an inertial position by GMST gives Earth-fixed coordinates.
///
/// ## Example Usage
/// ```swift
/// let now = Date()
/// let jd = now.julianDate                    // e.g. 2461319.1
/// let gmst = now.greenwichMeanSiderealTime   // radians, 0..<2π
/// ```
extension Date {

    // MARK: - Julian Date

    /// The Julian date of this instant (UTC).
    ///
    /// Computed directly from the Unix timestamp. Foundation's `Date` and the UTC Julian
    /// date both count days without leap seconds, so no calendar lookup is needed:
    /// ```
    /// JD = 2440587.5 + secondsSince1970 / 86400
    /// ```
    public var julianDate: JulianDate {
        return PhysicalConstants.Julian.unixEpoch + timeIntervalSince1970 / PhysicalConstants.Time.secondsPerDay
    }

    // MARK: - Sidereal Time

    /// Greenwich Mean Sidereal Time at this instant, in radians (0 to 2π).
    ///
    /// See `greenwichMeanSiderealTime(julianDate:)` for the model. This version measures
    /// time from J2000 in seconds rather than through a Julian date: a `Double` Julian date
    /// near 2.46 million only resolves about 40 µs, during which the Earth turns enough to
    /// move a point on the equator by 2 cm. Seconds since 1970 resolve well under 1 µs.
    public var greenwichMeanSiderealTime: Radians {
        let secondsPerCentury = PhysicalConstants.Time.secondsPerDay * PhysicalConstants.Time.daysPerJulianCentury
        let centuries = (timeIntervalSince1970 - Self.j2000UnixTime) / secondsPerCentury
        return Self.greenwichMeanSiderealTime(julianCenturies: centuries)
    }

    /// The J2000.0 epoch (2000-01-01 12:00:00) in seconds since 1970
    private static let j2000UnixTime: TimeInterval =
        (PhysicalConstants.Julian.j2000 - PhysicalConstants.Julian.unixEpoch) * PhysicalConstants.Time.secondsPerDay

    /// Calculates Greenwich Mean Sidereal Time for a Julian date.
    ///
    /// Uses the IAU-82 expression, which is the same model SGP4 uses (`gstime` in
    /// Vallado et al. 2006). The polynomial is evaluated on the full Julian date, so the
    /// time of day is included and the result advances by about 360.9856° per solar day.
    ///
    /// ```
    /// GMST(s) = 67310.54841 + (876600h + 8640184.812866)·T + 0.093104·T² − 6.2e-6·T³
    /// ```
    /// where `T` is Julian centuries of UT1 since J2000.0. UTC is used in place of UT1,
    /// which introduces at most 0.9 s of rotation error (about 0.4 km at the equator).
    ///
    /// - Parameter julianDate: The Julian date (UT1, UTC acceptable)
    /// - Returns: Greenwich Mean Sidereal Time in radians (0 to 2π)
    /// - Note: Vallado, "Fundamentals of Astrodynamics and Applications" (4th ed.), Eq. 3-47.
    ///         Verified against Example 3-5 (1992-08-20 12:14 UT1 → 152.578787810°).
    public static func greenwichMeanSiderealTime(julianDate: JulianDate) -> Radians {
        return greenwichMeanSiderealTime(julianCenturies: julianCenturiesSinceJ2000(julianDate: julianDate))
    }

    /// The IAU-82 GMST polynomial, evaluated for `t` Julian centuries since J2000.0.
    private static func greenwichMeanSiderealTime(julianCenturies t: Double) -> Radians {
        let twoPi = 2.0 * Double.pi

        // GMST in seconds of time (IAU-82)
        let gmstSeconds = -6.2e-6 * t * t * t
            + 0.093104 * t * t
            + (876600.0 * PhysicalConstants.Time.secondsPerHour + 8640184.812866) * t
            + 67310.54841

        // Seconds of time to radians: 240 seconds of time per degree
        var gmst = (gmstSeconds / 240.0).inRadians().truncatingRemainder(dividingBy: twoPi)
        if gmst < 0.0 {
            gmst += twoPi
        }
        return gmst
    }

    /// Converts a Julian date to Julian centuries since the J2000.0 epoch.
    ///
    /// ```
    /// T = (JD − 2451545.0) / 36525
    /// ```
    ///
    /// - Parameter julianDate: The Julian date
    /// - Returns: Julian centuries (36525 days each) since 2000-01-01 12:00 TT
    public static func julianCenturiesSinceJ2000(julianDate: JulianDate) -> Double {
        return (julianDate - PhysicalConstants.Julian.j2000) / PhysicalConstants.Time.daysPerJulianCentury
    }
}
