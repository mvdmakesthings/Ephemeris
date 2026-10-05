//
//  RigctlClient.swift
//  EphemerisRadio
//
//  Controls a radio or SDR program over the rigctl text protocol.
//

import Foundation

/// Something whose receive frequency and mode can be set. `RigctlClient` is the real one;
/// `DopplerTuningSession` accepts any conforming type, which keeps it testable.
public protocol FrequencyControl: Sendable {
    /// Tunes to a frequency in Hz.
    func setFrequency(_ hertz: Int) async throws

    /// Selects a demodulation mode and filter width.
    func setMode(_ mode: RadioMode, passbandHz: Int) async throws
}

/// A client for the rigctl network protocol, spoken by Hamlib's `rigctld`, SDR++ and GQRX.
///
/// ## The Protocol
/// rigctl is plain text over TCP, one command per line. The client uses only the four
/// commands every one of these programs supports:
///
/// | Send            | Meaning                      | Reply                   |
/// |-----------------|------------------------------|-------------------------|
/// | `F 145800000`   | Set frequency (Hz)           | `RPRT 0`                |
/// | `f`             | Get frequency                | `145800000`             |
/// | `M FM 12500`    | Set mode and passband (Hz)   | `RPRT 0`                |
/// | `m`             | Get mode and passband        | `FM` then `12500`       |
///
/// `RPRT 0` means success. A non-zero code is an error: Hamlib uses negative numbers, GQRX
/// uses `RPRT 1`. Either way the client throws `RigControlError.rejected`.
///
/// ## Setting Up the SDR Program
/// - **SDR++**: add a *Rigctl Server* module (Module Manager), then press Start in its panel.
///   Default port 4532.
/// - **GQRX**: Tools → Remote Control (enable it). Default port 7356. Under Tools → Remote
///   control settings, allow the IP address of the device running your app.
/// - **Hamlib rigctld** (for a hardware radio): `rigctld -m <model> -r <serial port>`.
///   Default port 4532.
///
/// ## Example
/// ```swift
/// let sdr = RigctlClient(host: "127.0.0.1", port: RigctlClient.gqrxPort)
/// try await sdr.setMode(.fm, passbandHz: 15_000)
/// try await sdr.setFrequency(145_800_000)
/// ```
///
/// The client connects on the first command and reconnects automatically after the
/// connection drops. Commands from several tasks are sent one at a time, never interleaved.
public actor RigctlClient: FrequencyControl {

    /// Default port of Hamlib `rigctld` and of SDR++'s rigctl server
    public static let rigctldPort: UInt16 = 4532

    /// Default port of GQRX's remote control
    public static let gqrxPort: UInt16 = 7356

    /// Host name or IP address of the radio or SDR program
    public nonisolated let host: String

    /// TCP port
    public nonisolated let port: UInt16

    /// How long to wait for a connection or a reply (seconds)
    public nonisolated let timeout: TimeInterval

    /// Opens connections; replaced in tests
    private let connector: @Sendable (String, UInt16, TimeInterval) async throws -> any LineConnection

    private var connection: (any LineConnection)?

    /// Commands waiting for the one in progress to finish
    private var isBusy = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    // MARK: - Initialization

    /// Creates a client. Nothing is sent until the first command.
    ///
    /// - Parameters:
    ///   - host: Host name or IP address (default `127.0.0.1`, the same computer)
    ///   - port: TCP port: `rigctldPort` (4532) for SDR++ and Hamlib, `gqrxPort` (7356) for GQRX
    ///   - timeout: How long to wait for a connection or a reply (default 2 s)
    public init(host: String = "127.0.0.1", port: UInt16 = RigctlClient.rigctldPort, timeout: TimeInterval = 2) {
        self.init(host: host, port: port, timeout: timeout) { host, port, timeout in
            try await TCPLineConnection.connect(host: host, port: port, timeout: timeout)
        }
    }

    /// Creates a client with a custom connection (for tests).
    init(host: String, port: UInt16, timeout: TimeInterval,
         connector: @escaping @Sendable (String, UInt16, TimeInterval) async throws -> any LineConnection) {
        self.host = host
        self.port = port
        self.timeout = timeout
        self.connector = connector
    }

    // MARK: - Commands

    /// Tunes to a frequency.
    ///
    /// - Parameter hertz: Frequency in Hz (must be positive)
    /// - Throws: `RigControlError`
    public func setFrequency(_ hertz: Int) async throws {
        guard hertz > 0 else {
            throw RigControlError.invalidArgument("Frequency must be positive, got \(hertz)")
        }
        _ = try await exchange("F \(hertz)", replyLines: 0)
    }

    /// The frequency the radio is tuned to, in Hz.
    ///
    /// - Throws: `RigControlError`
    public func frequency() async throws -> Int {
        let reply = try await exchange("f", replyLines: 1)
        // Hamlib may send a decimal point ("145800000.000000"); GQRX sends an integer
        guard let value = Double(reply[0].trimmingCharacters(in: .whitespaces)) else {
            throw RigControlError.unexpectedResponse(command: "f", response: reply[0])
        }
        return Int(value.rounded())
    }

    /// Selects a demodulation mode and filter width.
    ///
    /// - Parameters:
    ///   - mode: The mode, such as `.fm`
    ///   - passbandHz: Filter width in Hz. Typical values: FM 12,500 to 15,000, WFM for NOAA
    ///     APT about 40,000, USB or LSB 2,400, CW 500.
    /// - Throws: `RigControlError`
    public func setMode(_ mode: RadioMode, passbandHz: Int) async throws {
        guard mode.isValid else {
            throw RigControlError.invalidArgument("Mode names are letters, digits and underscores, got \"\(mode.rawValue)\"")
        }
        guard passbandHz > 0 else {
            throw RigControlError.invalidArgument("Passband must be positive, got \(passbandHz)")
        }
        _ = try await exchange("M \(mode.rawValue) \(passbandHz)", replyLines: 0)
    }

    /// The radio's current mode and filter width.
    ///
    /// - Throws: `RigControlError`
    public func mode() async throws -> (mode: RadioMode, passbandHz: Int) {
        let reply = try await exchange("m", replyLines: 2)
        guard let passband = Int(reply[1].trimmingCharacters(in: .whitespaces)) else {
            throw RigControlError.unexpectedResponse(command: "m", response: reply.joined(separator: "\n"))
        }
        return (RadioMode(rawValue: reply[0].trimmingCharacters(in: .whitespaces)), passband)
    }

    /// Closes the connection. The next command opens a new one.
    public func disconnect() async {
        await connection?.close()
        connection = nil
    }

    // MARK: - Exchange

    /// Sends one command and reads its reply.
    ///
    /// - Parameters:
    ///   - command: The command line
    ///   - replyLines: How many value lines a successful reply has. Zero means a set command,
    ///     whose reply is a single `RPRT` line.
    /// - Returns: The value lines (empty for set commands)
    private func exchange(_ command: String, replyLines: Int) async throws -> [String] {
        // One command at a time: the actor alone isn't enough, because it lets another call
        // run while this one waits for its reply, and the replies would be mixed up
        await acquire()
        defer { release() }

        do {
            let link = try await openConnection()
            try await link.send(command)

            let first = try await link.receiveLine(timeout: timeout)
            // A reply starting with RPRT is a status: success for set commands, an error for
            // get commands (which answer with values when they succeed)
            if let code = Self.reportCode(first) {
                guard code == 0, replyLines == 0 else {
                    throw RigControlError.rejected(command: command, code: code)
                }
                return []
            }
            guard replyLines > 0 else {
                throw RigControlError.unexpectedResponse(command: command, response: first)
            }
            var lines = [first]
            while lines.count < replyLines {
                lines.append(try await link.receiveLine(timeout: timeout))
            }
            return lines
        } catch let error as RigControlError {
            // After a timeout or a dropped link, the stream may hold a late or partial reply.
            // Start the next command on a fresh connection so replies can't get out of step.
            switch error {
            case .rejected, .invalidArgument:
                break
            default:
                await disconnect()
            }
            throw error
        }
    }

    /// The open connection, or a new one.
    private func openConnection() async throws -> any LineConnection {
        if let connection {
            return connection
        }
        do {
            let opened = try await connector(host, port, timeout)
            connection = opened
            return opened
        } catch let error as RigControlError {
            throw error
        } catch {
            throw RigControlError.connectionFailed("\(error)")
        }
    }

    /// The code from an `RPRT n` line, or nil if the line is something else.
    static func reportCode(_ line: String) -> Int? {
        let parts = line.trimmingCharacters(in: .whitespaces).split(separator: " ")
        guard parts.count == 2, parts[0] == "RPRT" else {
            return nil
        }
        return Int(parts[1])
    }

    private func acquire() async {
        if isBusy {
            await withCheckedContinuation { waiting.append($0) }
        } else {
            isBusy = true
        }
    }

    private func release() {
        if waiting.isEmpty {
            isBusy = false
        } else {
            waiting.removeFirst().resume()   // hand the turn straight to the next command
        }
    }
}
