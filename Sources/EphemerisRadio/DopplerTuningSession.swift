//
//  DopplerTuningSession.swift
//  EphemerisRadio
//
//  Keeps an SDR tuned to a satellite's downlink as Doppler shift moves it during a pass.
//

import Foundation
import Ephemeris

/// Retunes a radio or SDR once a second so a satellite's downlink stays centered as its
/// Doppler shift changes.
///
/// ## What It Does Each Second
/// 1. Computes the satellite's look angles and the Doppler-shifted downlink frequency.
/// 2. Below the minimum elevation, it does nothing: there is no signal to follow.
/// 3. Above it, it sends a new frequency only when the target has moved by at least the tuning
///    step since the last one sent. This keeps the radio's control link quiet when little is
///    changing (early and late in a pass) and busy only near the closest approach.
/// 4. If the radio can't be reached, it waits `reconnectInterval` before trying again.
///
/// Each step is published on `updates`, ready to drive a display.
///
/// ## Correcting for Your SDR's Crystal
/// Cheap SDRs are often off by several ppm: 1 to 3 kHz at 437 MHz. If the signal sits to one
/// side of the passband, call `setCorrection(hertz:)` with the offset. It is added to every
/// frequency sent and is kept for the rest of the session.
///
/// ## Example
/// ```swift
/// let sdr = RigctlClient(port: RigctlClient.gqrxPort)
/// let session = DopplerTuningSession(
///     propagator: try SGP4(elements: issElements),
///     observer: Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140),
///     radio: sdr,
///     configuration: .init(nominalFrequencyHz: 145_800_000, mode: .fm, passbandHz: 15_000)
/// )
///
/// let tuning = Task { await session.run() }
/// for await update in session.updates {
///     print(update)
/// }
/// // Later: tuning.cancel()
/// ```
public actor DopplerTuningSession {

    // MARK: - Configuration

    /// What to tune and how eagerly.
    public struct Configuration: Sendable {

        /// The satellite's transmit frequency (Hz)
        public var nominalFrequencyHz: Double

        /// Mode to select when tuning starts, or nil to leave the radio's mode alone
        public var mode: RadioMode?

        /// Filter width to select with `mode` (Hz)
        public var passbandHz: Int

        /// Smallest change worth sending (Hz). 10 Hz suits CW and SSB; FM is happy with 100 Hz
        /// or more. Never less than 1 Hz.
        public var tuningStepHz: Double

        /// Time between updates (seconds). Never less than 0.1 s.
        public var updateInterval: TimeInterval

        /// Elevation at which tuning starts and stops (degrees)
        public var minElevationDeg: Degrees

        /// How long to wait after the radio fails before trying it again (seconds)
        public var reconnectInterval: TimeInterval

        /// Creates a configuration.
        ///
        /// - Parameters:
        ///   - nominalFrequencyHz: The satellite's transmit frequency (Hz)
        ///   - mode: Mode to select when tuning starts (default: leave unchanged)
        ///   - passbandHz: Filter width to select with `mode` (default 15,000 Hz)
        ///   - tuningStepHz: Smallest change worth sending (default 10 Hz)
        ///   - updateInterval: Time between updates (default 1 s)
        ///   - minElevationDeg: Elevation at which tuning starts and stops (default 0°)
        ///   - reconnectInterval: Wait after a radio failure (default 5 s)
        public init(nominalFrequencyHz: Double, mode: RadioMode? = nil, passbandHz: Int = 15_000,
                    tuningStepHz: Double = 10, updateInterval: TimeInterval = 1,
                    minElevationDeg: Degrees = 0, reconnectInterval: TimeInterval = 5) {
            self.nominalFrequencyHz = nominalFrequencyHz
            self.mode = mode
            self.passbandHz = passbandHz
            self.tuningStepHz = max(tuningStepHz, 1)
            self.updateInterval = max(updateInterval, 0.1)
            self.minElevationDeg = minElevationDeg
            self.reconnectInterval = max(reconnectInterval, 1)
        }
    }

    // MARK: - Updates

    /// What happened on one step.
    public enum Update: Equatable, Sendable {
        /// The satellite is below the minimum elevation; nothing was sent
        case belowHorizon(DopplerPoint)

        /// A new frequency was sent to the radio (Hz, including any correction)
        case tuned(DopplerPoint, sentHz: Int)

        /// The frequency moved less than the tuning step; the radio stays where it is
        case holding(DopplerPoint, sentHz: Int)

        /// The radio couldn't be reached or refused the command
        case radioUnavailable(RigControlError)

        /// The satellite's position couldn't be computed (for example, a decayed orbit)
        case propagationFailed(String)
    }

    /// One update per step, newest kept if the reader falls behind
    public nonisolated let updates: AsyncStream<Update>
    private let continuation: AsyncStream<Update>.Continuation

    // MARK: - State

    private let propagator: any Propagator
    private let observer: Observer
    private let radio: any FrequencyControl
    private let time: TimeSource

    /// The configuration in use
    public let configuration: Configuration

    /// Added to every frequency sent, to correct the SDR's crystal error (Hz)
    public private(set) var correctionHz: Double = 0

    /// The last frequency sent, or nil if the radio needs a fresh one
    private var lastSentHz: Int?

    /// Whether the configured mode has been selected on the current connection
    private var modeIsSet = false

    /// No radio commands before this time, after a failure
    private var radioRetryTime: Date?

    // MARK: - Initialization

    /// Creates a session. Nothing is sent until `run()` is called.
    ///
    /// - Parameters:
    ///   - propagator: The satellite, usually an `SGP4`
    ///   - observer: The receiving station
    ///   - radio: The radio or SDR, usually a `RigctlClient`
    ///   - configuration: Frequency, mode and timing
    public init(propagator: any Propagator, observer: Observer, radio: any FrequencyControl,
                configuration: Configuration) {
        self.init(propagator: propagator, observer: observer, radio: radio,
                  configuration: configuration, time: .system)
    }

    /// Creates a session with a substitute clock (for tests).
    init(propagator: any Propagator, observer: Observer, radio: any FrequencyControl,
         configuration: Configuration, time: TimeSource) {
        self.propagator = propagator
        self.observer = observer
        self.radio = radio
        self.configuration = configuration
        self.time = time
        (updates, continuation) = AsyncStream.makeStream(of: Update.self, bufferingPolicy: .bufferingNewest(32))
    }

    // MARK: - Running

    /// Tunes until the task running it is cancelled, then finishes `updates`.
    public func run() async {
        while !Task.isCancelled {
            continuation.yield(await step(at: time.now()))
            do {
                try await time.sleep(configuration.updateInterval)
            } catch {
                break   // cancelled while sleeping
            }
        }
        continuation.finish()
    }

    /// Sets the crystal correction and retunes on the next step.
    ///
    /// - Parameter hertz: Offset added to every frequency sent. If the satellite's signal
    ///   appears 1.2 kHz above the center of your SDR's passband, use +1200.
    public func setCorrection(hertz: Double) {
        correctionHz = hertz
        lastSentHz = nil
    }

    /// Performs one step at a given time.
    func step(at date: Date) async -> Update {
        let point: DopplerPoint
        do {
            point = try propagator.doppler(at: date, for: observer,
                                           nominalFrequencyHz: configuration.nominalFrequencyHz)
        } catch {
            return .propagationFailed("\(error)")
        }

        guard point.topocentric.elevationDeg >= configuration.minElevationDeg else {
            // Forget the last frequency so the next pass starts with a fresh command
            lastSentHz = nil
            return .belowHorizon(point)
        }

        let target = Int((point.frequencyHz + correctionHz).rounded())
        if let last = lastSentHz, Double(abs(target - last)) < configuration.tuningStepHz {
            return .holding(point, sentHz: last)
        }

        // Back off after a failure, so an absent radio isn't hammered every second
        if let retry = radioRetryTime, date < retry {
            return .radioUnavailable(.connectionFailed("waiting until \(retry) to retry"))
        }

        do {
            if let mode = configuration.mode, !modeIsSet {
                try await radio.setMode(mode, passbandHz: configuration.passbandHz)
                modeIsSet = true
            }
            try await radio.setFrequency(target)
            lastSentHz = target
            radioRetryTime = nil
            return .tuned(point, sentHz: target)
        } catch {
            // The radio may have restarted: select the mode again once it's back
            modeIsSet = false
            lastSentHz = nil
            radioRetryTime = date.addingTimeInterval(configuration.reconnectInterval)
            return .radioUnavailable(error as? RigControlError ?? .connectionFailed("\(error)"))
        }
    }
}
