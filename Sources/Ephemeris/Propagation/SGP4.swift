//
//  SGP4.swift
//  Ephemeris
//
//  The SGP4/SDP4 orbit propagator for Two-Line Element sets.
//
//  This is a port of Vallado's sgp4unit.cpp (sgp4init, initl and sgp4), the reference
//  implementation described in Vallado, Crawford, Hujsak, Kelso, "Revisiting Spacetrack
//  Report #3", AIAA 2006-6753. Internal variable names match the reference so each line
//  can be checked against it. Results are verified against Vallado's published test
//  vectors (SGP4-VER.TLE / tcppver.out) in SGP4VerificationTests.
//

import Foundation

/// 2π, used throughout the SGP4 port
let twoPi = 2.0 * Double.pi

/// Degrees to radians, written as a single multiplier to match the reference rounding
private let deg2rad = Double.pi / 180.0

/// Errors reported by the SGP4 propagator.
///
/// The raw codes match those used by the reference implementation.
public enum SGP4Error: Error, Equatable, Sendable {
    /// Mean eccentricity left the range 0 ≤ e < 1 (code 1)
    case meanEccentricityOutOfRange(Double)
    /// Mean motion became zero or negative (code 2)
    case meanMotionNotPositive(Double)
    /// Eccentricity after lunar-solar periodics left the range 0 ≤ e ≤ 1 (code 3)
    case perturbedEccentricityOutOfRange(Double)
    /// Semi-latus rectum became negative (code 4)
    case semiLatusRectumNegative(Double)
    /// Orbital radius dropped below one Earth radius: the satellite has decayed (code 6)
    case decayed(radiusEarthRadii: Double)

    /// Error code used by the reference implementation
    public var code: Int {
        switch self {
        case .meanEccentricityOutOfRange: return 1
        case .meanMotionNotPositive: return 2
        case .perturbedEccentricityOutOfRange: return 3
        case .semiLatusRectumNegative: return 4
        case .decayed: return 6
        }
    }
}

extension SGP4Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .meanEccentricityOutOfRange(let value):
            return "SGP4: mean eccentricity \(value) is outside 0 ≤ e < 1"
        case .meanMotionNotPositive(let value):
            return "SGP4: mean motion \(value) is not positive"
        case .perturbedEccentricityOutOfRange(let value):
            return "SGP4: perturbed eccentricity \(value) is outside 0 ≤ e ≤ 1"
        case .semiLatusRectumNegative(let value):
            return "SGP4: semi-latus rectum \(value) is negative"
        case .decayed(let radius):
            return "SGP4: orbit radius \(radius) Earth radii is below the surface; the satellite has decayed"
        }
    }
}

/// Initialized SGP4 element set (the reference implementation's `elsetrec`).
///
/// Angles are in radians, mean motion in radians per minute, distances in Earth radii.
struct SGP4Elements: Sendable {
    var gravity: GravityModel

    // Elements from the TLE
    var bstar = 0.0
    var ecco = 0.0
    var argpo = 0.0
    var inclo = 0.0
    var mo = 0.0
    var noKozai = 0.0
    var nodeo = 0.0

    // Near-Earth constants from sgp4init
    var noUnkozai = 0.0
    var isimp = false
    var isDeepSpace = false
    var aycof = 0.0, con41 = 0.0, cc1 = 0.0, cc4 = 0.0, cc5 = 0.0
    var d2 = 0.0, d3 = 0.0, d4 = 0.0, delmo = 0.0, eta = 0.0
    var argpdot = 0.0, omgcof = 0.0, sinmao = 0.0
    var t2cof = 0.0, t3cof = 0.0, t4cof = 0.0, t5cof = 0.0
    var x1mth2 = 0.0, x7thm1 = 0.0, mdot = 0.0, nodedot = 0.0
    var xlcof = 0.0, xmcof = 0.0, nodecf = 0.0
    /// Greenwich sidereal time at epoch (rad)
    var gsto = 0.0

    // Deep-space terms (only used when isDeepSpace)
    var lunarSolar = SGP4LunarSolarTerms()
    var resonance = SGP4ResonanceTerms()

    init(gravity: GravityModel) {
        self.gravity = gravity
    }
}

