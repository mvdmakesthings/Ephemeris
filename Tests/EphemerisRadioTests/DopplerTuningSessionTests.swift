//
//  DopplerTuningSessionTests.swift
//  EphemerisRadioTests
//
//  The tuning session over a simulated ISS pass above Louisville on 2020-04-07, stepping
//  second by second with no real waiting. Rise 00:27:58.6, closest approach 00:33:25.5 and
//  set 00:38:50.8 UTC, from Skyfield's find_events (Ephemeris' predictPasses agrees to 1 s).
//

import XCTest
@testable import Ephemeris
@testable import EphemerisRadio

/// Records commands instead of sending them, and can be told to fail.
actor RecordingRadio: FrequencyControl {
    private(set) var commands: [String] = []
    private var failuresRemaining = 0

    func failNext(_ count: Int) {
        failuresRemaining = count
    }

    func setFrequency(_ hertz: Int) async throws {
        try check()
        commands.append("F \(hertz)")
    }

    func setMode(_ mode: RadioMode, passbandHz: Int) async throws {
        try check()
        commands.append("M \(mode.rawValue) \(passbandHz)")
    }

    var frequencyCommands: [Int] {
        commands.compactMap { $0.hasPrefix("F ") ? Int($0.dropFirst(2)) : nil }
    }

    private func check() throws {
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw RigControlError.connectionClosed
        }
    }
}

/// A propagator that always fails, like a decayed satellite
struct FailingPropagator: Propagator {
    func stateVector(at date: Date) throws -> StateVector {
        throw SGP4Error.decayed(radiusEarthRadii: 0.98)
    }
}

final class DopplerTuningSessionTests: XCTestCase {

    private let louisville = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
    private let passStart = Date(timeIntervalSince1970: 1_586_219_220)   // 2020-04-07 00:27:00 UTC
    private let closestApproach = Date(timeIntervalSince1970: 1_586_219_605)   // 00:33:25 UTC

    private func iss() throws -> SGP4 {
        try SGP4(tle: try TwoLineElement(from: """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """))
    }

    private func session(radio: any FrequencyControl, step: Double = 10,
                         mode: RadioMode? = .fm) throws -> DopplerTuningSession {
        DopplerTuningSession(propagator: try iss(), observer: louisville, radio: radio,
                             configuration: .init(nominalFrequencyHz: 145_800_000, mode: mode,
                                                  passbandHz: 15_000, tuningStepHz: step))
    }

    /// Steps once a second from 00:27:00 to 00:40:00, covering the whole pass.
    private func simulatePass(_ session: DopplerTuningSession) async -> [DopplerTuningSession.Update] {
        var updates: [DopplerTuningSession.Update] = []
        for second in 0...(13 * 60) {
            updates.append(await session.step(at: passStart.addingTimeInterval(Double(second))))
        }
        return updates
    }

    // MARK: - Tracking a Pass

    func testStep_overISSPass_shouldStayWithinTuningStepWhileUp() async throws {
        // Given
        let radio = RecordingRadio()
        let session = try session(radio: radio)

        // When
        let updates = await simulatePass(session)

        // Then: the radio is never more than one tuning step (plus rounding) off frequency
        var upSteps = 0
        for update in updates {
            switch update {
            case .tuned(let point, let sent), .holding(let point, let sent):
                upSteps += 1
                XCTAssertLessThan(abs(point.frequencyHz - Double(sent)), 10.5, "\(point.time)")
            case .belowHorizon(let point):
                XCTAssertLessThan(point.topocentric.elevationDeg, 0)
            default:
                XCTFail("Unexpected \(update)")
            }
        }
        // 652 s above the horizon (00:27:58.6 to 00:38:50.8), so 652 or 653 whole-second steps
        XCTAssertEqual(Double(upSteps), 652, accuracy: 1)

        // The mode is selected once, before the first frequency
        let commands = await radio.commands
        XCTAssertEqual(commands.first, "M FM 15000")
        XCTAssertEqual(commands.filter { $0.hasPrefix("M ") }.count, 1)

        // Fewer commands than seconds: early and late in the pass, the shift changes slowly
        let tunes = await radio.frequencyCommands
        XCTAssertLessThan(tunes.count, upSteps)
        XCTAssertGreaterThan(tunes.count, upSteps / 3)
        // Started high (approaching) and ended low (receding), by roughly ±3.3 kHz
        XCTAssertGreaterThan(try XCTUnwrap(tunes.first), 145_802_900)
        XCTAssertLessThan(try XCTUnwrap(tunes.last), 145_797_100)
    }

