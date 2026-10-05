//
//  SGP4+Resonance.swift
//  Ephemeris
//
//  Deep-space secular rates and the resonance integrator for 12-hour and 24-hour
//  orbits: a port of dsinit and dspace from Vallado's sgp4unit.cpp.
//  Variable names match the reference so each line can be checked against it.
//

import Foundation

// MARK: - dsinit

extension SGP4 {
    /// Computes deep-space secular rates and, for resonant orbits, the resonance coefficients.
    ///
    /// Port of `dsinit` from sgp4unit.cpp. Only called at initialization (t = 0, tc = 0).
    ///
    /// - Parameters:
    ///   - common: Output of `dscom`
    ///   - elements: Elements after near-Earth initialization
    ///   - xpidot: Rate of change of the longitude of perigee (rad/min)
    ///   - eccsq: Square of the epoch eccentricity
    /// - Returns: Secular rates and resonance terms for `dspace`
    static func dsinit(common: SGP4DeepSpaceCommon, elements: SGP4Elements,
                       xpidot: Double, eccsq: Double) -> SGP4ResonanceTerms {
        let q22 = 1.7891679e-6
        let q31 = 2.1460748e-6
        let q33 = 2.2123015e-7
        let root22 = 1.7891679e-6
        let root44 = 7.3636953e-9
        let root54 = 2.1765803e-9
        let rptim = 4.37526908801129966e-3 // Earth rotation rate, rad/min
        let root32 = 3.7393792e-7
        let root52 = 1.1428639e-7
        let x2o3 = 2.0 / 3.0
        let znl = 1.5835218e-4
        let zns = 1.19459e-5
        let tc = 0.0

        let cosim = common.cosim
        let sinim = common.sinim
        let emsq = common.emsq
        let nm = elements.noUnkozai
        let em = elements.ecco
        let inclm = elements.inclo

        var out = SGP4ResonanceTerms()

        // -------------------- deep space initialization ------------
        // Resonance windows by mean motion (rad/min): ~1 rev/day and ~2 rev/day
        if 0.0034906585 < nm && nm < 0.0052359877 {
            out.irez = 1
        }
        if 8.26e-3 <= nm && nm <= 9.24e-3 && em >= 0.5 {
            out.irez = 2
        }

        // ------------------------ do solar terms -------------------
        let ses = common.ss1 * zns * common.ss5
        let sis = common.ss2 * zns * (common.sz11 + common.sz13)
        let sls = -zns * common.ss3 * (common.sz1 + common.sz3 - 14.0 - 6.0 * emsq)
        let sghs = common.ss4 * zns * (common.sz31 + common.sz33 - 6.0)
        var shs = -zns * common.ss2 * (common.sz21 + common.sz23)
        // sgp4fix for 180 deg incl
        if inclm < 5.2359877e-2 || inclm > .pi - 5.2359877e-2 {
            shs = 0.0
        }
        if sinim != 0.0 {
            shs /= sinim
        }
        let sgs = sghs - cosim * shs

        // ------------------------- do lunar terms ------------------
        out.dedt = ses + common.s1 * znl * common.s5
        out.didt = sis + common.s2 * znl * (common.z11 + common.z13)
        out.dmdt = sls - znl * common.s3 * (common.z1 + common.z3 - 14.0 - 6.0 * emsq)
        let sghl = common.s4 * znl * (common.z31 + common.z33 - 6.0)
        var shll = -znl * common.s2 * (common.z21 + common.z23)
        // sgp4fix for 180 deg incl
        if inclm < 5.2359877e-2 || inclm > .pi - 5.2359877e-2 {
            shll = 0.0
        }
        out.domdt = sgs + sghl
        out.dnodt = shs
        if sinim != 0.0 {
            out.domdt -= cosim / sinim * shll
            out.dnodt += shll / sinim
        }

        // ----------- calculate deep space resonance effects --------
        let theta = (elements.gsto + tc * rptim).truncatingRemainder(dividingBy: twoPi)

        guard out.irez != 0 else {
            return out
        }

        let aonv = pow(nm / elements.gravity.xke, x2o3)

        // ---------- geopotential resonance for 12 hour orbits ------
        if out.irez == 2 {
            let cosisq = cosim * cosim
            let em = elements.ecco
            let emsq = eccsq
            let eoc = em * emsq
            let g201 = -0.306 - (em - 0.64) * 0.440

            let g211, g310, g322, g410, g422, g520: Double
            if em <= 0.65 {
                g211 = 3.616 - 13.2470 * em + 16.2900 * emsq
                g310 = -19.302 + 117.3900 * em - 228.4190 * emsq + 156.5910 * eoc
                g322 = -18.9068 + 109.7927 * em - 214.6334 * emsq + 146.5816 * eoc
                g410 = -41.122 + 242.6940 * em - 471.0940 * emsq + 313.9530 * eoc
                g422 = -146.407 + 841.8800 * em - 1629.014 * emsq + 1083.4350 * eoc
                g520 = -532.114 + 3017.977 * em - 5740.032 * emsq + 3708.2760 * eoc
            } else {
                g211 = -72.099 + 331.819 * em - 508.738 * emsq + 266.724 * eoc
                g310 = -346.844 + 1582.851 * em - 2415.925 * emsq + 1246.113 * eoc
                g322 = -342.585 + 1554.908 * em - 2366.899 * emsq + 1215.972 * eoc
                g410 = -1052.797 + 4758.686 * em - 7193.992 * emsq + 3651.957 * eoc
                g422 = -3581.690 + 16178.110 * em - 24462.770 * emsq + 12422.520 * eoc
                if em > 0.715 {
                    g520 = -5149.66 + 29936.92 * em - 54087.36 * emsq + 31324.56 * eoc
                } else {
                    g520 = 1464.74 - 4664.75 * em + 3763.64 * emsq
                }
            }

            let g533, g521, g532: Double
            if em < 0.7 {
                g533 = -919.22770 + 4988.6100 * em - 9064.7700 * emsq + 5542.21 * eoc
                g521 = -822.71072 + 4568.6173 * em - 8491.4146 * emsq + 5337.524 * eoc
                g532 = -853.66600 + 4690.2500 * em - 8624.7700 * emsq + 5341.4 * eoc
            } else {
                g533 = -37995.780 + 161616.52 * em - 229838.20 * emsq + 109377.94 * eoc
                g521 = -51752.104 + 218913.95 * em - 309468.16 * emsq + 146349.42 * eoc
                g532 = -40023.880 + 170470.89 * em - 242699.48 * emsq + 115605.82 * eoc
            }

            let sini2 = sinim * sinim
            let f220 = 0.75 * (1.0 + 2.0 * cosim + cosisq)
            let f221 = 1.5 * sini2
            let f321 = 1.875 * sinim * (1.0 - 2.0 * cosim - 3.0 * cosisq)
            let f322 = -1.875 * sinim * (1.0 + 2.0 * cosim - 3.0 * cosisq)
            let f441 = 35.0 * sini2 * f220
            let f442 = 39.3750 * sini2 * sini2
            let f522 = 9.84375 * sinim * (sini2 * (1.0 - 2.0 * cosim - 5.0 * cosisq) +
                0.33333333 * (-2.0 + 4.0 * cosim + 6.0 * cosisq))
            let f523 = sinim * (4.92187512 * sini2 * (-2.0 - 4.0 * cosim +
                10.0 * cosisq) + 6.56250012 * (1.0 + 2.0 * cosim - 3.0 * cosisq))
            let f542 = 29.53125 * sinim * (2.0 - 8.0 * cosim + cosisq *
                (-12.0 + 8.0 * cosim + 10.0 * cosisq))
            let f543 = 29.53125 * sinim * (-2.0 - 8.0 * cosim + cosisq *
                (12.0 + 8.0 * cosim - 10.0 * cosisq))

            let xno2 = nm * nm
            let ainv2 = aonv * aonv
            var temp1 = 3.0 * xno2 * ainv2
            var temp = temp1 * root22
            out.d2201 = temp * f220 * g201
            out.d2211 = temp * f221 * g211
            temp1 *= aonv
            temp = temp1 * root32
            out.d3210 = temp * f321 * g310
            out.d3222 = temp * f322 * g322
            temp1 *= aonv
            temp = 2.0 * temp1 * root44
            out.d4410 = temp * f441 * g410
            out.d4422 = temp * f442 * g422
            temp1 *= aonv
            temp = temp1 * root52
            out.d5220 = temp * f522 * g520
            out.d5232 = temp * f523 * g532
            temp = 2.0 * temp1 * root54
            out.d5421 = temp * f542 * g521
            out.d5433 = temp * f543 * g533
            out.xlamo = (elements.mo + elements.nodeo + elements.nodeo - theta - theta)
                .truncatingRemainder(dividingBy: twoPi)
            out.xfact = elements.mdot + out.dmdt + 2.0 * (elements.nodedot + out.dnodt - rptim) - elements.noUnkozai
        }

        // ---------------- synchronous resonance terms --------------
        if out.irez == 1 {
            let g200 = 1.0 + emsq * (-2.5 + 0.8125 * emsq)
            let g310 = 1.0 + 2.0 * emsq
            let g300 = 1.0 + emsq * (-6.0 + 6.60937 * emsq)
            let f220 = 0.75 * (1.0 + cosim) * (1.0 + cosim)
            let f311 = 0.9375 * sinim * sinim * (1.0 + 3.0 * cosim) - 0.75 * (1.0 + cosim)
            var f330 = 1.0 + cosim
            f330 = 1.875 * f330 * f330 * f330
            var del1 = 3.0 * nm * nm * aonv * aonv
            out.del2 = 2.0 * del1 * f220 * g200 * q22
            out.del3 = 3.0 * del1 * f330 * g300 * q33 * aonv
            del1 = del1 * f311 * g310 * q31 * aonv
            out.del1 = del1
            out.xlamo = (elements.mo + elements.nodeo + elements.argpo - theta).truncatingRemainder(dividingBy: twoPi)
            out.xfact = elements.mdot + xpidot - rptim + out.dmdt + out.domdt + out.dnodt - elements.noUnkozai
        }

        return out
    }
}

