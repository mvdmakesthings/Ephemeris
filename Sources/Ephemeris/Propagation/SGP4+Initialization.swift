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
    /// Everything that does not depend on time is computed once here, so each later
    /// propagation is only a few dozen multiplications. SGP4 works in canonical units:
    /// distance in Earth radii, time in minutes, angles in radians.
    ///
    /// Recurring shorthand from the J2 theory (θ = cos i):
    /// - `con41`  = 3θ² − 1
    /// - `x1mth2` = 1 − θ² (that is, sin² i)
    /// - `x7thm1` = 7θ² − 1
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

        // Atmospheric density model. SGP4 assumes density falls off as a power law,
        //     ρ ∝ ((q₀ − s) / (r − s))⁴
        // with reference heights s = 78 km and q₀ = 120 km above the surface. In Earth radii
        // from the center: ss = 1 + 78/R⊕, and qzms2t = (q₀ − s)⁴.
        let ss = 78.0 / grav.radiusEarthKm + 1.0
        let qzms2ttemp = (120.0 - 78.0) / grav.radiusEarthKm
        let qzms2t = qzms2ttemp * qzms2ttemp * qzms2ttemp * qzms2ttemp

        // ------------------------ initl ------------------------
        // TLEs publish "Kozai" mean motion. SGP4's theory is built on Brouwer's definition
        // of mean elements, which averages out J2 differently, so first recover the Brouwer
        // ("un-Kozai'd") mean motion n₀″:
        //     a₁ = (ke / n₀)^(2/3)                                    Kepler's third law
        //     δ₁ = ¾·J2·(3cos²i − 1) / (a₁²·(1 − e²)^(3/2))
        //     a₀ = a₁·(1 − δ₁/3 − δ₁² − 134/81·δ₁³)
        //     δ₀ = ¾·J2·(3cos²i − 1) / (a₀²·(1 − e²)^(3/2))
        //     n₀″ = n₀ / (1 + δ₀)
        // (Hoots & Roehrich, Spacetrack Report #3, Section 6.)
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

        // Brouwer semi-major axis a₀″ (Earth radii), semi-latus rectum p = a(1 − e²) and
        // perigee radius rp = a(1 − e)
        let ao = pow(grav.xke / rec.noUnkozai, x2o3)
        let sinio = sin(rec.inclo)
        let po = ao * omeosq
        let con42 = 1.0 - 5.0 * cosio2
        rec.con41 = -con42 - cosio2 - cosio2
        let posq = po * po
        let rp = ao * (1.0 - rec.ecco)

        // Greenwich sidereal time at epoch, used to phase the deep-space resonance terms
        // against the Earth's rotation
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
            rec.gsto = Date.greenwichMeanSiderealTime(julianDate: epoch + 2433281.5)
        }
        // ---------------------- end initl ----------------------

        // Perigee below 220 km: the higher-order drag terms are unreliable this deep in the
        // atmosphere, so SGP4 keeps only the leading ones ("simplified" equations)
        rec.isimp = rp < 220.0 / grav.radiusEarthKm + 1.0

        var sfour = ss
        var qzms24 = qzms2t
        let perige = (rp - 1.0) * grav.radiusEarthKm

        // For perigees below 156 km, lower the density reference height s so the power-law
        // atmosphere stays sensible (s = perigee − 78 km, but no lower than 20 km)
        if perige < 156.0 {
            sfour = perige - 78.0
            if perige < 98.0 {
                sfour = 20.0
            }
            let qzms24temp = (120.0 - sfour) / grav.radiusEarthKm
            qzms24 = qzms24temp * qzms24temp * qzms24temp * qzms24temp
            sfour = sfour / grav.radiusEarthKm + 1.0
        }

        // Drag coefficients C1…C5 (Spacetrack Report #3, Section 6):
        //     ξ = 1 / (a₀ − s)          tsi
        //     η = a₀·e₀·ξ               eta
        //     C2 = (q₀ − s)⁴·ξ⁴·n₀·(1 − η²)^(−7/2)·[…]
        //     C1 = B*·C2                cc1: secular decay of the semi-major axis
        //     C3                        cc3: drag effect on the argument of perigee (J3)
        //     C4, C5                    cc4, cc5: secular and periodic decay of eccentricity
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

        // Secular (steadily growing) rates from the J2 and J4 zonal harmonics. Earth's
        // equatorial bulge makes the orbit plane precess and the perigee rotate:
        //     Ω̇ ≈ −(3/2)·n·J2·(R⊕/p)²·cos i                 nodedot (westward for i < 90°)
        //     ω̇ ≈  (3/4)·n·J2·(R⊕/p)²·(5cos²i − 1)          argpdot (stops at i = 63.4°)
        //     Ṁ ≈ n·[1 + (3/4)·J2·(R⊕/p)²·√(1 − e²)·(3cos²i − 1)]   mdot
        // plus second-order J2 and J4 terms. For the ISS, Ω̇ is about −5° per day.
        let cosio4 = cosio2 * cosio2
        let temp1 = 1.5 * grav.j2 * pinvsq * rec.noUnkozai
        let temp2 = 0.5 * temp1 * grav.j2 * pinvsq
        let temp3 = -0.46875 * grav.j4 * pinvsq * pinvsq * rec.noUnkozai
        rec.mdot = rec.noUnkozai + 0.5 * temp1 * rteosq * rec.con41 + 0.0625 *
            temp2 * rteosq * (13.0 - 78.0 * cosio2 + 137.0 * cosio4)
        rec.argpdot = -0.5 * temp1 * con42 + 0.0625 * temp2 *
            (7.0 - 114.0 * cosio2 + 395.0 * cosio4) +
            temp3 * (3.0 - 36.0 * cosio2 + 49.0 * cosio4)
        // xhdot1 is the leading J2 node regression term
        let xhdot1 = -temp1 * cosio
        rec.nodedot = xhdot1 + (0.5 * temp2 * (4.0 - 19.0 * cosio2) +
            2.0 * temp3 * (3.0 - 7.0 * cosio2)) * cosio
        let xpidot = rec.argpdot + rec.nodedot
        // Drag terms for the perigee (omgcof), mean anomaly (xmcof) and node (nodecf)
        rec.omgcof = rec.bstar * cc3 * cos(rec.argpo)
        rec.xmcof = 0.0
        if rec.ecco > 1.0e-4 {
            rec.xmcof = -x2o3 * coef * rec.bstar / eeta
        }
        rec.nodecf = 3.5 * omeosq * xhdot1 * rec.cc1
        rec.t2cof = 1.5 * rec.cc1
        // Long-period periodics from J3, the pear-shaped (odd) harmonic, which makes the
        // eccentricity and perigee oscillate over one cycle of the argument of perigee.
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
        // At periods of 225 minutes or more (above ~5,900 km altitude) the Moon and Sun
        // matter, and some orbits resonate with Earth's lumpy gravity field. Drag uses the
        // simplified form because the atmosphere is negligible there.
        if 2.0 * Double.pi / rec.noUnkozai >= 225.0 {
            rec.isDeepSpace = true
            rec.isimp = true
            let common = dscom(epoch: epoch, elements: rec)
            rec.lunarSolar = common.lunarSolar
            rec.resonance = dsinit(common: common, elements: rec, xpidot: xpidot, eccsq: eccsq)
        }

        // ----------- set variables if not deep space -----------
        // Higher-order drag: as drag lowers the orbit, the satellite speeds up, so the
        // semi-major axis shrinks as (1 − C1·t − D2·t² − D3·t³ − D4·t⁴)² and the mean
        // longitude gains terms in t², t³, t⁴ and t⁵ (t2cof…t5cof).
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
}
