//
//  SGP4+DeepSpace.swift
//  Ephemeris
//
//  Deep-space (SDP4) extensions to SGP4: lunar and solar periodic perturbations for
//  orbits with periods of 225 minutes or more. The resonance terms for 12-hour and
//  24-hour orbits live in SGP4+Resonance.swift.
//
//  These routines are a direct port of dscom and dpper from
//  Vallado's sgp4unit.cpp (Vallado, Crawford, Hujsak, Kelso, AIAA 2006-6753).
//  Variable names deliberately match the reference so each line can be checked
//  against it; the math is not meant to be read without the paper alongside.
//

import Foundation

// MARK: - Deep-Space State

/// Lunar and solar periodic coefficients computed once by `dscom` and applied by `dpper`.
struct SGP4LunarSolarTerms: Sendable {
    var e3 = 0.0, ee2 = 0.0
    var se2 = 0.0, se3 = 0.0
    var sgh2 = 0.0, sgh3 = 0.0, sgh4 = 0.0
    var sh2 = 0.0, sh3 = 0.0
    var si2 = 0.0, si3 = 0.0
    var sl2 = 0.0, sl3 = 0.0, sl4 = 0.0
    var xgh2 = 0.0, xgh3 = 0.0, xgh4 = 0.0
    var xh2 = 0.0, xh3 = 0.0
    var xi2 = 0.0, xi3 = 0.0
    var xl2 = 0.0, xl3 = 0.0, xl4 = 0.0
    // Mean anomalies of the Moon and Sun at epoch
    var zmol = 0.0, zmos = 0.0
}

/// Secular rates and resonance coefficients computed once by `dsinit` and used by `dspace`.
struct SGP4ResonanceTerms: Sendable {
    /// 0 = none, 1 = one-day (geosynchronous), 2 = half-day (Molniya, GPS)
    var irez = 0
    var d2201 = 0.0, d2211 = 0.0, d3210 = 0.0, d3222 = 0.0, d4410 = 0.0
    var d4422 = 0.0, d5220 = 0.0, d5232 = 0.0, d5421 = 0.0, d5433 = 0.0
    var del1 = 0.0, del2 = 0.0, del3 = 0.0
    var xfact = 0.0, xlamo = 0.0
    // Secular rates of change of the mean elements from lunar-solar gravity
    var dedt = 0.0, didt = 0.0, dmdt = 0.0, dnodt = 0.0, domdt = 0.0
}

/// Intermediate values from `dscom` that `dsinit` needs.
struct SGP4DeepSpaceCommon {
    var lunarSolar = SGP4LunarSolarTerms()
    var sinim = 0.0, cosim = 0.0, emsq = 0.0
    var s1 = 0.0, s2 = 0.0, s3 = 0.0, s4 = 0.0, s5 = 0.0
    var ss1 = 0.0, ss2 = 0.0, ss3 = 0.0, ss4 = 0.0, ss5 = 0.0
    var sz1 = 0.0, sz3 = 0.0, sz11 = 0.0, sz13 = 0.0, sz21 = 0.0, sz23 = 0.0, sz31 = 0.0, sz33 = 0.0
    var z1 = 0.0, z3 = 0.0, z11 = 0.0, z13 = 0.0, z21 = 0.0, z23 = 0.0, z31 = 0.0, z33 = 0.0
}

/// Mean elements being updated during a propagation step (radians, rad/min).
struct SGP4MeanElements {
    var em: Double
    var argpm: Double
    var inclm: Double
    var mm: Double
    var nodem: Double
    var nm: Double
}

/// Osculating-ish elements after lunar-solar periodics are applied by `dpper`.
struct SGP4PerturbedElements {
    var ep: Double
    var inclp: Double
    var nodep: Double
    var argpp: Double
    var mp: Double
}

// MARK: - dscom