// MARK: - dspace

extension SGP4 {
    /// Applies deep-space secular effects and integrates the resonance equations.
    ///
    /// Port of `dspace` from sgp4unit.cpp. The reference implementation caches the
    /// integrator state (`atime`, `xli`, `xni`) between calls; this version always
    /// integrates from epoch, which gives identical results (the 720-minute step grid
    /// is the same) and keeps `SGP4` a pure value type that is safe to share.
    ///
    /// - Parameters:
    ///   - mean: Mean elements after near-Earth secular updates, updated in place
    ///   - t: Minutes since epoch
    ///   - elements: Initialized elements, including the deep-space terms
    static func dspace(_ mean: inout SGP4MeanElements, t: Double, elements: SGP4Elements) {
        let fasx2 = 0.13130908
        let fasx4 = 2.8843198
        let fasx6 = 0.37448087
        let g22 = 5.7686396
        let g32 = 0.95240898
        let g44 = 1.8014998
        let g52 = 1.0508330
        let g54 = 4.4108898
        let rptim = 4.37526908801129966e-3 // Earth rotation rate, rad/min
        let stepp = 720.0
        let stepn = -720.0
        let step2 = 259200.0

        let res = elements.resonance
        let tc = t

        // ----------- calculate deep space resonance effects -----------
        let theta = (elements.gsto + tc * rptim).truncatingRemainder(dividingBy: twoPi)
        mean.em += res.dedt * t
        mean.inclm += res.didt * t
        mean.argpm += res.domdt * t
        mean.nodem += res.dnodt * t
        mean.mm += res.dmdt * t

        guard res.irez != 0 else {
            return
        }

        // Numerical integration of the resonance terms in 720-minute steps from epoch
        var atime = 0.0
        var xni = elements.noUnkozai
        var xli = res.xlamo
        let delt = t > 0.0 ? stepp : stepn

        var xndt = 0.0
        var xldot = 0.0
        var xnddt = 0.0
        var ft = 0.0
        while true {
            // ------------------- dot terms calculated -------------
            if res.irez != 2 {
                // ----------- near-synchronous resonance terms -------
                xndt = res.del1 * sin(xli - fasx2) + res.del2 * sin(2.0 * (xli - fasx4)) +
                    res.del3 * sin(3.0 * (xli - fasx6))
                xldot = xni + res.xfact
                xnddt = res.del1 * cos(xli - fasx2) +
                    2.0 * res.del2 * cos(2.0 * (xli - fasx4)) +
                    3.0 * res.del3 * cos(3.0 * (xli - fasx6))
                xnddt *= xldot
            } else {
                // --------- near-half-day resonance terms ------------
                let xomi = elements.argpo + elements.argpdot * atime
                let x2omi = xomi + xomi
                let x2li = xli + xli
                xndt = res.d2201 * sin(x2omi + xli - g22) + res.d2211 * sin(xli - g22) +
                    res.d3210 * sin(xomi + xli - g32) + res.d3222 * sin(-xomi + xli - g32) +
                    res.d4410 * sin(x2omi + x2li - g44) + res.d4422 * sin(x2li - g44) +
                    res.d5220 * sin(xomi + xli - g52) + res.d5232 * sin(-xomi + xli - g52) +
                    res.d5421 * sin(xomi + x2li - g54) + res.d5433 * sin(-xomi + x2li - g54)
                xldot = xni + res.xfact
                xnddt = res.d2201 * cos(x2omi + xli - g22) + res.d2211 * cos(xli - g22) +
                    res.d3210 * cos(xomi + xli - g32) + res.d3222 * cos(-xomi + xli - g32) +
                    res.d5220 * cos(xomi + xli - g52) + res.d5232 * cos(-xomi + xli - g52) +
                    2.0 * (res.d4410 * cos(x2omi + x2li - g44) +
                    res.d4422 * cos(x2li - g44) + res.d5421 * cos(xomi + x2li - g54) +
                    res.d5433 * cos(-xomi + x2li - g54))
                xnddt *= xldot
            }

            // ----------------------- integrator -------------------
            if abs(t - atime) >= stepp {
                xli = xli + xldot * delt + xndt * step2
                xni = xni + xndt * delt + xnddt * step2
                atime += delt
            } else {
                ft = t - atime
                break
            }
        }

        mean.nm = xni + xndt * ft + xnddt * ft * ft * 0.5
        let xl = xli + xldot * ft + xndt * ft * ft * 0.5
        if res.irez != 1 {
            mean.mm = xl - 2.0 * mean.nodem + 2.0 * theta
        } else {
            mean.mm = xl - mean.nodem - mean.argpm + theta
        }
        // nm = no + dndt, where dndt = nm - no: kept as in the reference for identical rounding
        let dndt = mean.nm - elements.noUnkozai
        mean.nm = elements.noUnkozai + dndt
    }
}
