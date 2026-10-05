//
//  CelesTrakClientTests.swift
//  EphemerisCatalogTests
//
//  Requests, caching and request sharing. Every test runs against FakeCelesTrak: nothing
//  here ever sends a request to the real CelesTrak.
//

import XCTest
@testable import EphemerisCatalog

final class CelesTrakClientTests: CelesTrakTestCase {

    // MARK: - Requests

    func testRequest_forEachQuery_shouldUseGPEndpointWithJSONFormat() throws {
        // Given
        let client = makeClient()

        // When
        let group = try client.request(for: .group(.amateur))
        let number = try client.request(for: .catalogNumber(25544))
        let launch = try client.request(for: .internationalDesignator("1998-067"))
        let name = try client.request(for: .name("NOAA 19"))

        // Then: the documented gp.php form, always asking for OMM JSON
        XCTAssertEqual(group.url?.absoluteString, "https://celestrak.org/NORAD/elements/gp.php?GROUP=amateur&FORMAT=JSON")
        XCTAssertEqual(number.url?.absoluteString, "https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=JSON")
        XCTAssertEqual(launch.url?.absoluteString, "https://celestrak.org/NORAD/elements/gp.php?INTDES=1998-067&FORMAT=JSON")
        XCTAssertEqual(name.url?.absoluteString, "https://celestrak.org/NORAD/elements/gp.php?NAME=NOAA%2019&FORMAT=JSON")
    }

    func testRequest_shouldIdentifyTheAppAndLibrary() throws {
        // Given
        let client = makeClient()

        // When
        let request = try client.request(for: .group(.stations))

        // Then
        let userAgent = try XCTUnwrap(request.value(forHTTPHeaderField: "User-Agent"))
        XCTAssertTrue(userAgent.hasPrefix("EphemerisTests/1.0 Ephemeris/2.0"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    // MARK: - Caching

    func testCatalog_calledTwiceWithinRefreshInterval_shouldDownloadOnce() async throws {
        // Given
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss, Fixtures.noaa19)))
        let client = makeClient()

        // When
        let first = try await client.catalog(for: .group(.stations))
        clock.advance(by: 2 * 3600 - 1)
        let second = try await client.catalog(for: .group(.stations))

        // Then
        let requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(first.source, .network)
        XCTAssertEqual(second.source, .cache)
        XCTAssertEqual(second.catalog.satellites.map(\.catalogNumber), [25544, 33591])
        XCTAssertEqual(second.fetchedAt, start)
    }