extension SGP4 {
    /// Computes lunar and solar terms common to the secular and periodic deep-space effects.
    ///
    /// Port of `dscom` from sgp4unit.cpp. Only called at initialization, so `tc` is 0.
    ///
    /// - Parameters:
    ///   - epoch: Days since 1949 December 31 00:00 UT
    ///   - elements: Elements after `initl` (uses ecco, argpo, inclo, nodeo, noUnkozai)
    /// - Returns: Lunar-solar coefficients and intermediate terms for `dsinit`
    static func dscom(epoch: Double, elements: SGP4Elements) -> SGP4DeepSpaceCommon {
        let zes = 0.01675
        let zel = 0.05490
        let c1ss = 2.9864797e-6
        let c1l = 4.7968065e-7
        let zsinis = 0.39785416
        let zcosis = 0.91744867
        let zcosgs = 0.1945905
        let zsings = -0.98088458
        let tc = 0.0

        var out = SGP4DeepSpaceCommon()
        let nm = elements.noUnkozai
        let em = elements.ecco
        let snodm = sin(elements.nodeo)
        let cnodm = cos(elements.nodeo)
        let sinomm = sin(elements.argpo)
        let cosomm = cos(elements.argpo)
        let sinim = sin(elements.inclo)
        let cosim = cos(elements.inclo)
        let emsq = em * em
        let betasq = 1.0 - emsq
        let rtemsq = sqrt(betasq)

        // ----------------- initialize lunar solar terms ---------------
        let day = epoch + 18261.5 + tc / 1440.0
        let xnodce = (4.5236020 - 9.2422029e-4 * day).truncatingRemainder(dividingBy: twoPi)
        let stem = sin(xnodce)
        let ctem = cos(xnodce)
        let zcosil = 0.91375164 - 0.03568096 * ctem
        let zsinil = sqrt(1.0 - zcosil * zcosil)
        let zsinhl = 0.089683511 * stem / zsinil
        let zcoshl = sqrt(1.0 - zsinhl * zsinhl)
        let gam = 5.8351514 + 0.0019443680 * day
        var zx = 0.39785416 * stem / zsinil
        let zy = zcoshl * ctem + 0.91744867 * zsinhl * stem
        zx = atan2(zx, zy)
        zx = gam + zx - xnodce
        let zcosgl = cos(zx)
        let zsingl = sin(zx)

        // ------------------------- do solar terms ---------------------
        var zcosg = zcosgs
        var zsing = zsings
        var zcosi = zcosis
        var zsini = zsinis
        var zcosh = cnodm
        var zsinh = snodm
        var cc = c1ss
        let xnoi = 1.0 / nm

        // Two passes: first the Sun (lsflg 1), then the Moon (lsflg 2)
        for lsflg in 1...2 {
            let a1 = zcosg * zcosh + zsing * zcosi * zsinh
            let a3 = -zsing * zcosh + zcosg * zcosi * zsinh
            let a7 = -zcosg * zsinh + zsing * zcosi * zcosh
            let a8 = zsing * zsini
            let a9 = zsing * zsinh + zcosg * zcosi * zcosh
            let a10 = zcosg * zsini
            let a2 = cosim * a7 + sinim * a8
            let a4 = cosim * a9 + sinim * a10
            let a5 = -sinim * a7 + cosim * a8
            let a6 = -sinim * a9 + cosim * a10

            let x1 = a1 * cosomm + a2 * sinomm
            let x2 = a3 * cosomm + a4 * sinomm
            let x3 = -a1 * sinomm + a2 * cosomm
            let x4 = -a3 * sinomm + a4 * cosomm
            let x5 = a5 * sinomm
            let x6 = a6 * sinomm
            let x7 = a5 * cosomm
            let x8 = a6 * cosomm

            let z31 = 12.0 * x1 * x1 - 3.0 * x3 * x3
            let z32 = 24.0 * x1 * x2 - 6.0 * x3 * x4
            let z33 = 12.0 * x2 * x2 - 3.0 * x4 * x4
            var z1 = 3.0 * (a1 * a1 + a2 * a2) + z31 * emsq
            var z2 = 6.0 * (a1 * a3 + a2 * a4) + z32 * emsq
            var z3 = 3.0 * (a3 * a3 + a4 * a4) + z33 * emsq
            let z11 = -6.0 * a1 * a5 + emsq * (-24.0 * x1 * x7 - 6.0 * x3 * x5)
            let z12 = -6.0 * (a1 * a6 + a3 * a5) + emsq *
                (-24.0 * (x2 * x7 + x1 * x8) - 6.0 * (x3 * x6 + x4 * x5))
            let z13 = -6.0 * a3 * a6 + emsq * (-24.0 * x2 * x8 - 6.0 * x4 * x6)
            let z21 = 6.0 * a2 * a5 + emsq * (24.0 * x1 * x5 - 6.0 * x3 * x7)
            let z22 = 6.0 * (a4 * a5 + a2 * a6) + emsq *
                (24.0 * (x2 * x5 + x1 * x6) - 6.0 * (x4 * x7 + x3 * x8))
            let z23 = 6.0 * a4 * a6 + emsq * (24.0 * x2 * x6 - 6.0 * x4 * x8)
            z1 = z1 + z1 + betasq * z31
            z2 = z2 + z2 + betasq * z32
            z3 = z3 + z3 + betasq * z33
            let s3 = cc * xnoi
            let s2 = -0.5 * s3 / rtemsq
            let s4 = s3 * rtemsq
            let s1 = -15.0 * em * s4
            let s5 = x1 * x3 + x2 * x4
            let s6 = x2 * x3 + x1 * x4
            let s7 = x2 * x4 - x1 * x3

            if lsflg == 1 {
                // ------------------ solar terms ----------------------
                let ss1 = s1, ss2 = s2, ss3 = s3, ss4 = s4
                out.ss1 = ss1
                out.ss2 = ss2
                out.ss3 = ss3
                out.ss4 = ss4
                out.ss5 = s5
                out.sz1 = z1
                out.sz3 = z3
                out.sz11 = z11
                out.sz13 = z13
                out.sz21 = z21
                out.sz23 = z23
                out.sz31 = z31
                out.sz33 = z33

                out.lunarSolar.se2 = 2.0 * ss1 * s6
                out.lunarSolar.se3 = 2.0 * ss1 * s7
                out.lunarSolar.si2 = 2.0 * ss2 * z12
                out.lunarSolar.si3 = 2.0 * ss2 * (z13 - z11)
                out.lunarSolar.sl2 = -2.0 * ss3 * z2
                out.lunarSolar.sl3 = -2.0 * ss3 * (z3 - z1)
                out.lunarSolar.sl4 = -2.0 * ss3 * (-21.0 - 9.0 * emsq) * zes
                out.lunarSolar.sgh2 = 2.0 * ss4 * z32
                out.lunarSolar.sgh3 = 2.0 * ss4 * (z33 - z31)
                out.lunarSolar.sgh4 = -18.0 * ss4 * zes
                out.lunarSolar.sh2 = -2.0 * ss2 * z22
                out.lunarSolar.sh3 = -2.0 * ss2 * (z23 - z21)

                // Switch the geometry over to the Moon for the second pass
                zcosg = zcosgl
                zsing = zsingl
                zcosi = zcosil
                zsini = zsinil
                zcosh = zcoshl * cnodm + zsinhl * snodm
                zsinh = snodm * zcoshl - cnodm * zsinhl
                cc = c1l
            } else {
                // ------------------ lunar terms ----------------------
                out.s1 = s1
                out.s2 = s2
                out.s3 = s3
                out.s4 = s4
                out.s5 = s5
                out.z1 = z1
                out.z3 = z3
                out.z11 = z11
                out.z13 = z13
                out.z21 = z21
                out.z23 = z23
                out.z31 = z31
                out.z33 = z33

                out.lunarSolar.ee2 = 2.0 * s1 * s6
                out.lunarSolar.e3 = 2.0 * s1 * s7
                out.lunarSolar.xi2 = 2.0 * s2 * z12
                out.lunarSolar.xi3 = 2.0 * s2 * (z13 - z11)
                out.lunarSolar.xl2 = -2.0 * s3 * z2
                out.lunarSolar.xl3 = -2.0 * s3 * (z3 - z1)
                out.lunarSolar.xl4 = -2.0 * s3 * (-21.0 - 9.0 * emsq) * zel
                out.lunarSolar.xgh2 = 2.0 * s4 * z32
                out.lunarSolar.xgh3 = 2.0 * s4 * (z33 - z31)
                out.lunarSolar.xgh4 = -18.0 * s4 * zel
                out.lunarSolar.xh2 = -2.0 * s2 * z22
                out.lunarSolar.xh3 = -2.0 * s2 * (z23 - z21)
            }
        }

        out.lunarSolar.zmol = (4.7199672 + 0.22997150 * day - gam).truncatingRemainder(dividingBy: twoPi)
        out.lunarSolar.zmos = (6.2565837 + 0.017201977 * day).truncatingRemainder(dividingBy: twoPi)
        out.sinim = sinim
        out.cosim = cosim
        out.emsq = emsq
        return out
    }
}