    func testStep_withLargerTuningStep_shouldSendFewerCommands() async throws {
        // Given
        let fine = RecordingRadio()
        let coarse = RecordingRadio()

        // When
        _ = await simulatePass(try session(radio: fine, step: 10))
        _ = await simulatePass(try session(radio: coarse, step: 100))

        // Then
        let fineCount = await fine.frequencyCommands.count
        let coarseCount = await coarse.frequencyCommands.count
        XCTAssertLessThan(coarseCount * 4, fineCount)
    }

    func testStep_belowHorizon_shouldSendNothing() async throws {
        // Given: an hour before the pass
        let radio = RecordingRadio()
        let session = try session(radio: radio)

        // When
        let update = await session.step(at: passStart.addingTimeInterval(-3600))

        // Then
        guard case .belowHorizon = update else {
            return XCTFail("Expected belowHorizon, got \(update)")
        }
        let commands = await radio.commands
        XCTAssertEqual(commands, [])
    }

    func testStep_withoutMode_shouldOnlySendFrequencies() async throws {
        // Given
        let radio = RecordingRadio()
        let session = try session(radio: radio, mode: nil)

        // When
        _ = await session.step(at: closestApproach)

        // Then
        let commands = await radio.commands
        XCTAssertEqual(commands.count, 1)
        XCTAssertTrue(commands[0].hasPrefix("F "))
    }

    func testStep_afterSatelliteSets_shouldRetuneAtNextRise() async throws {
        // Given: tuned, then the satellite goes below the horizon (the operator may retune by
        // hand in between)
        let radio = RecordingRadio()
        let session = try session(radio: radio)
        _ = await session.step(at: closestApproach)
        _ = await session.step(at: passStart.addingTimeInterval(-3600))

        // When: back above the horizon at a frequency within one tuning step of the last one
        let update = await session.step(at: closestApproach)

        // Then: a fresh command, not "holding"
        guard case .tuned = update else {
            return XCTFail("Expected tuned, got \(update)")
        }
        let tunes = await radio.frequencyCommands
        XCTAssertEqual(tunes.count, 2)
    }

    // MARK: - Correction

    func testSetCorrection_shouldOffsetFrequencyAndRetuneOnNextStep() async throws {
        // Given: tuned at the closest approach
        let radio = RecordingRadio()
        let session = try session(radio: radio)
        _ = await session.step(at: closestApproach)

        // When: the operator sees the signal 1.2 kHz high and corrects
        await session.setCorrection(hertz: 1200)
        let update = await session.step(at: closestApproach)

        // Then: same instant, same Doppler, but 1200 Hz higher, sent at once
        let tunes = await radio.frequencyCommands
        guard tunes.count == 2 else {
            return XCTFail("Expected a second command after the correction, got \(tunes)")
        }
        XCTAssertEqual(tunes[1] - tunes[0], 1200)
        guard case .tuned = update else {
            return XCTFail("Expected tuned, got \(update)")
        }
    }

    func testSetCorrection_smallerThanTuningStep_shouldStillRetuneAtOnce() async throws {
        // Given
        let radio = RecordingRadio()
        let session = try session(radio: radio, step: 10)
        _ = await session.step(at: closestApproach)

        // When: a 5 Hz nudge, half the tuning step
        await session.setCorrection(hertz: 5)
        _ = await session.step(at: closestApproach)

        // Then: the operator's change takes effect immediately
        let tunes = await radio.frequencyCommands
        guard tunes.count == 2 else {
            return XCTFail("Expected a second command after the correction, got \(tunes)")
        }
        XCTAssertEqual(tunes[1] - tunes[0], 5)
    }

    // MARK: - Failures

