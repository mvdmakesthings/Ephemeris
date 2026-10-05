//
//  TCPLineConnection.swift
//  EphemerisRadio
//
//  A TCP connection that sends and receives text one line at a time, the way the rigctl
//  protocol works. Built on BSD sockets so the same code runs, and is tested, on macOS, iOS
//  and Linux.
//

import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// A connection that exchanges newline-terminated text.
///
/// `TCPLineConnection` is the real implementation; tests can substitute their own.
public protocol LineConnection: Sendable {
    /// Sends one line. The newline is added for you.
    func send(_ line: String) async throws

    /// Waits for the next complete line, without its line ending.
    ///
    /// - Throws: `RigControlError.timeout` if no full line arrives in time, or
    ///   `.connectionClosed` if the other side hangs up
    func receiveLine(timeout: TimeInterval) async throws -> String

    /// Closes the connection. Safe to call more than once.
    func close() async
}

/// A line-based TCP connection over BSD sockets.
///
/// Blocking socket calls run on a private serial queue, never on Swift's cooperative thread
/// pool, and each call has a timeout so a silent radio can't hang the caller.
///
/// On iOS, connecting to another device on the local network (a Mac running SDR++, for
/// example) requires the `NSLocalNetworkUsageDescription` key in the app's Info.plist; the
/// system asks the user the first time.
public final class TCPLineConnection: LineConnection, @unchecked Sendable {

    // `@unchecked Sendable`: `buffer` and `isClosed` are only touched on `queue`, and
    // `descriptor` never changes after init.

    private let descriptor: Int32
    private let queue = DispatchQueue(label: "EphemerisRadio.TCPLineConnection")
    private var buffer: [UInt8] = []
    private var isClosed = false

    private init(descriptor: Int32) {
        self.descriptor = descriptor
    }

    deinit {
        if !isClosed {
            Socket.close(descriptor)
        }
    }

    /// Opens a connection.
    ///
    /// - Parameters:
    ///   - host: Host name or IP address, such as `"127.0.0.1"` or `"shack-mac.local"`
    ///   - port: TCP port (SDR++ and Hamlib rigctld default to 4532, GQRX to 7356)
    ///   - timeout: How long to wait for the connection (seconds)
    /// - Throws: `RigControlError.connectionFailed` with the reason
    public static func connect(host: String, port: UInt16, timeout: TimeInterval) async throws -> TCPLineConnection {
        let descriptor = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int32, Error>) in
            DispatchQueue.global().async {
                continuation.resume(with: Result { try Socket.connect(host: host, port: port, timeout: timeout) })
            }
        }
        return TCPLineConnection(descriptor: descriptor)
    }

    public func send(_ line: String) async throws {
        let bytes = Array((line + "\n").utf8)
        try await perform { [self] in
            guard !isClosed else { throw RigControlError.connectionClosed }
            try Socket.sendAll(bytes, on: descriptor)
        }
    }

    public func receiveLine(timeout: TimeInterval) async throws -> String {
        try await perform { [self] in
            let deadline = Date().addingTimeInterval(timeout)
            while true {
                guard !isClosed else { throw RigControlError.connectionClosed }

                // A complete line already buffered?
                if let newline = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                    var line = Array(buffer[..<newline])
                    buffer.removeSubrange(...newline)
                    if line.last == UInt8(ascii: "\r") {
                        line.removeLast()
                    }
                    guard let text = String(bytes: line, encoding: .utf8) else {
                        throw RigControlError.unexpectedResponse(command: "", response: "a reply that is not UTF-8 text")
                    }
                    return text
                }

                // Wait for more bytes, but never past the deadline
                let remaining = deadline.timeIntervalSinceNow
                guard remaining > 0, try Socket.waitForData(on: descriptor, timeout: remaining) else {
                    throw RigControlError.timeout
                }
                let chunk = try Socket.receive(on: descriptor)
                guard !chunk.isEmpty else {
                    throw RigControlError.connectionClosed   // orderly shutdown by the other side
                }
                buffer.append(contentsOf: chunk)
            }
        }
    }

    public func close() async {
        // Shut down first: that wakes a receive that is waiting on the queue right now
        Socket.shutdown(descriptor)
        _ = try? await perform { [self] in
            if !isClosed {
                isClosed = true
                Socket.close(descriptor)
            }
        }
    }

    /// Runs blocking work on the connection's serial queue.
    private func perform<T: Sendable>(_ work: @escaping @Sendable () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(with: Result { try work() })
            }
        }
    }
}

// MARK: - BSD Socket Calls

/// Thin wrappers over the BSD socket API. Darwin and Glibc name a few types and flags
/// differently; those differences live here and nowhere else.
enum Socket {

    #if canImport(Darwin)
    static let streamType = SOCK_STREAM
    static let sendFlags: Int32 = 0   // SIGPIPE is disabled per socket with SO_NOSIGPIPE
    #else
    static let streamType = Int32(SOCK_STREAM.rawValue)
    static let sendFlags = Int32(MSG_NOSIGNAL)   // don't raise SIGPIPE if the peer has gone
    #endif

