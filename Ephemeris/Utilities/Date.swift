//
//  Date.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/22/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

extension Date {

    
    /// Converts epoch year, and epoch day fraction to full julian days
    /// - Note:
    ///     Derived from https://github.com/dhmspector/ZeitSatTrack
    public static func julianDayFromEpoch(epochYear: Int, epochDayFraction: Double) -> Double {
        var calendar =  Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "UTC")!
        var components = DateComponents()
            components.year = epochYear
        let epochFirstDayOfYear = calendar.date(from: components)
        let epochFirstDayOfYearSecondsSince1970 = floor((epochFirstDayOfYear?.timeIntervalSince1970)!)
        let epochFirstDayOfYearJulianDate = 2440587.5 + epochFirstDayOfYearSecondsSince1970 / 86400.0

        return epochFirstDayOfYearJulianDate + epochDayFraction
    }

    
    /// Converts the date unto a julian day.
    /// - Note: Derived from "Methods of Astrondynamics, A Computer Approach (v3) " by Capt David Vallado, Department of Astronautics, U.S. Air Force Academy https://www.academia.edu/20528856/Methods_of_Astrodynamics_a_Computer_Approach
    public static func julianDay(from date: Date) -> JulianDay? {
        var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "UTC")!
        
        // Seperate the date into it's components.
        let dc = calendar.dateComponents(in: calendar.timeZone, from: date)
        guard let year = dc.year,
              let month = dc.month,
              let day = dc.day,
              let hour = dc.hour,
              let minute = dc.minute,
              let second = dc.second else { return nil }
        
        let term1 = Double(367.0 * Double(year))
        let term2 = Int(7 * (year + ((month + 9) / 12)) / 4)
        let term3 = Int(275 * month / 9)
        let ut = hmsToUT(hour: hour, minute: minute, second: second)
        let julianDay: Double = (term1 - Double(term2) + Double(term3)) + Double(day) + 1721013.5 + ut
        return julianDay
    }
    
    /// Converts conventional hour, minute, seconds into universal time.
    /// - Parameters:
    ///   - hour: Two digit hour (0..24), ex. 2
    ///   - minute: Two digit minute (0...59), ex. 39
    ///   - second: Seconds (0.0...59.99) 57.29. For ease of use, we assume no fractional second, hence Int
    /// - Returns: Universal Time (hhmm.ss) ex. 239.5729
    /// - Note: Derived from "Methods of Astrondynamics, A Computer Approach (v3) " by Capt David Vallado, Department of Astronautics, U.S. Air Force Academy https://www.academia.edu/20528856/Methods_of_Astrodynamics_a_Computer_Approach
    public static func hmsToUT(hour: Int, minute: Int, second: Int) -> Double {
        let sec = Double(second) / 100.0
        return Double(hour * 100 + minute) + sec
    }
    
    
    /// Finds the Greenwich Sidereal Time or the hour angle of the average position of the vernal equinox, neglecting short term motions of the equinox due to nutation.
    /// - Example:  Λ=𝐻0+Δ𝐻+𝜔∗(𝑡−Δ𝑡)
    /// - Parameter julianDay
    /// - Returns: Hour Angle in Radians (0 to 2Pi rad)
    /// - Note: Derived from "Methods of Astrondynamics, A Computer Approach (v3) " by Capt David Vallado, Department of Astronautics, U.S. Air Force Academy https://www.academia.edu/20528856/Methods_of_Astrodynamics_a_Computer_Approach
    public static func greenwichSideRealTime(from julianDay: JulianDay) -> Radians {
        let twopi: Double = 2 * .pi
        let J2000: Double = Date.toJ2000(from: julianDay)
        var temp = 1.753368559 + 628.3319705 * J2000 + (6.770708127 * pow(10, -06) * J2000 * J2000)
        temp = temp.truncatingRemainder(dividingBy: twopi)
        if temp < 0.0 {
            temp = temp + twopi
        }
        return temp
    }
    
    public static func toJ2000(from julianDay: JulianDay) -> J2000 {
        return (julianDay - 2451545.0) / 36525.0
    }
    
}
