//
//  ElementSetClientFailureTests.swift
//  EphemerisCatalogTests
//
//  Failed requests, rate limits and invalid queries. The point of these tests is that a
//  failing app never turns into a stream of requests to the server.
//

import XCTest
@testable import EphemerisCatalog

final class ElementSetClientFailureTests: ElementSetClientTestCase {

    // MARK: - Failed Requests

    func testCatalog_whenRefreshFailsWithCachedCopy_shouldReturnStaleCopy() async throws {
        // Given: a cached group that has expired, and a server that is now failing
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        let client = makeClient()
        _ = try await client.catalog(for: .group(.stations))
        clock.advance(by: 3 * 3600)
        await server.respondAlways(FakeResponse(status: 500, body: "Server error"))

        // When
        let result = try await client.catalog(for: .group(.stations))

        // Then: the old data, marked with the reason it couldn't be refreshed
        XCTAssertEqual(result.source, .staleCache(.httpStatus(500)))
        XCTAssertEqual(result.fetchedAt, start)
        XCTAssertEqual(result.catalog.satellites.count, 1)
    }

    func testCatalog_whenRequestFailsWithoutCache_shouldThrow() async {
        // Given
        await server.respondAlways(FakeResponse(status: 503, body: "Unavailable"))
        let client = makeClient()

        // When / Then
        await assertThrows(.httpStatus(503)) { try await client.catalog(for: .group(.stations)) }
    }

    func testCatalog_afterFailure_shouldWaitFifteenMinutesBeforeRetrying() async throws {
        // Given: one failed request
        await server.respondAlways(FakeResponse(status: 500, body: "Server error"))
        let client = makeClient()
        await assertThrows(.httpStatus(500)) { try await client.catalog(for: .group(.stations)) }

        // When: the app retries immediately, in a loop
        let retryTime = start.addingTimeInterval(15 * 60)
        for _ in 0..<5 {
            await assertThrows(.backingOff(until: retryTime)) { try await client.catalog(for: .group(.stations)) }
        }

        // Then: no further requests were sent
        var requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 1)

        // When: fifteen minutes later, with the server back
        clock.advance(by: 15 * 60)
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        let result = try await client.catalog(for: .group(.stations))