    /// Resolves the host and connects to the first address that answers within the timeout.
    static func connect(host: String, port: UInt16, timeout: TimeInterval) throws -> Int32 {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC          // IPv4 or IPv6, whichever the host has
        hints.ai_socktype = streamType
        hints.ai_protocol = Int32(IPPROTO_TCP)

        var addresses: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(host, String(port), &hints, &addresses)
        guard status == 0, let first = addresses else {
            throw RigControlError.connectionFailed("Could not resolve \(host): \(String(cString: gai_strerror(status)))")
        }
        defer { freeaddrinfo(addresses) }

        var lastError = "no addresses"
        var candidate: UnsafeMutablePointer<addrinfo>? = first
        while let address = candidate?.pointee {
            candidate = address.ai_next
            let descriptor = socket(address.ai_family, address.ai_socktype, address.ai_protocol)
            guard descriptor >= 0 else {
                lastError = errorText()
                continue
            }
            do {
                try connect(descriptor, to: address, timeout: timeout)
                #if canImport(Darwin)
                var on: Int32 = 1
                setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
                #endif
                return descriptor
            } catch {
                lastError = "\(error)"
                close(descriptor)
            }
        }
        throw RigControlError.connectionFailed("Could not connect to \(host):\(port): \(lastError)")
    }

    /// Connects with a timeout: start a non-blocking connect, wait until the socket is
    /// writable, then read the result from `SO_ERROR`.
    private static func connect(_ descriptor: Int32, to address: addrinfo, timeout: TimeInterval) throws {
        let flags = fcntl(descriptor, F_GETFL, 0)
        _ = fcntl(descriptor, F_SETFL, flags | O_NONBLOCK)
        defer { _ = fcntl(descriptor, F_SETFL, flags) }   // back to blocking afterwards

        #if canImport(Darwin)
        let result = Darwin.connect(descriptor, address.ai_addr, address.ai_addrlen)
        #else
        let result = Glibc.connect(descriptor, address.ai_addr, address.ai_addrlen)
        #endif
        if result == 0 {
            return
        }
        guard errno == EINPROGRESS else {
            throw RigControlError.connectionFailed(errorText())
        }

        var poller = pollfd(fd: descriptor, events: Int16(POLLOUT), revents: 0)
        let ready = poll(&poller, 1, milliseconds(timeout))
        guard ready > 0 else {
            throw RigControlError.connectionFailed(ready == 0 ? "timed out" : errorText())
        }
        var socketError: Int32 = 0
        var length = socklen_t(MemoryLayout<Int32>.size)
        getsockopt(descriptor, SOL_SOCKET, SO_ERROR, &socketError, &length)
        guard socketError == 0 else {
            throw RigControlError.connectionFailed(String(cString: strerror(socketError)))
        }
    }

    /// Sends every byte, looping because `send` may write only part of the buffer.
    static func sendAll(_ bytes: [UInt8], on descriptor: Int32) throws {
        var offset = 0
        while offset < bytes.count {
            let sent = bytes[offset...].withUnsafeBytes { buffer in
                #if canImport(Darwin)
                Darwin.send(descriptor, buffer.baseAddress, buffer.count, sendFlags)
                #else
                Glibc.send(descriptor, buffer.baseAddress, buffer.count, sendFlags)
                #endif
            }
            guard sent > 0 else {
                if errno == EINTR { continue }
                throw RigControlError.connectionClosed
            }
            offset += sent
        }
    }

    /// Waits until bytes can be read. Returns false on timeout.
    static func waitForData(on descriptor: Int32, timeout: TimeInterval) throws -> Bool {
        var poller = pollfd(fd: descriptor, events: Int16(POLLIN), revents: 0)
        let ready = poll(&poller, 1, milliseconds(timeout))
        if ready < 0 && errno != EINTR {
            throw RigControlError.connectionClosed
        }
        return ready > 0
    }

    /// Reads whatever bytes are available. An empty result means the peer closed the connection.
    static func receive(on descriptor: Int32) throws -> [UInt8] {
        var chunk = [UInt8](repeating: 0, count: 4096)
        let count = chunk.withUnsafeMutableBytes { buffer in
            recv(descriptor, buffer.baseAddress, buffer.count, 0)
        }
        guard count >= 0 else {
            throw RigControlError.connectionClosed
        }
        return Array(chunk.prefix(count))
    }

    /// Stops both directions, waking any thread blocked on the socket.
    static func shutdown(_ descriptor: Int32) {
        #if canImport(Darwin)
        _ = Darwin.shutdown(descriptor, SHUT_RDWR)
        #else
        _ = Glibc.shutdown(descriptor, Int32(SHUT_RDWR))
        #endif
    }

    static func close(_ descriptor: Int32) {
        #if canImport(Darwin)
        _ = Darwin.close(descriptor)
        #else
        _ = Glibc.close(descriptor)
        #endif
    }

    /// A timeout in whole milliseconds for `poll`, at least 1 ms
    static func milliseconds(_ seconds: TimeInterval) -> Int32 {
        Int32(min(max(seconds * 1000, 1), Double(Int32.max)))
    }

    /// The text for the current `errno`
    static func errorText() -> String {
        String(cString: strerror(errno))
    }
}
