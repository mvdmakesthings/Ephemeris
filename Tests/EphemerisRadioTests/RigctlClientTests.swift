//
//  RigctlClientTests.swift
//  EphemerisRadioTests
//
//  The rigctl client over a real TCP connection to FakeRigServer, imitating SDR++ and Hamlib
//  rigctld (RPRT -1 on error, decimal frequency) and GQRX (RPRT 1, integer frequency).
//

import XCTest
@testable import EphemerisRadio

final class RigctlClientTests: XCTestCase {

    private var servers: [FakeRigServer] = []

    override func tearDown() {
        servers.forEach { $0.stop() }
        servers.removeAll()
        super.tearDown()
    }

    private func start(_ server: FakeRigServer) -> RigctlClient {
        servers.append(server)
        return RigctlClient(host: "127.0.0.1", port: server.port, timeout: 1)
    }

    private func assertThrows(_ expected: RigControlError, file: StaticString = #filePath, line: UInt = #line,
                              _ body: () async throws -> Void) async {
        do {
            try await body()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch let error as RigControlError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected \(expected), got \(error)", file: file, line: line)
        }
    }

    // MARK: - Commands

    func testSetFrequency_shouldSendFCommandAndAcceptRPRT0() async throws {
        for server in [try FakeRigServer.hamlibStyle(), try FakeRigServer.gqrxStyle()] {
            // Given
            let client = start(server)

            // When
            try await client.setFrequency(145_800_000)
            let readBack = try await client.frequency()

            // Then: Hamlib's "145800000.000000" and GQRX's "145800000" both read back exactly
            XCTAssertEqual(server.received, ["F 145800000", "f"])
            XCTAssertEqual(readBack, 145_800_000)
        }
    }

    func testSetMode_shouldSendModeAndPassbandAndReadBothBack() async throws {
        for server in [try FakeRigServer.hamlibStyle(), try FakeRigServer.gqrxStyle()] {
            // Given
            let client = start(server)

            // When
            try await client.setMode(.wfm, passbandHz: 40_000)
            let current = try await client.mode()

            // Then
            XCTAssertEqual(server.received, ["M WFM 40000", "m"])
            XCTAssertEqual(current.mode, .wfm)
            XCTAssertEqual(current.passbandHz, 40_000)
        }
    }

    func testCommands_onOneClient_shouldReuseOneConnection() async throws {
        // Given
        let server = try FakeRigServer.hamlibStyle()
        let client = start(server)

        // When
        for offset in 0..<10 {
            try await client.setFrequency(437_800_000 + offset * 100)
        }

        // Then
        XCTAssertEqual(server.connectionCount, 1)
        XCTAssertEqual(server.received.count, 10)
    }

    // MARK: - Errors

    func testSetFrequency_whenRadioRefuses_shouldThrowRejectedWithCode() async throws {
        // Given: 10 GHz is outside the fake RTL-SDR's range
        let hamlib = start(try FakeRigServer.hamlibStyle())
        let gqrx = start(try FakeRigServer.gqrxStyle())

        // When / Then: Hamlib's negative codes and GQRX's RPRT 1 both become .rejected
        await assertThrows(.rejected(command: "F 10000000000", code: -1)) { try await hamlib.setFrequency(10_000_000_000) }
        await assertThrows(.rejected(command: "F 10000000000", code: 1)) { try await gqrx.setFrequency(10_000_000_000) }

        // And the connection is still usable afterwards
        try await hamlib.setFrequency(145_800_000)
        XCTAssertEqual(servers[0].connectionCount, 1)
    }

    func testGetCommand_whenAnsweredWithRPRT_shouldThrowRejected() async throws {
        // Given: a program that doesn't support reading the frequency
        let server = try FakeRigServer { _ in .lines(["RPRT -11"]) }
        let client = start(server)

        // When / Then
        await assertThrows(.rejected(command: "f", code: -11)) { _ = try await client.frequency() }
    }

    func testInvalidArguments_shouldThrowWithoutSending() async throws {
        // Given
        let server = try FakeRigServer.hamlibStyle()
        let client = start(server)

        // When / Then
        await assertThrows(.invalidArgument("Frequency must be positive, got 0")) { try await client.setFrequency(0) }
        await assertThrows(.invalidArgument("Mode names are letters, digits and underscores, got \"FM\nF 1\"")) {
            try await client.setMode("FM\nF 1", passbandHz: 12_000)
        }
        await assertThrows(.invalidArgument("Passband must be positive, got 0")) { try await client.setMode(.fm, passbandHz: 0) }
        XCTAssertEqual(server.received, [])
    }

    func testCommand_whenNoReply_shouldTimeOutAndReconnectForNextCommand() async throws {
        // Given: a server that ignores the first command, then answers normally
        let calls = Counter()
        let server = try FakeRigServer { _ in calls.next() == 1 ? .silent : .lines(["RPRT 0"]) }
        let client = start(server)

        // When
        await assertThrows(.timeout) { try await client.setFrequency(145_800_000) }
        try await client.setFrequency(145_801_000)

        // Then: a late reply on the old connection can't be mistaken for the new one's
        XCTAssertEqual(server.connectionCount, 2)
    }

    func testCommand_afterServerHangsUp_shouldReconnect() async throws {
        // Given: the program closes the connection on the first command (as when restarted)
        let calls = Counter()
        let server = try FakeRigServer { _ in calls.next() == 1 ? .hangUp : .lines(["RPRT 0"]) }
        let client = start(server)

        // When
        await assertThrows(.connectionClosed) { try await client.setFrequency(145_800_000) }
        try await client.setFrequency(145_800_000)

        // Then
        XCTAssertEqual(server.connectionCount, 2)
    }

    func testConnect_withNothingListening_shouldThrowConnectionFailed() async throws {
        // Given: a port that was just closed
        let server = try FakeRigServer.hamlibStyle()
        let port = server.port
        server.stop()
        let client = RigctlClient(host: "127.0.0.1", port: port, timeout: 1)

        // When / Then
        do {
            try await client.setFrequency(145_800_000)
            XCTFail("Expected a connection failure")
        } catch RigControlError.connectionFailed {
            // expected
        }
    }

    // MARK: - Concurrency

    func testConcurrentCommands_shouldNotInterleaveReplies() async throws {
        // Given: a radio that echoes the frequency back on every read
        let server = try FakeRigServer.hamlibStyle()
        let client = start(server)

        // When: many tasks set and read at once
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<20 {
                group.addTask {
                    try await client.setFrequency(145_000_000 + index)
                    _ = try await client.frequency()
                }
            }
            try await group.waitForAll()
        }

        // Then: every command got its own reply (a mix-up would have thrown) on one connection
        XCTAssertEqual(server.received.count, 40)
        XCTAssertEqual(server.connectionCount, 1)
    }

    // MARK: - Parsing

    func testReportCode_shouldReadOnlyRPRTLines() {
        XCTAssertEqual(RigctlClient.reportCode("RPRT 0"), 0)
        XCTAssertEqual(RigctlClient.reportCode("RPRT -11"), -11)
        XCTAssertEqual(RigctlClient.reportCode(" RPRT 1 "), 1)
        XCTAssertNil(RigctlClient.reportCode("145800000"))
        XCTAssertNil(RigctlClient.reportCode("FM"))
    }
}

/// A thread-safe call counter for server handlers
final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func next() -> Int {
        lock.lock(); defer { lock.unlock() }
        value += 1
        return value
    }
}
