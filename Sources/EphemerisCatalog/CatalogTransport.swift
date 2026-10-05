//
//  CatalogTransport.swift
//  EphemerisCatalog
//
//  The two things ElementSetClient needs from the outside world, HTTP and time, behind small
//  seams so the tests can replace both and never touch the network or wait in real time.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Sends one HTTP request. `URLSessionTransport` is the real implementation; tests use a fake.
public protocol CatalogTransport: Sendable {
    /// Performs the request and returns the body and the HTTP response.
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// `CatalogTransport` backed by `URLSession`.
public struct URLSessionTransport: CatalogTransport {

    private let session: URLSession

    /// Creates a transport using the given session (default `.shared`).
    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CatalogFetchError.invalidResponse("Not an HTTP response")
        }
        return (data, http)
    }
}

/// The current time and a way to wait. Real by default; tests substitute a manual clock so
/// they can jump hours ahead to expire a cache without sleeping.
struct TimeSource: Sendable {
    let now: @Sendable () -> Date
    let sleep: @Sendable (TimeInterval) async throws -> Void

    static let system = TimeSource(
        now: { Date() },
        sleep: { seconds in try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)) }
    )
}
