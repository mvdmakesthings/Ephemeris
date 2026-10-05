//
//  TestDoubles.swift
//  EphemerisCatalogTests
//
//  A fake CelesTrak and a manual clock. With these, the client's tests never send a real
//  request and never wait in real time.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import EphemerisCatalog

/// A canned HTTP response
struct FakeResponse: Sendable {
    let status: Int
    let body: String
    var headers: [String: String] = [:]

    static func ok(_ body: String) -> FakeResponse {
        FakeResponse(status: 200, body: body)
    }
}

/// Stands in for CelesTrak. Answers each request from a handler and records what was sent.
actor FakeCelesTrak: CatalogTransport {

    /// Every request received, in order
    private(set) var requests: [URLRequest] = []

    /// Decides the response for a request (default: an empty JSON array)
    private var handler: @Sendable (URLRequest) throws -> FakeResponse = { _ in .ok("[]") }

    /// When true, responses wait until `release()` is called
    private var isHolding = false
    private var held: [CheckedContinuation<Void, Never>] = []

    func respond(with handler: @escaping @Sendable (URLRequest) throws -> FakeResponse) {
        self.handler = handler
    }

    func respondAlways(_ response: FakeResponse) {
        handler = { _ in response }
    }

    func hold() {
        isHolding = true
    }

    func release() {
        isHolding = false
        held.forEach { $0.resume() }
        held.removeAll()
    }

    var heldCount: Int { held.count }

    var requestCount: Int { requests.count }

    /// The `gp.php` query parameters of each request, such as `["CATNR=25544"]`
    var queries: [String] {
        requests.compactMap { request in
            request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
                .queryItems?
                .filter { $0.name != "FORMAT" }
                .map { "\($0.name)=\($0.value ?? "")" }
                .joined(separator: "&")
        }
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        if isHolding {
            await withCheckedContinuation { held.append($0) }
        }
        let response = try handler(request)
        guard let url = request.url,
              let http = HTTPURLResponse(url: url, statusCode: response.status,
                                         httpVersion: "HTTP/1.1", headerFields: response.headers) else {
            throw URLError(.badURL)
        }
        return (Data(response.body.utf8), http)
    }
}

/// A clock that only moves when told to. `sleep` advances it instantly and records how long
/// the client asked to wait.
final class ManualClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    private var recordedSleeps: [TimeInterval] = []

    init(_ start: Date) {
        current = start
    }

    var now: Date {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    var sleeps: [TimeInterval] {
        lock.lock(); defer { lock.unlock() }
        return recordedSleeps
    }

    func advance(by seconds: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        current = current.addingTimeInterval(seconds)
    }

    private func recordSleep(_ seconds: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        recordedSleeps.append(seconds)
        current = current.addingTimeInterval(seconds)
    }

    var timeSource: TimeSource {
        TimeSource(
            now: { self.now },
            sleep: { seconds in self.recordSleep(seconds) }
        )
    }
}

/// OMM JSON in the form CelesTrak serves, for a few real satellites
enum Fixtures {

    static let iss = record(name: "ISS (ZARYA)", id: "1998-067A", catalogNumber: 25544,
                            orbit: (meanMotion: 15.49560532, eccentricity: 0.0006703, inclination: 51.6416))
    static let noaa19 = record(name: "NOAA 19", id: "2009-005A", catalogNumber: 33591,
                               orbit: (meanMotion: 14.12501077, eccentricity: 0.0013388, inclination: 99.1730))
    static let ao91 = record(name: "FOX-1B (AO-91)", id: "2017-073E", catalogNumber: 43017,
                             orbit: (meanMotion: 14.90000000, eccentricity: 0.0215000, inclination: 97.6000))

    /// The query string of a request, such as `CATNR=25544&FORMAT=JSON`
    static func query(of request: URLRequest) -> String {
        request.url?.query ?? ""
    }

    /// A JSON array of records
    static func document(_ records: String...) -> String {
        "[" + records.joined(separator: ",") + "]"
    }

    static func record(name: String, id: String, catalogNumber: Int,
                       orbit: (meanMotion: Double, eccentricity: Double, inclination: Double)) -> String {
        """
        {"OBJECT_NAME":"\(name)","OBJECT_ID":"\(id)","EPOCH":"2026-10-04T12:00:00.000000",\
        "MEAN_MOTION":\(orbit.meanMotion),"ECCENTRICITY":\(orbit.eccentricity),"INCLINATION":\(orbit.inclination),\
        "RA_OF_ASC_NODE":120.5,"ARG_OF_PERICENTER":80.25,"MEAN_ANOMALY":280.1,"EPHEMERIS_TYPE":0,\
        "CLASSIFICATION_TYPE":"U","NORAD_CAT_ID":\(catalogNumber),"ELEMENT_SET_NO":999,\
        "REV_AT_EPOCH":12345,"BSTAR":0.00012,"MEAN_MOTION_DOT":0.0001,"MEAN_MOTION_DDOT":0}
        """
    }
}
