//
//  Doppler.swift
//  Ephemeris
//
//  The frequency shift caused by a satellite's motion toward or away from the observer:
//  what an SDR has to correct for to stay on a satellite's signal during a pass.
//

import Foundation

/// Doppler shift for radio signals between a satellite and a ground station.
///
/// ## The Physics
/// A satellite in low Earth orbit moves at about 7.5 km/s. While it approaches, each wave
/// crest is sent from a little closer than the last, so crests arrive more often and the
/// received frequency is higher than the transmitted one. While it recedes, the received
/// frequency is lower. Only the speed *along the line of sight* matters: that is the
/// range rate `ṙ` (positive when the distance is growing), which `Topocentric` provides.
///
/// For a satellite transmitting at frequency `f`, the ground station receives
/// ```
/// f_rx = f · (1 − ṙ / c)
/// Δf   = f_rx − f = −f · ṙ / c
/// ```
/// For the ISS at 145.8 MHz, `ṙ` runs from about −7 to +7 km/s, so the received signal starts
/// about 3.4 kHz high, sweeps through zero at the closest approach, and ends about 3.4 kHz low.
/// The shift scales with frequency: the same pass at 437 MHz spans about ±10 kHz, and at
/// 2.4 GHz about ±56 kHz.
///
/// For transmitting *to* a satellite (an uplink), the satellite is the moving receiver and
/// hears `f_tx · (1 − ṙ / c)`. To land on its nominal frequency `f`, transmit at
/// ```
/// f_tx = f / (1 − ṙ / c)
/// ```
///
/// ## How Accurate Is This?
/// These are the first-order (non-relativistic) formulas. The full relativistic expression
/// differs by about β²/2 of the frequency, where β = v/c ≈ 2.5 × 10⁻⁵ in low Earth orbit:
/// about 3 × 10⁻¹⁰, or 0.05 Hz at 145.8 MHz, 0.1 Hz at 437 MHz and 3 Hz at 10 GHz. A typical
/// SDR's crystal is off by 0.5 to 20 ppm (hundreds to thousands of Hz at UHF), so the
/// second-order term is far below anything a receiver can notice.
///
/// In practice the error comes from the range rate, which depends on the element set's age:
/// a 1 km along-track error (roughly one day old) shifts the curve by about 0.13 s. Near the
/// closest approach of an overhead 437 MHz pass, where the frequency moves about 150 Hz/s,
/// that is about 20 Hz: fine for FM, noticeable on narrow CW or SSB signals.
///
/// - Note: References: Maral, Bousquet and Sun, "Satellite Communications Systems";
///   Davidoff, "The Radio Amateur's Satellite Handbook"
public enum Doppler {

    /// The frequency received on the ground from a satellite transmitting at `nominalHz`.
    ///
    /// - Parameters:
    ///   - nominalHz: The satellite's transmit frequency (Hz)
    ///   - rangeRateKmPerSec: Range rate, positive when the satellite is moving away (km/s)
    /// - Returns: The received frequency (Hz): higher while approaching, lower while receding
    public static func downlinkFrequency(nominalHz: Double, rangeRateKmPerSec: Double) -> Double {
        return nominalHz * (1 - rangeRateKmPerSec / PhysicalConstants.speedOfLight)
    }

    /// The frequency to transmit so that the satellite receives exactly `nominalHz`.
    ///
    /// - Parameters:
    ///   - nominalHz: The satellite's receive frequency (Hz)
    ///   - rangeRateKmPerSec: Range rate, positive when the satellite is moving away (km/s)
    /// - Returns: The frequency to transmit (Hz): lower while approaching, higher while receding
    public static func uplinkFrequency(nominalHz: Double, rangeRateKmPerSec: Double) -> Double {
        return nominalHz / (1 - rangeRateKmPerSec / PhysicalConstants.speedOfLight)
    }

    /// The downlink shift, received minus nominal frequency (Hz).
    ///
    /// - Parameters:
    ///   - nominalHz: The satellite's transmit frequency (Hz)
    ///   - rangeRateKmPerSec: Range rate, positive when the satellite is moving away (km/s)
    public static func downlinkShift(nominalHz: Double, rangeRateKmPerSec: Double) -> Double {
        return -nominalHz * rangeRateKmPerSec / PhysicalConstants.speedOfLight
    }
}

// MARK: - Topocentric Convenience

extension Topocentric {
    /// The frequency received from a satellite transmitting at `nominalHz`, at this moment.
    ///
    /// ```swift
    /// let topo = try sgp4.topocentric(at: Date(), for: observer)
    /// let tuneTo = topo.downlinkFrequency(nominalHz: 145_800_000)
    /// ```
    public func downlinkFrequency(nominalHz: Double) -> Double {
        return Doppler.downlinkFrequency(nominalHz: nominalHz, rangeRateKmPerSec: rangeRateKmPerSec)
    }

