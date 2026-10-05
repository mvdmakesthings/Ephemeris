//
//  SGP4+Initialization.swift
//  Ephemeris
//
//  SGP4 element initialization: a port of sgp4init and initl from Vallado's
//  sgp4unit.cpp, plus the reference implementation's TLE epoch conversion.
//

import Foundation

// MARK: - Initialization (sgp4init, initl)

extension SGP4 {
    /// Computes the near-Earth constants and, for deep-space orbits, the lunar-solar and
    /// resonance terms. Port of `sgp4init` and `initl` from sgp4unit.cpp.
    ///
    /// - Parameters:
    ///   - input: Elements with the TLE values filled in (radians, rad/min)
    ///   - epoch: Days since 1949 December 31 00:00 UT
    ///   - mode: Operation mode
    /// - Returns: Fully initialized elements
    static func sgp4init(_ input: SGP4Elements, epoch: Double, mode: OperationMode) -> SGP4Elements {
        var rec = input
        let grav = rec.gravity
        let temp4 = 1.5e-12
        let x2o3 = 2.0 / 3.0

        // sgp4fix: perigee heights for the atmospheric density model, in Earth radii
        let ss = 78.0 / grav.radiusEarthKm + 1.0
        let qzms2ttemp = (120.0 - 78.0) / grav.radiusEarthKm
        let qzms2t = qzms2ttemp * qzms2ttemp * qzms2ttemp * qzms2ttemp

        // ------------------------ initl ------------------------
        // Recover the original (Brouwer) mean motion from the Kozai mean motion in the TLE
        let eccsq = rec.ecco * rec.ecco
        let omeosq = 1.0 - eccsq
        let rteosq = sqrt(omeosq)
        let cosio = cos(rec.inclo)
        let cosio2 = cosio * cosio

        let ak = pow(grav.xke / rec.noKozai, x2o3)
        let d1 = 0.75 * grav.j2 * (3.0 * cosio2 - 1.0) / (rteosq * omeosq)
        var del = d1 / (ak * ak)
        let adel = ak * (1.0 - del * del - del * (1.0 / 3.0 + 134.0 * del * del / 81.0))
        del = d1 / (adel * adel)
        rec.noUnkozai = rec.noKozai / (1.0 + del)

        let ao = pow(grav.xke / rec.noUnkozai, x2o3)
        let sinio = sin(rec.inclo)
        let po = ao * omeosq
        let con42 = 1.0 - 5.0 * cosio2
        rec.con41 = -con42 - cosio2 - cosio2
        let posq = po * po
        let rp = ao * (1.0 - rec.ecco)

        // Greenwich sidereal time at epoch
        switch mode {
        case .afspc:
            let ts70 = epoch - 7305.0
            let ds70 = floor(ts70 + 1.0e-8)
            let tfrac = ts70 - ds70
            let c1 = 1.72027916940703639e-2
            let thgr70 = 1.7321343856509374
            let fk5r = 5.07551419432269442e-15
            let c1p2p = c1 + twoPi
            var gsto = (thgr70 + c1 * ds70 + c1p2p * tfrac + ts70 * ts70 * fk5r).truncatingRemainder(dividingBy: twoPi)
            if gsto < 0.0 {
                gsto += twoPi
            }
            rec.gsto = gsto
        case .improved:
            rec.gsto = Date.greenwichSideRealTime(from: epoch + 2433281.5)
        }
        // ---------------------- end initl ----------------------

        // Perigee below 220 km: use the simplified drag equations
        rec.isimp = rp < 220.0 / grav.radiusEarthKm + 1.0

        var sfour = ss
        var qzms24 = qzms2t
        let perige = (rp - 1.0) * grav.radiusEarthKm

        // For perigees below 156 km, the values of s and qoms2t are altered
        if perige < 156.0 {
            sfour = perige - 78.0
            if perige < 98.0 {
                sfour = 20.0
            }
            let qzms24temp = (120.0 - sfour) / grav.radiusEarthKm
            qzms24 = qzms24temp * qzms24temp * qzms24temp * qzms24temp
            sfour = sfour / grav.radiusEarthKm + 1.0
        }

        let pinvsq = 1.0 / posq
        let tsi = 1.0 / (ao - sfour)
        rec.eta = ao * rec.ecco * tsi
        let etasq = rec.eta * rec.eta
        let eeta = rec.ecco * rec.eta
        let psisq = abs(1.0 - etasq)
        let coef = qzms24 * pow(tsi, 4.0)
        let coef1 = coef / pow(psisq, 3.5)
        let cc2 = coef1 * rec.noUnkozai * (ao * (1.0 + 1.5 * etasq + eeta *
            (4.0 + etasq)) + 0.375 * grav.j2 * tsi / psisq * rec.con41 *
            (8.0 + 3.0 * etasq * (8.0 + etasq)))
        rec.cc1 = rec.bstar * cc2
        var cc3 = 0.0
        if rec.ecco > 1.0e-4 {
            cc3 = -2.0 * coef * tsi * grav.j3oj2 * rec.noUnkozai * sinio / rec.ecco
        }
        rec.x1mth2 = 1.0 - cosio2
        rec.cc4 = 2.0 * rec.noUnkozai * coef1 * ao * omeosq *
            (rec.eta * (2.0 + 0.5 * etasq) + rec.ecco *
            (0.5 + 2.0 * etasq) - grav.j2 * tsi / (ao * psisq) *
            (-3.0 * rec.con41 * (1.0 - 2.0 * eeta + etasq *
            (1.5 - 0.5 * eeta)) + 0.75 * rec.x1mth2 *
            (2.0 * etasq - eeta * (1.0 + etasq)) * cos(2.0 * rec.argpo)))
        rec.cc5 = 2.0 * coef1 * ao * omeosq * (1.0 + 2.75 *
            (etasq + eeta) + eeta * etasq)

        // Secular rates from J2 and J4: mean anomaly, argument of perigee, and node
        let cosio4 = cosio2 * cosio2
        let temp1 = 1.5 * grav.j2 * pinvsq * rec.noUnkozai
        let temp2 = 0.5 * temp1 * grav.j2 * pinvsq
        let temp3 = -0.46875 * grav.j4 * pinvsq * pinvsq * rec.noUnkozai
        rec.mdot = rec.noUnkozai + 0.5 * temp1 * rteosq * rec.con41 + 0.0625 *
            temp2 * rteosq * (13.0 - 78.0 * cosio2 + 137.0 * cosio4)
        rec.argpdot = -0.5 * temp1 * con42 + 0.0625 * temp2 *
            (7.0 - 114.0 * cosio2 + 395.0 * cosio4) +
            temp3 * (3.0 - 36.0 * cosio2 + 49.0 * cosio4)
        let xhdot1 = -temp1 * cosio
        rec.nodedot = xhdot1 + (0.5 * temp2 * (4.0 - 19.0 * cosio2) +
            2.0 * temp3 * (3.0 - 7.0 * cosio2)) * cosio
        let xpidot = rec.argpdot + rec.nodedot
        rec.omgcof = rec.bstar * cc3 * cos(rec.argpo)
        rec.xmcof = 0.0
        if rec.ecco > 1.0e-4 {
            rec.xmcof = -x2o3 * coef * rec.bstar / eeta
        }
        rec.nodecf = 3.5 * omeosq * xhdot1 * rec.cc1
        rec.t2cof = 1.5 * rec.cc1
        // sgp4fix for divide by zero with xinco = 180 deg
        if abs(cosio + 1.0) > 1.5e-12 {
            rec.xlcof = -0.25 * grav.j3oj2 * sinio * (3.0 + 5.0 * cosio) / (1.0 + cosio)
        } else {
            rec.xlcof = -0.25 * grav.j3oj2 * sinio * (3.0 + 5.0 * cosio) / temp4
        }
        rec.aycof = -0.5 * grav.j3oj2 * sinio
        let delmotemp = 1.0 + rec.eta * cos(rec.mo)
        rec.delmo = delmotemp * delmotemp * delmotemp
        rec.sinmao = sin(rec.mo)
        rec.x7thm1 = 7.0 * cosio2 - 1.0

        // --------------- deep space initialization -------------
        // Period of 225 minutes or more switches on lunar-solar and resonance terms
        if 2.0 * Double.pi / rec.noUnkozai >= 225.0 {
            rec.isDeepSpace = true
            rec.isimp = true
            let common = dscom(epoch: epoch, elements: rec)
            rec.lunarSolar = common.lunarSolar
            rec.resonance = dsinit(common: common, elements: rec, xpidot: xpidot, eccsq: eccsq)
        }

        // ----------- set variables if not deep space -----------
        if !rec.isimp {
            let cc1sq = rec.cc1 * rec.cc1
            rec.d2 = 4.0 * ao * tsi * cc1sq
            let temp = rec.d2 * tsi * rec.cc1 / 3.0
            rec.d3 = (17.0 * ao + sfour) * temp
            rec.d4 = 0.5 * temp * ao * tsi * (221.0 * ao + 31.0 * sfour) * rec.cc1
            rec.t3cof = rec.d2 + 2.0 * cc1sq
            rec.t4cof = 0.25 * (3.0 * rec.d3 + rec.cc1 * (12.0 * rec.d2 + 10.0 * cc1sq))
            rec.t5cof = 0.2 * (3.0 * rec.d4 +
                12.0 * rec.cc1 * rec.d3 +
                6.0 * rec.d2 * rec.d2 +
                15.0 * cc1sq * (2.0 * rec.d2 + cc1sq))
        }

        return rec
    }