    func testCatalog_afterRefreshInterval_shouldDownloadAgain() async throws {
        // Given
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        let client = makeClient()
        _ = try await client.catalog(for: .group(.stations))

        // When
        clock.advance(by: 2 * 3600)
        let refreshed = try await client.catalog(for: .group(.stations))

        // Then
        let requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 2)
        XCTAssertEqual(refreshed.source, .network)
        XCTAssertEqual(refreshed.fetchedAt, start.addingTimeInterval(2 * 3600))
    }

    func testInit_withRefreshIntervalBelowMinimum_shouldUseTwoHours() async throws {
        // Given: an app asking to refresh every minute
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        let client = makeClient(refreshInterval: 60)
        XCTAssertEqual(client.refreshInterval, 2 * 3600)

        // When
        _ = try await client.catalog(for: .group(.stations))
        clock.advance(by: 3600)
        _ = try await client.catalog(for: .group(.stations))

        // Then: still one request after an hour
        let requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 1)
    }

    func testCatalog_afterRelaunch_shouldReadDiskCacheWithoutDownloading() async throws {
        // Given: one launch downloads the group
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss, Fixtures.ao91)))
        _ = try await makeClient().catalog(for: .group(.amateur))

        // When: the app relaunches (a new client on the same directory) an hour later
        clock.advance(by: 3600)
        let relaunched = try await makeClient().catalog(for: .group(.amateur))

        // Then
        let requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(relaunched.source, .cache)
        XCTAssertEqual(relaunched.fetchedAt, start)
        XCTAssertEqual(relaunched.catalog.satellites.count, 2)
    }

    func testCachedCatalog_shouldNeverDownload() async throws {
        // Given
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        let client = makeClient()

        // When / Then: nothing cached yet
        await assertThrows(.notCached) { try await client.cachedCatalog(for: .group(.stations)) }

        // When: cached, then long expired
        _ = try await client.catalog(for: .group(.stations))
        clock.advance(by: 30 * 86400)
        let cached = try await client.cachedCatalog(for: .group(.stations))

        // Then: the old copy is returned and nothing new was requested
        let requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(cached.fetchedAt, start)
    }

    func testClearCache_shouldDownloadAgainOnNextCall() async throws {
        // Given
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        let client = makeClient()
        _ = try await client.catalog(for: .group(.stations))

        // When
        try await client.clearCache()
        _ = try await client.catalog(for: .group(.stations))

        // Then
        let requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 2)
    }

    // MARK: - Single Satellites

    func testCatalogNumber_inFreshCachedGroup_shouldNotDownload() async throws {
        // Given: the amateur group is cached
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss, Fixtures.noaa19, Fixtures.ao91)))
        let client = makeClient()
        _ = try await client.catalog(for: .group(.amateur))

        // When
        let single = try await client.catalog(for: .catalogNumber(43017))

        // Then: answered from the group, narrowed to the one satellite
        let queries = await server.queries
        XCTAssertEqual(queries, ["GROUP=amateur"])
        XCTAssertEqual(single.source, .cache)
        XCTAssertEqual(single.catalog.satellites.map(\.catalogNumber), [43017])
        XCTAssertEqual(single.fetchedAt, start)
    }

    func testCatalogNumber_notInAnyGroup_shouldDownloadIt() async throws {
        // Given: a cached group without the satellite
        await server.respond { request in
            Fixtures.query(of: request).contains("CATNR") ? .ok(Fixtures.document(Fixtures.noaa19))
                                                  : .ok(Fixtures.document(Fixtures.iss))
        }
        let client = makeClient()
        _ = try await client.catalog(for: .group(.stations))

        // When
        let single = try await client.catalog(for: .catalogNumber(33591))

        // Then
        let queries = await server.queries
        XCTAssertEqual(queries, ["GROUP=stations", "CATNR=33591"])
        XCTAssertEqual(single.source, .network)
        XCTAssertEqual(single.catalog.satellites.map(\.catalogNumber), [33591])
    }

    func testCatalogNumber_inExpiredGroupOnly_shouldDownloadIt() async throws {
        // Given: the group that has the satellite is older than the refresh interval
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        let client = makeClient()
        _ = try await client.catalog(for: .group(.stations))
        clock.advance(by: 3 * 3600)

        // When
        _ = try await client.catalog(for: .catalogNumber(25544))

        // Then: the old group is not trusted for a fresh answer
        let queries = await server.queries
        XCTAssertEqual(queries, ["GROUP=stations", "CATNR=25544"])
    }

    func testCatalogNumber_whenCelesTrakHasNoData_shouldCacheTheEmptyAnswer() async throws {
        // Given: CelesTrak's plain-text answer for a query that matches nothing
        await server.respondAlways(.ok("No GP data found"))
        let client = makeClient()

        // When: an app asks for the same missing satellite repeatedly
        let first = try await client.catalog(for: .catalogNumber(99999))
        let second = try await client.catalog(for: .catalogNumber(99999))

        // Then
        let requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertTrue(first.catalog.satellites.isEmpty)
        XCTAssertTrue(second.catalog.satellites.isEmpty)
        XCTAssertEqual(second.source, .cache)
    }

    func testCatalog_withEmptyJSONArray_shouldReturnEmptyCatalog() async throws {
        // Given
        await server.respondAlways(.ok("[ ]\n"))

        // When
        let result = try await makeClient().catalog(for: .name("NO SUCH SATELLITE"))

        // Then
        XCTAssertTrue(result.catalog.satellites.isEmpty)
        XCTAssertTrue(result.catalog.rejections.isEmpty)
    }

    // MARK: - Sharing and Pacing

    func testCatalog_concurrentCallsForSameQuery_shouldShareOneRequest() async throws {
        // Given: responses are held so all callers arrive while the first request is running
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        await server.hold()
        let client = makeClient()

        // When
        async let first = client.catalog(for: .group(.stations))
        async let second = client.catalog(for: .group(.stations))
        async let third = client.catalog(for: .group(.stations))
        while await server.heldCount == 0 {
            await Task.yield()
        }
        // Give the other callers time to reach the client before the response arrives
        for _ in 0..<100 {
            await Task.yield()
        }
        await server.release()
        let results = try await [first, second, third]

        // Then
        let requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(results.map(\.catalog.satellites.count), [1, 1, 1])
    }

    func testCatalog_differentQueriesBackToBack_shouldBeAtLeastOneSecondApart() async throws {
        // Given
        await server.respondAlways(.ok(Fixtures.document(Fixtures.iss)))
        let client = makeClient()

        // When: three different queries with no time passing between them
        _ = try await client.catalog(for: .group(.stations))
        _ = try await client.catalog(for: .group(.amateur))
        _ = try await client.catalog(for: .group(.weather))

        // Then: the second and third each waited one second
        let requestCount = await server.requestCount
        XCTAssertEqual(requestCount, 3)
        XCTAssertEqual(clock.sleeps, [1, 1])
    }

    // MARK: - Cache Keys

    func testCacheKey_forUnusualNames_shouldBeSafeFileNames() {
        // Given
        let queries: [CelesTrakQuery] = [.name("NOAA/19 ü"), .name("../../etc"), .name("noaa 19")]

        // When
        let keys = queries.map(\.cacheKey)

        // Then: only hex digits after the prefix, and case-insensitive names share a key
        for key in keys {
            XCTAssertNotNil(key.range(of: "^name-[0-9a-f]+$", options: .regularExpression), key)
        }
        XCTAssertEqual(CelesTrakQuery.name("noaa 19").cacheKey, CelesTrakQuery.name(" NOAA 19 ").cacheKey)
    }
}