    /// The frequency to transmit so the satellite receives exactly `nominalHz`, at this moment.
    public func uplinkFrequency(nominalHz: Double) -> Double {
        return Doppler.uplinkFrequency(nominalHz: nominalHz, rangeRateKmPerSec: rangeRateKmPerSec)
    }
}

// MARK: - Doppler Over Time

/// The Doppler-shifted downlink of a satellite at one moment.
public struct DopplerPoint: Hashable, Codable, Sendable {

    /// The time of this point
    public let time: Date

    /// The frequency received on the ground (Hz)
    public let frequencyHz: Double

    /// Received minus nominal frequency (Hz): positive while approaching
    public let shiftHz: Double

    /// How fast the received frequency is changing (Hz/s). Most negative near the closest
    /// approach, where the shift sweeps through zero fastest.
    public let rateHzPerSec: Double

    /// Look angles, range and range rate at this moment
    public let topocentric: Topocentric

    /// Creates a Doppler point.
    public init(time: Date, frequencyHz: Double, shiftHz: Double, rateHzPerSec: Double, topocentric: Topocentric) {
        self.time = time
        self.frequencyHz = frequencyHz
        self.shiftHz = shiftHz
        self.rateHzPerSec = rateHzPerSec
        self.topocentric = topocentric
    }
}

extension Propagator {
    /// The Doppler-shifted downlink of this satellite as received by an observer.
    ///
    /// - Parameters:
    ///   - date: The time of interest
    ///   - observer: The receiving station
    ///   - nominalFrequencyHz: The satellite's transmit frequency (Hz)
    /// - Returns: Received frequency, shift, rate of change and look angles
    /// - Throws: Any error thrown by the propagator
    ///
    /// ## Doppler Rate
    /// Differentiating `f_rx = f · (1 − ṙ / c)` gives `df_rx/dt = −f · r̈ / c`, where `r̈` is the
    /// range acceleration. It is found by a central difference of the range rate one half
    /// second either side of `date`: `r̈ ≈ (ṙ(t + ½) − ṙ(t − ½)) / 1 s`. Over one second the
    /// range rate is very nearly a straight line, so this is accurate to well under 0.1 Hz/s.
    ///
    /// ## Example
    /// ```swift
    /// let now = try sgp4.doppler(at: Date(), for: observer, nominalFrequencyHz: 437_800_000)
    /// print("Tune to \(now.frequencyHz) Hz, drifting \(now.rateHzPerSec) Hz/s")
    /// ```
    public func doppler(at date: Date, for observer: Observer, nominalFrequencyHz: Double) throws -> DopplerPoint {
        try doppler(at: date, from: ObserverFrame(observer), nominalFrequencyHz: nominalFrequencyHz)
    }

    /// The downlink Doppler curve over a time window, such as a pass.
    ///
    /// - Parameters:
    ///   - observer: The receiving station
    ///   - nominalFrequencyHz: The satellite's transmit frequency (Hz)
    ///   - start: First sample time
    ///   - end: Last sample time (always included)
    ///   - stepSeconds: Time between samples (default 10 s)
    /// - Returns: One point per sample, in time order
    /// - Throws: Any error thrown by the propagator
    ///
    /// The shape of this curve identifies a satellite: its steepness at the zero crossing
    /// depends on how close the satellite passes, and the time of the zero crossing on where
    /// it is along its orbit.
    public func dopplerCurve(for observer: Observer, nominalFrequencyHz: Double,
                             from start: Date, to end: Date, stepSeconds: Double = 10) throws -> [DopplerPoint] {
        let frame = ObserverFrame(observer)
        return try sampleTimes(from: start, to: end, stepSeconds: stepSeconds).map { time in
            try doppler(at: time, from: frame, nominalFrequencyHz: nominalFrequencyHz)
        }
    }

    /// Doppler at one time using an observer frame built once by the caller.
    func doppler(at date: Date, from frame: ObserverFrame, nominalFrequencyHz: Double) throws -> DopplerPoint {
        let topo = try topocentric(at: date, from: frame)

        // Range acceleration by central difference over one second
        let later = try topocentric(at: date.addingTimeInterval(0.5), from: frame).rangeRateKmPerSec
        let earlier = try topocentric(at: date.addingTimeInterval(-0.5), from: frame).rangeRateKmPerSec
        let rangeAcceleration = later - earlier   // km/s per 1 s

        return DopplerPoint(
            time: date,
            frequencyHz: topo.downlinkFrequency(nominalHz: nominalFrequencyHz),
            shiftHz: Doppler.downlinkShift(nominalHz: nominalFrequencyHz, rangeRateKmPerSec: topo.rangeRateKmPerSec),
            rateHzPerSec: -nominalFrequencyHz * rangeAcceleration / PhysicalConstants.speedOfLight,
            topocentric: topo
        )
    }
}