    /// Converts a TLE epoch (year + fractional day of year) to a Julian date exactly the
    /// way the reference implementation does: `days2mdhms` followed by `jday`.
    ///
    /// Splitting into month, day, hour, minute and second and recombining introduces
    /// rounding of up to ~1e-10 days (tens of microseconds). That is physically
    /// negligible, but the published verification vectors include it, and for highly
    /// eccentric orbits it is visible at the millimeter level. Matching it keeps this
    /// port comparable with the reference to sub-millimeter precision.
    ///
    /// - Parameters:
    ///   - year: Four-digit year
    ///   - dayOfYear: Day of year with fraction (1.0 = January 1, 00:00 UTC)
    /// - Returns: Julian date (UTC)
    static func referenceJulianDate(year: Int, dayOfYear: Double) -> Double {
        // ---------------------------- days2mdhms ----------------------------
        var monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        if year % 4 == 0 {
            monthLengths[1] = 29
        }
        let dayOfYearWhole = Int(floor(dayOfYear))
        var month = 1
        var daysBeforeMonth = 0
        while dayOfYearWhole > daysBeforeMonth + monthLengths[month - 1] && month < 12 {
            daysBeforeMonth += monthLengths[month - 1]
            month += 1
        }
        let day = Double(dayOfYearWhole - daysBeforeMonth)
        var temp = (dayOfYear - Double(dayOfYearWhole)) * 24.0
        let hour = floor(temp)
        temp = (temp - hour) * 60.0
        let minute = floor(temp)
        let second = (temp - minute) * 60.0

        // ------------------------------- jday -------------------------------
        let yr = Double(year)
        let mon = Double(month)
        return 367.0 * yr
            - floor((7.0 * (yr + floor((mon + 9.0) / 12.0))) * 0.25)
            + floor(275.0 * mon / 9.0)
            + day + 1721013.5
            + ((second / 60.0 + minute) / 60.0 + hour) / 24.0
    }

    /// Converts a proleptic Gregorian calendar date to days since 1970-01-01.
    ///
    /// - Note: Howard Hinnant's `days_from_civil` algorithm; exact for all dates.
    static func daysFromCivil(year: Int, month: Int, day: Int) -> Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (month + 9) % 12
        let doy = (153 * mp + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146097 + doe - 719468
    }
}
