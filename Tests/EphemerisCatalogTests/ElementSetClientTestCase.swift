//
//  ElementSetClientTestCase.swift
//  EphemerisCatalogTests
//

import XCTest
@testable import EphemerisCatalog

/// Shared setup: a fresh cache directory, a fake server and a manual clock for each test.
class ElementSetClientTestCase: XCTestCase {

    var cacheDirectory: URL!
    var server: FakeElementSetServer!
    var clock: ManualClock!

    /// A placeholder endpoint; requests to it only ever reach `FakeElementSetServer`
    let endpoint = URL(string: "https://gp.example.org/elements/gp.php")!

    /// 2026-10-05 00:00 UTC, one half day after the fixtures' epoch
    let start = Date(timeIntervalSince1970: 1_791_158_400)

    override func setUp() {
        super.setUp()
        cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EphemerisCatalogTests-\(UUID().uuidString)", isDirectory: true)
        server = FakeElementSetServer()
        clock = ManualClock(start)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        super.tearDown()
    }

    /// A client using the test's fake server, clock and cache directory. Creating a second
    /// one with the same directory simulates relaunching the app.
    func makeClient(refreshInterval: TimeInterval = ElementSetClient.minimumRefreshInterval) -> ElementSetClient {
        ElementSetClient(endpoint: endpoint, appIdentifier: "EphemerisTests/1.0", cacheDirectory: cacheDirectory,
                        refreshInterval: refreshInterval, gravity: .wgs72,
                        transport: server, time: clock.timeSource)
    }

    /// Asserts that an async call throws a specific `CatalogFetchError`.
    func assertThrows<T>(_ expected: CatalogFetchError, file: StaticString = #filePath, line: UInt = #line,
                         _ body: () async throws -> T) async {
        do {
            _ = try await body()
            XCTFail("Expected \(expected), but nothing was thrown", file: file, line: line)
        } catch let error as CatalogFetchError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected \(expected), got \(error)", file: file, line: line)
        }
    }
}
