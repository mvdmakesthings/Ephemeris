//
//  FakeRigServer.swift
//  EphemerisRadioTests
//
//  A real TCP server on 127.0.0.1 that speaks enough rigctl to stand in for SDR++, GQRX or
//  Hamlib rigctld. Tests talk to it over an actual socket, so the connection code is
//  exercised end to end without any radio or SDR program.
//

import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif
@testable import EphemerisRadio

/// How the fake server answers one command line
enum FakeReply: Sendable {
    /// Send these lines back
    case lines([String])
    /// Say nothing (to test timeouts)
    case silent
    /// Close the connection without answering
    case hangUp
}

final class FakeRigServer: @unchecked Sendable {

    /// The port the server is listening on (chosen by the system)
    let port: UInt16

    private let listener: Int32
    private let lock = NSLock()
    private var receivedLines: [String] = []
    private var acceptedCount = 0
    private var clients: [Int32] = []
    private let respond: @Sendable (String) -> FakeReply

    /// Starts a server. `respond` decides the reply to each line received.
    init(respond: @escaping @Sendable (String) -> FakeReply) throws {
        self.respond = respond
        // The client may close first; a write to a closed socket must not kill the test run
        signal(SIGPIPE, SIG_IGN)

        let descriptor = socket(AF_INET, Socket.streamType, 0)
        guard descriptor >= 0 else { throw RigControlError.connectionFailed("socket") }
        var reuse: Int32 = 1
        setsockopt(descriptor, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_in()
        #if canImport(Darwin)
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        #endif
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = 0                              // let the system pick a free port
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let bound = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { generic in
                bind(descriptor, generic, length) == 0
                    && listen(descriptor, 8) == 0
                    && getsockname(descriptor, generic, &length) == 0
            }
        }
        guard bound else { throw RigControlError.connectionFailed("bind") }
        listener = descriptor
        port = UInt16(bigEndian: address.sin_port)

        let thread = Thread { [self] in acceptLoop() }
        thread.start()
    }

    /// Every line received, across all connections, in order
    var received: [String] {
        lock.lock(); defer { lock.unlock() }
        return receivedLines
    }

    /// How many connections have been accepted
    var connectionCount: Int {
        lock.lock(); defer { lock.unlock() }
        return acceptedCount
    }

    /// Stops listening and closes every connection.
    func stop() {
        Socket.shutdown(listener)
        Socket.close(listener)
        lock.lock()
        let open = clients
        clients.removeAll()
        lock.unlock()
        open.forEach { Socket.shutdown($0); Socket.close($0) }
    }

    private func acceptLoop() {
        while true {
            let client = accept(listener, nil, nil)
            guard client >= 0 else { return }   // listener closed
            lock.lock()
            acceptedCount += 1
            clients.append(client)
            lock.unlock()
            let thread = Thread { [self] in serve(client) }
            thread.start()
        }
    }

    private func serve(_ client: Int32) {
        var buffer: [UInt8] = []
        while true {
            guard let chunk = try? Socket.receive(on: client), !chunk.isEmpty else { return }
            buffer.append(contentsOf: chunk)
            while let newline = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                let line = String(bytes: buffer[..<newline], encoding: .utf8) ?? ""
                buffer.removeSubrange(...newline)
                lock.lock()
                receivedLines.append(line)
                lock.unlock()

                switch respond(line) {
                case .lines(let lines):
                    let bytes = Array(lines.map { $0 + "\n" }.joined().utf8)
                    guard (try? Socket.sendAll(bytes, on: client)) != nil else { return }
                case .silent:
                    continue
                case .hangUp:
                    Socket.shutdown(client)
                    return
                }
            }
        }
    }

    // MARK: - Program Personalities

    /// Answers the way SDR++ and Hamlib rigctld do. Tracks frequency and mode like a radio.
    static func hamlibStyle() throws -> FakeRigServer {
        let state = RadioState()
        return try FakeRigServer { line in state.handle(line, errorCode: -1, frequencySuffix: ".000000") }
    }

    /// Answers the way GQRX's remote control does: integer frequency, `RPRT 1` for errors.
    static func gqrxStyle() throws -> FakeRigServer {
        let state = RadioState()
        return try FakeRigServer { line in state.handle(line, errorCode: 1, frequencySuffix: "") }
    }
}

/// A radio's frequency and mode, shared by the server's connection threads
final class RadioState: @unchecked Sendable {
    private let lock = NSLock()
    private var frequency = 100_000_000
    private var mode = "FM"
    private var passband = 12_000

    func handle(_ line: String, errorCode: Int, frequencySuffix: String) -> FakeReply {
        lock.lock(); defer { lock.unlock() }
        let parts = line.split(separator: " ").map(String.init)
        switch parts.first {
        case "F":
            // Reject frequencies outside 24 MHz to 1.766 GHz, like an RTL-SDR
            guard parts.count == 2, let hertz = Int(parts[1]), (24_000_000...1_766_000_000).contains(hertz) else {
                return .lines(["RPRT \(errorCode)"])
            }
            frequency = hertz
            return .lines(["RPRT 0"])
        case "f":
            return .lines(["\(frequency)\(frequencySuffix)"])
        case "M":
            guard parts.count == 3, let width = Int(parts[2]) else { return .lines(["RPRT \(errorCode)"]) }
            mode = parts[1]
            passband = width
            return .lines(["RPRT 0"])
        case "m":
            return .lines([mode, "\(passband)"])
        default:
            return .lines(["RPRT \(errorCode)"])
        }
    }
}
