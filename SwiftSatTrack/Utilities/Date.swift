//
//  Date.swift
//  SwiftSatTrack
//
//  Created by Michael VanDyke on 4/22/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

extension Date {
    /// Returns date as julian date
    func asJulianDate() -> JulianDate {
        let julianDayTimeIntervalOffsetSince1970 = 2440587.5
        return julianDayTimeIntervalOffsetSince1970 + self.timeIntervalSince1970 / 86400
    }

    /// Converts Julian Day Double as Date
    init(from julianDay: JulianDay) {
        let julianDayTimeIntervalOffsetSince1970 = 2440587.5
        self.init(timeIntervalSince1970: (julianDay - julianDayTimeIntervalOffsetSince1970) * 86400)
    }
    
    static func epochAsJulianDate(day: Int, year: Int) -> JulianDate {
        let julianDayFrom1970 = 2440587.5
        var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "UTC")!
        var components = DateComponents()
            components.year = year
        let epochFromYear = calendar.date(from: components)!
        let epochSince1970 = floor(epochFromYear.timeIntervalSince1970)
        return (julianDayFrom1970 + epochSince1970 / (24 * 60 * 60)) + day - 1.0
    }
}
