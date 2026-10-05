//
//  Date.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/22/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// Extensions to `Date` for astronomical time conversions.
///
/// These extensions provide methods for converting between standard calendar dates
/// and astronomical time systems used in orbital mechanics:
/// - Julian Day Number (JDN)
/// - Greenwich Sidereal Time (GST)
/// - J2000 epoch conversions
///
/// ## Julian Day
/// The Julian Day is a continuous count of days since the beginning of the Julian Period
/// (January 1, 4713 BC). It's widely used in astronomy and orbital mechanics for calculating
/// time intervals without worrying about calendar complexities.
///
/// ## Sidereal Time
/// Greenwich Sidereal Time is essential for converting between celestial coordinates and
/// Earth-fixed coordinates, accounting for Earth's rotation.
///
/// ## Example Usage
/// ```swift
/// let jd = Date.julianDay(from: Date())
/// let gst = Date.greenwichSideRealTime(from: jd!)
/// let j2000 = Date.toJ2000(from: jd!)
/// ```
extension Date {
    
    // MARK: - Julian Date Conversion
    
    /// Converts a Date to Julian Day Number.
    ///
    /// The Julian Day Number (JDN) is the integer assigned to a whole solar day in the
    /// Julian day count starting from noon Universal time, with Julian day number 0
    /// assigned to the day starting at noon on Monday, January 1, 4713 BC.
    ///
    /// - Parameter date: The date to convert
    /// - Returns: The Julian Day Number as a Double, or nil if the date components cannot be extracted
    /// - Note: Based on the algorithm from "Astronomical Algorithms" by Jean Meeus and
    ///         "Methods of Astrodynamics, A Computer Approach (v3)" by Capt David Vallado
    public static func julianDay(from date: Date) -> JulianDay? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        
        // Extract date components in UTC
        let dc = calendar.dateComponents(in: calendar.timeZone, from: date)
        guard let year = dc.year,
              let month = dc.month,
              let day = dc.day,
              let hour = dc.hour,
              let minute = dc.minute,
              let second = dc.second,
              let nanosecond = dc.nanosecond else { return nil }
        
        // Calculate the Julian Day using the standard algorithm
        // This algorithm works for all Gregorian calendar dates
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        
        // Julian Day Number at noon
        let jdn = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
        
        // Convert time to fraction of day (0.0 to 1.0)
        let totalSeconds = Double(hour) * 3600.0 + Double(minute) * 60.0 + Double(second) + Double(nanosecond) / 1_000_000_000.0
        let dayFraction = totalSeconds / PhysicalConstants.Time.secondsPerDay
        
        // Julian Day = JDN - 0.5 (to convert from noon to midnight) + day fraction
        let julianDay = Double(jdn) - 0.5 + dayFraction
        