/// The SGP4/SDP4 propagator: the standard model for Two-Line Element sets.
///
/// TLEs are not plain Keplerian elements. They are mean elements fitted with SGP4's
/// own simplified physics, so SGP4 is the only propagator that reproduces the orbit
/// they describe. It models:
/// - Earth's oblateness (J2, J3, J4 zonal harmonics), which turns the orbital plane
///   and rotates the perigee by several degrees per day in low orbits
/// - Atmospheric drag through the TLE's B* term
/// - For periods of 225 minutes or more (SDP4): lunar and solar gravity, plus
///   resonance effects for 12-hour and 24-hour orbits
///
/// Expect about 1 km of error at epoch, growing by roughly 1-3 km per day in low
/// Earth orbit. Refresh TLEs often for antenna pointing.
///
/// ## Example
/// ```swift
/// let tle = try TwoLineElement(from: tleString)
/// let sgp4 = try SGP4(tle: tle)
///
/// // Inertial (TEME) state 90 minutes after the TLE epoch
/// let state = try sgp4.propagate(minutesSinceEpoch: 90)
///
/// // Everything on Propagator works too
/// let position = try sgp4.calculatePosition(at: Date())
/// let passes = try sgp4.predictPasses(for: observer, from: start, to: end)
/// ```
///
/// - Note: Velocity comes from SGP4's own analytic expressions, not from differentiating
///         position, and the two agree to about 2 cm/s. That is negligible for Doppler
///         (about 0.03 Hz at 437 MHz).
/// - Note: Output is in the TEME (True Equator, Mean Equinox) frame. Rotating by
///         Greenwich Mean Sidereal Time converts TEME to Earth-fixed coordinates.
public struct SGP4: Propagator, Sendable {

    // MARK: - Nested Types

    /// Selects between the original operational behavior and Vallado's improvements.
    public enum OperationMode: Sendable {
        /// Air Force Space Command mode: reproduces the original operational code,
        /// including its sidereal time formula and node wrapping.
        case afspc
        /// Improved mode (default): the corrections recommended by Vallado et al. 2006.
        case improved
    }

    // MARK: - Properties

    /// The TLE epoch, the reference time for propagation
    public let epoch: Date

    /// Gravity constants used for propagation
    public let gravity: GravityModel

    /// Operation mode used for propagation
    public let operationMode: OperationMode

    /// True when the orbital period is 225 minutes or more, so the deep-space (SDP4)
    /// lunar-solar and resonance terms are active
    public var isDeepSpace: Bool {
        return elements.isDeepSpace
    }

    /// Initialized element set
    let elements: SGP4Elements

    // MARK: - Initialization

    /// Creates an SGP4 propagator from a parsed TLE.
    ///
    /// - Parameters:
    ///   - tle: The Two-Line Element set to propagate
    ///   - gravity: Gravity constants (default `.wgs72`, which TLEs are fitted with)
    ///   - operationMode: `.improved` (default) or `.afspc` for legacy behavior
    /// - Throws: `SGP4Error` if the elements cannot be propagated even at epoch
    public init(tle: TwoLineElement, gravity: GravityModel = .wgs72, operationMode: OperationMode = .improved) throws {
        // Minutes per day / radians per revolution: converts rev/day to rad/min
        let xpdotp = 1440.0 / (2.0 * Double.pi)

        // Days since 1949 December 31 00:00 UT, the time base SGP4 uses internally
        let daysSince1950 = Self.referenceJulianDate(year: tle.epochYear, dayOfYear: tle.epochDayOfYear) - 2433281.5

        self.epoch = tle.epoch
        self.gravity = gravity
        self.operationMode = operationMode

        var elements = SGP4Elements(gravity: gravity)
        elements.bstar = tle.bstarDragTerm
        elements.ecco = tle.eccentricity
        elements.argpo = tle.argumentOfPerigee * deg2rad
        elements.inclo = tle.inclination * deg2rad
        elements.mo = tle.meanAnomaly * deg2rad
        elements.noKozai = tle.meanMotion / xpdotp
        elements.nodeo = tle.rightAscensionOfAscendingNode * deg2rad

        self.elements = Self.sgp4init(elements, epoch: daysSince1950, mode: operationMode)

        // The reference implementation propagates to epoch during initialization to
        // catch element sets that are invalid from the start
        _ = try propagate(minutesSinceEpoch: 0.0)
    }

    // MARK: - Propagation