// MARK: - dpper

extension SGP4 {
    /// Applies lunar and solar long-period periodics to the mean elements.
    ///
    /// Port of `dpper` from sgp4unit.cpp with `init == 'n'`. (The initialization call in
    /// `sgp4init` leaves the elements unchanged, so it is omitted.) The `peo`, `pinco`,
    /// `plo`, `pgho` and `pho` offsets are always zero after `dscom`, so subtracting them
    /// is also omitted.
    ///
    /// - Parameters:
    ///   - elements: Elements to perturb, updated in place
    ///   - t: Minutes since epoch
    ///   - terms: Lunar-solar coefficients from `dscom`
    ///   - mode: Operation mode, which changes how the node is wrapped at low inclination
    static func dpper(_ elements: inout SGP4PerturbedElements, t: Double,
                      terms: SGP4LunarSolarTerms, mode: OperationMode) {
        let zns = 1.19459e-5
        let zes = 0.01675
        let znl = 1.5835218e-4
        let zel = 0.05490

        // --------------- calculate time varying periodics -----------
        var zm = terms.zmos + zns * t
        var zf = zm + 2.0 * zes * sin(zm)
        var sinzf = sin(zf)
        var f2 = 0.5 * sinzf * sinzf - 0.25
        var f3 = -0.5 * sinzf * cos(zf)
        let ses = terms.se2 * f2 + terms.se3 * f3
        let sis = terms.si2 * f2 + terms.si3 * f3
        let sls = terms.sl2 * f2 + terms.sl3 * f3 + terms.sl4 * sinzf
        let sghs = terms.sgh2 * f2 + terms.sgh3 * f3 + terms.sgh4 * sinzf
        let shs = terms.sh2 * f2 + terms.sh3 * f3

        zm = terms.zmol + znl * t
        zf = zm + 2.0 * zel * sin(zm)
        sinzf = sin(zf)
        f2 = 0.5 * sinzf * sinzf - 0.25
        f3 = -0.5 * sinzf * cos(zf)
        let sel = terms.ee2 * f2 + terms.e3 * f3
        let sil = terms.xi2 * f2 + terms.xi3 * f3
        let sll = terms.xl2 * f2 + terms.xl3 * f3 + terms.xl4 * sinzf
        let sghl = terms.xgh2 * f2 + terms.xgh3 * f3 + terms.xgh4 * sinzf
        let shll = terms.xh2 * f2 + terms.xh3 * f3

        let pe = ses + sel
        let pinc = sis + sil
        let pl = sls + sll
        var pgh = sghs + sghl
        var ph = shs + shll

        elements.inclp += pinc
        elements.ep += pe
        let sinip = sin(elements.inclp)
        let cosip = cos(elements.inclp)

        // ----------------- apply periodics directly ------------
        // Lyddane modification: below 0.2 rad (11.46°) inclination the node and argument
        // of perigee are poorly defined, so periodics are applied in a nonsingular form.
        if elements.inclp >= 0.2 {
            ph /= sinip
            pgh -= cosip * ph
            elements.argpp += pgh
            elements.nodep += ph
            elements.mp += pl
        } else {
            // ---- apply periodics with lyddane modification ----
            let sinop = sin(elements.nodep)
            let cosop = cos(elements.nodep)
            var alfdp = sinip * sinop
            var betdp = sinip * cosop
            let dalf = ph * cosop + pinc * cosip * sinop
            let dbet = -ph * sinop + pinc * cosip * cosop
            alfdp += dalf
            betdp += dbet
            elements.nodep = elements.nodep.truncatingRemainder(dividingBy: twoPi)
            // AFSPC mode wraps negative nodes into 0...2π
            if elements.nodep < 0.0 && mode == .afspc {
                elements.nodep += twoPi
            }
            let xls = elements.mp + elements.argpp + pl + pgh + (cosip - pinc * sinip) * elements.nodep
            let xnoh = elements.nodep
            elements.nodep = atan2(alfdp, betdp)
            if elements.nodep < 0.0 && mode == .afspc {
                elements.nodep += twoPi
            }
            if abs(xnoh - elements.nodep) > .pi {
                if elements.nodep < xnoh {
                    elements.nodep += twoPi
                } else {
                    elements.nodep -= twoPi
                }
            }
            elements.mp += pl
            elements.argpp = xls - elements.mp - cosip * elements.nodep
        }
    }
}