        // Then
        requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 2)
        XCTAssertEqual(result.source, .network)
    }

    func testCatalog_afterFailure_shouldNotDelayOtherQueries() async throws {
        // Given: one query failed
        await server.respond { request in
            Fixtures.query(of: request).contains("stations") ? FakeResponse(status: 500, body: "")
                                                     : .ok(Fixtures.document(Fixtures.ao91))
        }
        let client = makeClient()
        await assertThrows(.httpStatus(500)) { try await client.catalog(for: .group(.stations)) }

        // When
        let other = try await client.catalog(for: .group(.amateur))

        // Then
        XCTAssertEqual(other.source, .network)
    }

    func testCatalog_whenTransportFails_shouldReportTransportErrorAndUseStaleCopy() async throws {
        // Given
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        let client = makeClient()
        _ = try await client.catalog(for: .group(.stations))
        clock.advance(by: 3 * 3600)
        await server.respond { _ in throw URLError(.notConnectedToInternet) }

        // When
        let result = try await client.catalog(for: .group(.stations))

        // Then
        guard case .staleCache(.transport) = result.source else {
            return XCTFail("Expected a stale copy after a transport error, got \(result.source)")
        }
    }

    func testCatalog_withUnreadableResponse_shouldReportInvalidResponse() async {
        // Given: something other than the server answered, such as a captive Wi-Fi portal
        await server.respondAlways(.ok("<html><body>Please sign in</body></html>"))
        let client = makeClient()

        // When / Then
        await assertThrows(.invalidResponse("<html><body>Please sign in</body></html>")) {
            try await client.catalog(for: .group(.stations))
        }
    }

    // MARK: - Rate Limits

    func testCatalog_whenRateLimited_shouldPauseEveryQueryForTwoHours() async throws {
        // Given
        await server.respondAlways(FakeResponse(status: 403, body: "Forbidden"))
        let client = makeClient()
        let pausedUntil = start.addingTimeInterval(2 * 3600)

        // When
        await assertThrows(.rateLimited(until: pausedUntil)) { try await client.catalog(for: .group(.stations)) }
        await assertThrows(.rateLimited(until: pausedUntil)) { try await client.catalog(for: .group(.amateur)) }
        await assertThrows(.rateLimited(until: pausedUntil)) { try await client.catalog(for: .catalogNumber(25544)) }

        // Then: only the first request was sent
        let requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 1)
    }

    func testCatalog_whenRateLimited_shouldStayPausedAfterRelaunchAndCacheClear() async throws {
        // Given
        await server.respondAlways(FakeResponse(status: 429, body: "Too Many Requests"))
        let pausedUntil = start.addingTimeInterval(2 * 3600)
        await assertThrows(.rateLimited(until: pausedUntil)) { try await self.makeClient().catalog(for: .group(.active)) }

        // When: the app relaunches, clears its cache and tries again
        let relaunched = makeClient()
        try await relaunched.clearCache()
        clock.advance(by: 3600)
        await assertThrows(.rateLimited(until: pausedUntil)) { try await relaunched.catalog(for: .group(.active)) }

        // Then
        var requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 1)

        // When: the pause is over
        clock.advance(by: 3600)
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        _ = try await relaunched.catalog(for: .group(.active))

        // Then
        requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 2)
    }

    func testCatalog_whenRateLimitedWithLongerRetryAfter_shouldHonorIt() async {
        // Given
        await server.respondAlways(FakeResponse(status: 429, body: "", headers: ["Retry-After": "21600"]))
        let client = makeClient()

        // When / Then: six hours instead of the two-hour default
        await assertThrows(.rateLimited(until: start.addingTimeInterval(21600))) {
            try await client.catalog(for: .group(.stations))
        }
    }

    func testCatalog_whenRateLimitedWithCachedCopy_shouldReturnStaleCopy() async throws {
        // Given
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        let client = makeClient()
        _ = try await client.catalog(for: .group(.stations))
        clock.advance(by: 3 * 3600)
        await server.respondAlways(FakeResponse(status: 403, body: ""))

        // When
        let result = try await client.catalog(for: .group(.stations))

        // Then
        XCTAssertEqual(result.source, .staleCache(.rateLimited(until: start.addingTimeInterval(5 * 3600))))
    }

    // MARK: - Invalid Queries

    func testCatalog_withInvalidQueries_shouldThrowWithoutSendingRequests() async {
        // Given
        let client = makeClient()
        let invalid: [ElementSetQuery] = [
            .catalogNumber(0),
            .catalogNumber(1_000_000_000),
            .internationalDesignator("98067"),
            .internationalDesignator("1998-067A"),
            .name("ab"),
            .name("   "),
            .group("amateur&FORMAT=TLE"),
            .group("")
        ]

        // When
        for query in invalid {
            do {
                _ = try await client.catalog(for: query)
                XCTFail("\(query) should have been rejected")
            } catch CatalogFetchError.invalidQuery {
                // expected
            } catch {
                XCTFail("\(query) threw \(error)")
            }
        }

        // Then
        let requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 0)
    }

    func testCatalog_whenServerSaysInvalidQuery_shouldThrowInvalidQuery() async {
        // Given: a group name the server doesn't know
        await server.respondAlways(.ok("Invalid query: \"GROUP=not-a-group\""))
        let client = makeClient()

        // When / Then
        await assertThrows(.invalidQuery("Invalid query: \"GROUP=not-a-group\"")) {
            try await client.catalog(for: .group("not-a-group"))
        }
    }

    func testCatalog_whenServerSaysInvalidQueryWithCachedCopy_shouldStillThrow() async throws {
        // Given: a cached answer, then the server stops recognizing the query (a retired group)
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        let client = makeClient()
        _ = try await client.catalog(for: .group("retired-group"))
        clock.advance(by: 3 * 3600)
        await server.respondAlways(.ok("Invalid query"))

        // When / Then: a query that can never succeed is reported, not hidden behind old data
        await assertThrows(.invalidQuery("Invalid query")) {
            try await client.catalog(for: .group("retired-group"))
        }
    }
}