    /// Computes the TEME state vector a given number of minutes from the TLE epoch.
    ///
    /// - Parameter tsince: Minutes since epoch (negative values propagate backward)
    /// - Returns: Position (km) and velocity (km/s) in the TEME frame
    /// - Throws: `SGP4Error` if the orbit has decayed or the elements become invalid
    public func propagate(minutesSinceEpoch tsince: Double) throws -> StateVector {
        try Self.sgp4(elements, tsince: tsince, mode: operationMode)
    }

    /// Computes the TEME state vector at a given time.
    ///
    /// - Parameter date: The time of interest
    /// - Returns: Position (km) and velocity (km/s) in the TEME frame
    /// - Throws: `SGP4Error` if the orbit has decayed or the elements become invalid
    public func stateVector(at date: Date) throws -> StateVector {
        try propagate(minutesSinceEpoch: date.timeIntervalSince(epoch) / 60.0)
    }
}

// MARK: - Propagation (sgp4)

extension SGP4 {
    /// Propagates initialized elements to a time since epoch. Port of `sgp4` from sgp4unit.cpp.
    ///
    /// The steps, in order:
    /// 1. **Secular effects**: J2/J4 make the mean anomaly, perigee and node drift
    ///    linearly; drag shrinks the orbit and adds powers of t to the mean longitude.
    /// 2. **Deep space** (long periods only): lunar-solar secular rates and resonance.
    /// 3. **Long-period periodics**: J3 terms, plus lunar-solar periodics in deep space.
    /// 4. **Kepler's equation**, solved in a form that has no singularity at e = 0.
    /// 5. **Short-period periodics**: J2 wobbles within one orbit.
    /// 6. **Orientation vectors**: turn radius, argument of latitude, node and inclination
    ///    into Cartesian position and velocity.
    ///
    /// - Parameters:
    ///   - rec: Initialized elements
    ///   - tsince: Minutes since epoch
    ///   - mode: Operation mode
    /// - Returns: Position (km) and velocity (km/s) in TEME
    /// - Throws: `SGP4Error` when the elements become invalid
    static func sgp4(_ rec: SGP4Elements, tsince: Double, mode: OperationMode) throws -> StateVector {
        let grav = rec.gravity
        let temp4 = 1.5e-12
        let x2o3 = 2.0 / 3.0
        let vkmpersec = grav.radiusEarthKm * grav.xke / 60.0
        let t = tsince

        // ------- update for secular gravity and atmospheric drag -----
        // Mean anomaly, argument of perigee and node advance at the constant J2/J4 rates
        // from initialization. Drag also pulls the node (nodecf·t²).
        let xmdf = rec.mo + rec.mdot * t
        let argpdf = rec.argpo + rec.argpdot * t
        let nodedf = rec.nodeo + rec.nodedot * t
        var argpm = argpdf
        var mm = xmdf
        let t2 = t * t
        var nodem = nodedf + rec.nodecf * t2
        var tempa = 1.0 - rec.cc1 * t
        var tempe = rec.bstar * rec.cc4 * t
        var templ = rec.t2cof * t2

        if !rec.isimp {
            // Full drag model: perigee and mean anomaly corrections, and the higher powers
            // of t that shrink the orbit (tempa), circularize it (tempe) and speed up the
            // satellite (templ)
            let delomg = rec.omgcof * t
            let delmtemp = 1.0 + rec.eta * cos(xmdf)
            let delm = rec.xmcof * (delmtemp * delmtemp * delmtemp - rec.delmo)
            let temp = delomg + delm
            mm = xmdf + temp
            argpm = argpdf - temp
            let t3 = t2 * t
            let t4 = t3 * t
            tempa = tempa - rec.d2 * t2 - rec.d3 * t3 - rec.d4 * t4
            tempe += rec.bstar * rec.cc5 * (sin(mm) - rec.sinmao)
            templ = templ + rec.t3cof * t3 + t4 * (rec.t4cof + t * rec.t5cof)
        }

        var mean = SGP4MeanElements(em: rec.ecco, argpm: argpm, inclm: rec.inclo,
                                    mm: mm, nodem: nodem, nm: rec.noUnkozai)
        if rec.isDeepSpace {
            dspace(&mean, t: t, elements: rec)
        }

        // Apply drag. tempa scales the semi-major axis, and Kepler's third law gives the
        // matching mean motion: n = ke / a^(3/2)
        if mean.nm <= 0.0 {
            throw SGP4Error.meanMotionNotPositive(mean.nm)
        }
        let am = pow(grav.xke / mean.nm, x2o3) * tempa * tempa
        let nm = grav.xke / pow(am, 1.5)
        var em = mean.em - tempe

        // Fix tolerance for error recognition
        if em >= 1.0 || em < -0.001 {
            throw SGP4Error.meanEccentricityOutOfRange(em)
        }
        // Avoid a divide by zero
        if em < 1.0e-6 {
            em = 1.0e-6
        }
        mm = mean.mm + rec.noUnkozai * templ
        argpm = mean.argpm
        nodem = mean.nodem
        let inclm = mean.inclm
        var xlm = mm + argpm + nodem

        nodem = nodem.truncatingRemainder(dividingBy: twoPi)
        argpm = argpm.truncatingRemainder(dividingBy: twoPi)
        xlm = xlm.truncatingRemainder(dividingBy: twoPi)
        mm = (xlm - argpm - nodem).truncatingRemainder(dividingBy: twoPi)

        // ----------------- compute extra mean quantities -------------
        // xlm is the mean longitude (M + ω + Ω). Wrapping each angle into 0…2π keeps
        // precision for long propagations.
        let sinim = sin(inclm)
        let cosim = cos(inclm)

        // -------------------- add lunar-solar periodics --------------
        // For deep space, the Moon and Sun add slow oscillations to every element. A
        // negative inclination after this step is folded back by flipping the node.
        var perturbed = SGP4PerturbedElements(ep: em, inclp: inclm, nodep: nodem, argpp: argpm, mp: mm)
        var sinip = sinim
        var cosip = cosim
        var aycof = rec.aycof
        var xlcof = rec.xlcof
        var con41 = rec.con41
        var x1mth2 = rec.x1mth2
        var x7thm1 = rec.x7thm1

        if rec.isDeepSpace {
            dpper(&perturbed, t: t, terms: rec.lunarSolar, mode: mode)
            if perturbed.inclp < 0.0 {
                perturbed.inclp = -perturbed.inclp
                perturbed.nodep += .pi
                perturbed.argpp -= .pi
            }
            if perturbed.ep < 0.0 || perturbed.ep > 1.0 {
                throw SGP4Error.perturbedEccentricityOutOfRange(perturbed.ep)
            }

            // -------------------- long period periodics ------------------
            sinip = sin(perturbed.inclp)
            cosip = cos(perturbed.inclp)
            aycof = -0.5 * grav.j3oj2 * sinip
            // sgp4fix for divide by zero for xincp = 180 deg
            if abs(cosip + 1.0) > 1.5e-12 {
                xlcof = -0.25 * grav.j3oj2 * sinip * (3.0 + 5.0 * cosip) / (1.0 + cosip)
            } else {
                xlcof = -0.25 * grav.j3oj2 * sinip * (3.0 + 5.0 * cosip) / temp4
            }
        }

        let ep = perturbed.ep
        let xincp = perturbed.inclp
        let nodep = perturbed.nodep
        let argpp = perturbed.argpp
        let mp = perturbed.mp

        // Long-period J3 periodics in nonsingular form. Instead of e and ω, which are poorly
        // defined for near-circular orbits, use the components
        //     axn = e·cos ω
        //     ayn = e·sin ω + (J3 correction)
        // and the corrected mean longitude xl = M + ω + Ω + (J3 correction).
        let axnl = ep * cos(argpp)
        var temp = 1.0 / (am * (1.0 - ep * ep))
        let aynl = ep * sin(argpp) + temp * aycof
        let xl = mp + argpp + nodep + temp * xlcof * axnl

        // --------------------- solve kepler's equation ---------------
        // In these variables Kepler's equation becomes
        //     U = E′ − axn·sin E′ + ayn·cos E′,    where U = xl − Ω and E′ = E + ω
        // solved for E′ (eo1) by Newton iteration. Each step is limited to 0.95 rad so the
        // iteration cannot run away for highly eccentric orbits.
        let u = (xl - nodep).truncatingRemainder(dividingBy: twoPi)
        var eo1 = u
        var tem5 = 9999.9
        var ktr = 1
        var sineo1 = 0.0
        var coseo1 = 0.0
        // sgp4fix for kepler iteration: the 0.95 clamp keeps steps stable for high eccentricity
        while abs(tem5) >= 1.0e-12 && ktr <= 10 {
            sineo1 = sin(eo1)
            coseo1 = cos(eo1)
            tem5 = 1.0 - coseo1 * axnl - sineo1 * aynl
            tem5 = (u - aynl * coseo1 + axnl * sineo1 - eo1) / tem5
            if abs(tem5) >= 0.95 {
                tem5 = tem5 > 0.0 ? 0.95 : -0.95
            }
            eo1 += tem5
            ktr += 1
        }

        // ------------- short period preliminary quantities -----------
        // From E′: e·cos E (ecose), e·sin E (esine), the semi-latus rectum pl = a(1 − e²),
        // radius rl = a(1 − e·cos E), its rate rdotl, and the argument of latitude
        // su = ν + ω (the angle from the ascending node to the satellite).
        let ecose = axnl * coseo1 + aynl * sineo1
        let esine = axnl * sineo1 - aynl * coseo1
        let el2 = axnl * axnl + aynl * aynl
        let pl = am * (1.0 - el2)
        if pl < 0.0 {
            throw SGP4Error.semiLatusRectumNegative(pl)
        }

        let rl = am * (1.0 - ecose)
        let rdotl = sqrt(am) * esine / rl
        let rvdotl = sqrt(pl) / rl
        let betal = sqrt(1.0 - el2)
        temp = esine / (1.0 + betal)
        let sinu = am / rl * (sineo1 - aynl - axnl * temp)
        let cosu = am / rl * (coseo1 - axnl + aynl * temp)
        var su = atan2(sinu, cosu)
        let sin2u = (cosu + cosu) * sinu
        let cos2u = 1.0 - 2.0 * sinu * sinu
        temp = 1.0 / pl
        let temp1 = 0.5 * grav.j2 * temp
        let temp2 = temp1 * temp

        // -------------- update for short period periodics ------------
        // J2 makes the orbit wobble twice per revolution (terms in 2u). Correct the radius
        // (mrt), argument of latitude (su), node (xnode), inclination (xinc), and the radial
        // (mvt) and transverse (rvdot) velocities. Units: Earth radii and radii per minute.
        if rec.isDeepSpace {
            let cosisq = cosip * cosip
            con41 = 3.0 * cosisq - 1.0
            x1mth2 = 1.0 - cosisq
            x7thm1 = 7.0 * cosisq - 1.0
        }
        let mrt = rl * (1.0 - 1.5 * temp2 * betal * con41) + 0.5 * temp1 * x1mth2 * cos2u
        su -= 0.25 * temp2 * x7thm1 * sin2u
        let xnode = nodep + 1.5 * temp2 * cosip * sin2u
        let xinc = xincp + 1.5 * temp2 * cosip * sinip * cos2u
        let mvt = rdotl - nm * temp1 * x1mth2 * sin2u / grav.xke
        let rvdot = rvdotl + nm * temp1 * (x1mth2 * cos2u + 1.5 * con41) / grav.xke

        // --------------------- orientation vectors -------------------
        // U points from Earth's center to the satellite, V along the direction of motion in
        // the orbit plane, both built from node, inclination and argument of latitude:
        //     r = radius·U
        //     v = (radial speed)·U + (transverse speed)·V
        let sinsu = sin(su)
        let cossu = cos(su)
        let snod = sin(xnode)
        let cnod = cos(xnode)
        let sini = sin(xinc)
        let cosi = cos(xinc)
        let xmx = -snod * cosi
        let xmy = cnod * cosi
        let ux = xmx * sinsu + cnod * cossu
        let uy = xmy * sinsu + snod * cossu
        let uz = sini * sinsu
        let vx = xmx * cossu - cnod * sinsu
        let vy = xmy * cossu - snod * sinsu
        let vz = sini * cossu

        // sgp4fix for decaying satellites: a radius below one Earth radius means the
        // satellite would be underground
        if mrt < 1.0 {
            throw SGP4Error.decayed(radiusEarthRadii: mrt)
        }

        // --------- position and velocity (in km and km/sec) ----------
        // Convert from Earth radii and radii/minute back to km and km/s
        let mr = mrt * grav.radiusEarthKm
        return StateVector(
            position: Vector3D(x: mr * ux, y: mr * uy, z: mr * uz),
            velocity: Vector3D(
                x: (mvt * ux + rvdot * vx) * vkmpersec,
                y: (mvt * uy + rvdot * vy) * vkmpersec,
                z: (mvt * uz + rvdot * vz) * vkmpersec
            )
        )
    }
}