    func testStep_whenRadioFails_shouldWaitBeforeRetryingAndReselectMode() async throws {
        // Given: the radio fails twice (mode, then the first retry), then works
        let radio = RecordingRadio()
        await radio.failNext(2)
        let session = try session(radio: radio)

        // When: one step per second through the closest approach
        var updates: [DopplerTuningSession.Update] = []
        for second in 0..<12 {
            updates.append(await session.step(at: closestApproach.addingTimeInterval(Double(second))))
        }

        // Then: failures at 0 s and 5 s (the reconnect interval), waiting in between, then tuned
        let unavailable = updates.enumerated().filter {
            if case .radioUnavailable = $0.element { return true } else { return false }
        }.map(\.offset)
        XCTAssertEqual(unavailable, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        guard case .tuned = updates[10] else {
            return XCTFail("Expected tuned at 10 s, got \(updates[10])")
        }
        // Only the two failed attempts and one successful pair reached the radio
        let commands = await radio.commands
        XCTAssertEqual(commands.first, "M FM 15000")
        XCTAssertEqual(commands.filter { $0.hasPrefix("M ") }.count, 1)
    }

    func testStep_afterRadioRecovers_shouldSelectModeAgain() async throws {
        // Given: tuned normally, then the SDR program restarts (losing its mode)
        let radio = RecordingRadio()
        let session = try session(radio: radio)
        _ = await session.step(at: closestApproach)
        await radio.failNext(1)
        _ = await session.step(at: closestApproach.addingTimeInterval(1))

        // When: after the reconnect interval
        _ = await session.step(at: closestApproach.addingTimeInterval(6))

        // Then: the mode is selected again before the frequency
        let commands = await radio.commands
        XCTAssertEqual(commands.filter { $0.hasPrefix("M ") }.count, 2)
        XCTAssertTrue(commands[commands.count - 2].hasPrefix("M "))
        XCTAssertTrue(commands[commands.count - 1].hasPrefix("F "))
    }

    func testStep_whenPropagationFails_shouldReportIt() async {
        // Given
        let radio = RecordingRadio()
        let session = DopplerTuningSession(propagator: FailingPropagator(), observer: louisville, radio: radio,
                                           configuration: .init(nominalFrequencyHz: 145_800_000))

        // When
        let update = await session.step(at: closestApproach)

        // Then
        guard case .propagationFailed = update else {
            return XCTFail("Expected propagationFailed, got \(update)")
        }
        let commands = await radio.commands
        XCTAssertEqual(commands, [])
    }

    // MARK: - Running

    func testRun_shouldPublishOneUpdatePerIntervalUntilCancelled() async throws {
        // Given: a clock that starts at the closest approach and advances only when slept
        let clock = ManualClock(closestApproach)
        let radio = RecordingRadio()
        let session = DopplerTuningSession(propagator: try iss(), observer: louisville, radio: radio,
                                           configuration: .init(nominalFrequencyHz: 145_800_000),
                                           time: clock.timeSource)

        // When
        let running = Task { await session.run() }
        var times: [Date] = []
        for await update in session.updates {
            if case .tuned(let point, _) = update { times.append(point.time) }
            if case .holding(let point, _) = update { times.append(point.time) }
            if times.count == 5 { running.cancel() }
        }

        // Then: the stream finished after cancellation, and updates were one second apart
        XCTAssertGreaterThanOrEqual(times.count, 5)
        XCTAssertEqual(Array(times.prefix(5)), (0..<5).map { closestApproach.addingTimeInterval(Double($0)) })
    }

    func testConfiguration_shouldClampUnsafeValues() {
        // Given / When
        let configuration = DopplerTuningSession.Configuration(nominalFrequencyHz: 145_800_000, tuningStepHz: 0,
                                                               updateInterval: 0, reconnectInterval: 0)

        // Then: no zero step, no busy loop, no reconnect storm
        XCTAssertEqual(configuration.tuningStepHz, 1)
        XCTAssertEqual(configuration.updateInterval, 0.1)
        XCTAssertEqual(configuration.reconnectInterval, 1)
    }

    // MARK: - End to End

    func testSession_withRigctlClientAndFakeSDR_shouldSendModeThenFrequencies() async throws {
        // Given: the session driving a real rigctl client over TCP to a GQRX-like server
        let server = try FakeRigServer.gqrxStyle()
        defer { server.stop() }
        let client = RigctlClient(host: "127.0.0.1", port: server.port, timeout: 1)
        let session = DopplerTuningSession(propagator: try iss(), observer: louisville, radio: client,
                                           configuration: .init(nominalFrequencyHz: 145_800_000, mode: .fm,
                                                                passbandHz: 15_000))

        // When: three seconds around the closest approach, where the shift moves ~52 Hz/s
        for second in 0..<3 {
            _ = await session.step(at: closestApproach.addingTimeInterval(Double(second)))
        }
        let tunedTo = try await client.frequency()

        // Then
        let received = server.received
        XCTAssertEqual(received.first, "M FM 15000")
        XCTAssertEqual(received.filter { $0.hasPrefix("F ") }.count, 3)
        XCTAssertEqual(received.last, "f")
        XCTAssertEqual(Double(tunedTo), 145_800_000 - 52.2 * 2 + 25.1, accuracy: 15)
    }
}

/// A clock that only moves when the session sleeps.
final class ManualClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(_ start: Date) {
        current = start
    }

    var now: Date {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    private func advance(by seconds: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        current = current.addingTimeInterval(seconds)
    }

    var timeSource: TimeSource {
        TimeSource(
            now: { self.now },
            sleep: { seconds in
                // A real millisecond pause keeps the loop from outrunning the test's reader
                try await Task.sleep(nanoseconds: 1_000_000)
                self.advance(by: seconds)
            }
        )
    }
}
