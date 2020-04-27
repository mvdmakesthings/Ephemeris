//
//  Date.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/22/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation


extension Date {
    public static func greenwhichSiderealTime(from julianDate: Double) -> Radian {
        let twopi = Double.pi * 2
        let deg2Rad = Double.pi / 180
        let julianCenturies = (julianDate - 2451545.0) / 36525.0
        var temp = -6.2*pow(10.0, -6.0) * pow(julianCenturies, 3.0) + 0.093104 + pow(julianCenturies, 2.0) + (876600.0 * 3600 + 8640184.812866) * julianCenturies + 67310.54841 // seconds
        temp = ((temp * deg2Rad / 240.0).truncatingRemainder(dividingBy: twopi)) //
        
        if temp < 0 {
            temp += pow(.pi, 2)
        }
        return temp
    }
    
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
    
}

/// Provided by Eien Fun: https://gist.github.com/eienf/ed9a62f3935318711ef824a173b5375a
/// Updated function names for clarity.
extension Date {
    
    public func julianDayFromDate() -> Double {
        let JD_JAN_1_1970_0000GMT = 2440587.5
        return JD_JAN_1_1970_0000GMT + self.timeIntervalSince1970 / 86400
    }

    public func dateFromJulianDay(julianDay: Double) -> Date {
        let JD_JAN_1_1970_0000GMT = 2440587.5
        return  Date(timeIntervalSince1970: (julianDay - JD_JAN_1_1970_0000GMT) * 86400)
    }
    
    public func julianDateFromDate() -> DateComponents {
        let julianDay = self.julianDayFromDate()
        let julianDate = self.julianDateFromJulianDay(julianDay: julianDay)
        return julianDate
    }
    
    public func julianDayFromJulianDate(year: Int, month: Int, day: Int) -> Double {
        let y = year + (month - 3)/12
        let m = (month - 3) % 12
        let d = day - 1
        let n = d + (153 * m + 2) / 5 + 365 * y + y / 4
        let mjd = n - 678883
        let jd = Double(mjd) + 2400000.5
        return jd
    }

    public func julianDateFromJulianDay(julianDay: Double) -> DateComponents {
        let mjd = julianDay - 2400000.5
        let n = Int(mjd) + 678883
        let a = 4 * n + 3
        let b = 5 * ( ( a % 1461 ) / 4 ) + 2
        let y = a / 1461
        let m = b / 153
        let d = ( b % 153 ) / 5
        
        let day = d + 1
        let month = ( m + 3 ) % 12
        let year = y - m / 12
        
        var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
        return comps
    }
}