        return julianDay
    }
    
    /// The Julian Date of this instant (UTC).
    ///
    /// Computed directly from the Unix timestamp, so it needs no calendar lookup and
    /// cannot fail. Both Foundation's `Date` and the UTC Julian Date count days without
    /// leap seconds, so the result matches `julianDay(from:)`.
    ///
    /// ```
    /// JD = 2440587.5 + secondsSince1970 / 86400
    /// ```
    var julianDate: JulianDay {
        return PhysicalConstants.Julian.unixEpoch + timeIntervalSince1970 / PhysicalConstants.Time.secondsPerDay
    }

    /// Converts epoch year and epoch day fraction to Julian Day Number.
    ///
    /// This method is specifically designed for satellite Two-Line Element (TLE) data,
    /// which uses a compact date format of year + day-of-year with fractional day.
    ///
    /// - Parameters:
    ///   - epochYear: The year of the epoch (e.g., 2020)
    ///   - epochDayFraction: The day of year plus fractional day (e.g., 1.5 = January 1st, noon)
    /// - Returns: The Julian Day Number
    /// - Note: Derived from https://github.com/dhmspector/ZeitSatTrack
    public static func julianDayFromEpoch(epochYear: Int, epochDayFraction: Double) -> JulianDay {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        
        // Create date for January 1st of the epoch year at midnight
        var components = DateComponents()
        components.year = epochYear
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let jan1 = calendar.date(from: components) else {
            // Fallback calculation if date creation fails
            let jan1SecondsSince1970 = Double((epochYear - 1970) * 365 + (epochYear - 1969) / 4) * PhysicalConstants.Time.secondsPerDay
            return PhysicalConstants.Julian.unixEpoch + jan1SecondsSince1970 / PhysicalConstants.Time.secondsPerDay + epochDayFraction - 1.0
        }
        
        // Get Julian Day for January 1st
        guard let jan1JD = julianDay(from: jan1) else {
            // Fallback calculation
            let jan1SecondsSince1970 = jan1.timeIntervalSince1970
            return PhysicalConstants.Julian.unixEpoch + jan1SecondsSince1970 / PhysicalConstants.Time.secondsPerDay + epochDayFraction - 1.0
        }
        
        // Add the epoch day fraction (subtract 1 because day 1 is January 1st, not day 0)
        return jan1JD + epochDayFraction - 1.0
    }
    
    // MARK: - Sidereal Time
    
    /// Calculates the Greenwich Sidereal Time (GST) for a given Julian Day.
    ///
    /// Greenwich Sidereal Time is the hour angle of the mean vernal equinox at Greenwich,
    /// neglecting short term motions of the equinox due to nutation. It's essential for
    /// converting between celestial and terrestrial coordinate systems.
    ///
    /// Uses the IAU-82 expression for Greenwich Mean Sidereal Time, which is the same
    /// model SGP4 uses (`gstime` in Vallado et al. 2006). The polynomial is evaluated
    /// on the full Julian date, so the time of day is included and the result advances
    /// by roughly 360.9856° per solar day.
    ///
    /// ```
    /// GMST(s) = 67310.54841 + (876600h + 8640184.812866)·T + 0.093104·T² − 6.2e-6·T³
    /// ```
    /// where `T` is Julian centuries of UT1 since J2000.0. UTC is used in place of UT1,
    /// which introduces at most 0.9 s of rotation error (about 0.4 km at the equator).
    ///
    /// - Parameter julianDay: The Julian Day (UT1, UTC acceptable)
    /// - Returns: Greenwich Mean Sidereal Time in radians (0 to 2π)
    /// - Note: Vallado, "Fundamentals of Astrodynamics and Applications" (4th ed.), Eq. 3-47.
    ///         Verified against Example 3-5 (1992-08-20 12:14 UT1 → 152.578787810°).
    public static func greenwichSideRealTime(from julianDay: JulianDay) -> Radians {
        let twopi: Double = PhysicalConstants.Angle.radiansPerCircle

        // Convert to Julian centuries since J2000.0
        let t = toJ2000(from: julianDay)

        // GMST in seconds of time (IAU-82)
        let gmstSeconds = -6.2e-6 * t * t * t
            + 0.093104 * t * t
            + (876600.0 * PhysicalConstants.Time.secondsPerHour + 8640184.812866) * t
            + 67310.54841

        // Seconds of time to radians: 240 seconds of time per degree
        var gst = (gmstSeconds / 240.0).inRadians()

        // Normalize to 0 to 2π range
        gst = gst.truncatingRemainder(dividingBy: twopi)
        if gst < 0.0 {
            gst += twopi
        }
        
        return gst
    }
    
    // MARK: - J2000 Conversion
    
    /// Converts Julian Day to Julian centuries since J2000.0.
    ///
    /// J2000.0 is the standard epoch used in astronomy, corresponding to
    /// January 1, 2000, 12:00 TT (Terrestrial Time), which is JD 2451545.0.
    ///
    /// - Parameter julianDay: The Julian Day Number
    /// - Returns: Time in Julian centuries since J2000.0
    public static func toJ2000(from julianDay: JulianDay) -> J2000 {
        // JD 2451545.0 = January 1, 2000, 12:00 TT (J2000.0 epoch)
        // 36525 days = 1 Julian century
        return (julianDay - PhysicalConstants.Julian.j2000Epoch) / PhysicalConstants.Time.daysPerJulianCentury
    }
    
}
