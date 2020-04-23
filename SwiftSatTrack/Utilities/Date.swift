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
    func asJulianDate() -> Double {
        let JD_JAN_1_1970_0000GMT = 2440587.5
        return JD_JAN_1_1970_0000GMT + self.timeIntervalSince1970 / 86400
    }

    /// Converts Julian DAY Double as Date
    init(from julianDay: JulianDay) {
        let JD_JAN_1_1970_0000GMT = 2440587.5
        self.init(timeIntervalSince1970: (julianDay - JD_JAN_1_1970_0000GMT) * 86400)
    }
}
