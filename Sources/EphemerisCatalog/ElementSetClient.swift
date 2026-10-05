//
//  ElementSetClient.swift
//  EphemerisCatalog
//
//  Downloads element sets from a GP data server, caches them on disk, and makes it hard to
//  send the server more requests than the data needs.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Ephemeris

/// Fetches satellite catalogs from a GP (general perturbations) data server, with a disk cache
/// and built-in rate limits.
///
/// ## The Endpoint
/// The client works with any server that answers the common GP query format: one parameter
/// picking the satellites (`GROUP`, `CATNR`, `INTDES` or `NAME`) plus `FORMAT=JSON`, returning
/// an array of CCSDS OMM records. You pass the endpoint in; the library has no built-in server.
/// `docs/catalogs.md` recommends a free public endpoint that needs no account.
///
/// ## Being a Good Client
/// Public element-set servers are usually free services, and they block clients that download
/// the same data over and over. Element sets change only a few times a day, so almost every
/// request an app might make can be answered from a copy it already has. This client does that
/// for you:
///
/// - **Cache first.** Every response is saved to disk. A query is downloaded again only after
///   its copy is older than the refresh interval, which can't be set below two hours.
/// - **One request per query.** If several parts of an app ask for the same thing at once,
///   they share a single download.
/// - **Single satellites from groups.** A `.catalogNumber` query is answered from any cached
///   group that contains the satellite, so it costs a request only when it really is new.
/// - **"Not found" is cached too.** Looking up a satellite the server doesn't have doesn't
///   repeat the request.
/// - **Paced.** Requests are at least one second apart.
/// - **Backs off.** After a failed request, the same query waits 15 minutes before it is tried
///   again. If the server says the client is sending too much (HTTP 403 or 429), every request
///   stops for two hours, and that pause is saved to disk so relaunching the app doesn't end it.
/// - **Keeps working offline.** When a refresh fails, the expired copy is returned with
///   `source == .staleCache(error)` instead of an error.
/// - **Identifies itself.** Each request carries a `User-Agent` naming your app.
///
/// ## Example
/// ```swift
/// let client = ElementSetClient(endpoint: gpEndpoint, appIdentifier: "MyTracker/1.0")
/// let amateur = try await client.catalog(for: .group(.amateur))
/// print("\(amateur.catalog.satellites.count) satellites, downloaded \(amateur.fetchedAt)")
///
/// let overhead = await amateur.catalog.lookAngles(from: observer, at: Date(), minElevationDeg: 10)
/// ```
///
/// Use one client for the whole app, so every caller shares the pacing and in-flight requests.
public actor ElementSetClient {

    // MARK: - Limits

    /// The shortest allowed refresh interval: two hours. Public GP data is regenerated a few
    /// times a day at most, so downloading sooner returns the same data.
    public static let minimumRefreshInterval: TimeInterval = 2 * 3600

    /// The shortest time between two requests: one second
    public static let minimumRequestSpacing: TimeInterval = 1

    /// How long a query waits after a failed request before it is tried again: 15 minutes
    public static let retryInterval: TimeInterval = 15 * 60

    /// How long every request pauses after the server reports too many requests: two hours,
    /// or longer if the response's `Retry-After` header asks for it
    public static let rateLimitPause: TimeInterval = 2 * 3600

    // MARK: - Configuration

    /// How old a cached copy may get before it is downloaded again
    public nonisolated let refreshInterval: TimeInterval

    /// The GP query URL that query parameters are added to
    public nonisolated let endpoint: URL

    /// Where responses are cached
    public nonisolated let cacheDirectory: URL

    /// The `User-Agent` header sent with each request
    public nonisolated let userAgent: String

    /// Gravity model used for each satellite's SGP4 propagator
    private let gravity: GravityModel

    private let transport: any CatalogTransport
    private let time: TimeSource
    private let cache: CatalogCache

    // MARK: - State

    /// Parsed cache entries, so a cached response is read from disk and parsed only once
    private var parsed: [String: FetchedCatalog] = [:]

    /// Downloads in progress, so simultaneous callers share one request
    private var inFlight: [String: Task<FetchedCatalog, Error>] = [:]

    /// Queries whose last request failed, and when they may be tried again
    private var retryAfter: [String: Date] = [:]

    /// The earliest time the next request may be sent
    private var nextRequestTime = Date.distantPast

    // MARK: - Initialization

    /// Creates a client.
    ///
    /// - Parameters:
    ///   - endpoint: The server's GP query URL, without query parameters (for example
    ///     `https://example.org/elements/gp.php`). See `docs/catalogs.md` for a recommended
    ///     public endpoint. Must be `http` or `https`.
    ///   - appIdentifier: Your app's name and version, such as `"MyTracker/1.0"`. It goes in
    ///     the `User-Agent` header so the server's operator can see who is sending requests.
    ///   - cacheDirectory: Where to cache responses (default: a folder named after the
    ///     endpoint's host under `Ephemeris/ElementSets` in the user's Caches directory, so
    ///     two servers never share cached data or rate-limit pauses)
    ///   - refreshInterval: How old a cached copy may get before it is downloaded again.
    ///     Values below `minimumRefreshInterval` (two hours) are raised to it.
    ///   - gravity: Gravity model for the SGP4 propagators (default WGS-72, which TLEs and
    ///     OMMs are fitted with)
    ///   - transport: How requests are sent (default `URLSession.shared`)
    public init(
        endpoint: URL,
        appIdentifier: String,
        cacheDirectory: URL? = nil,
        refreshInterval: TimeInterval = ElementSetClient.minimumRefreshInterval,
        gravity: GravityModel = .wgs72,
        transport: any CatalogTransport = URLSessionTransport()
    ) {
        self.init(endpoint: endpoint, appIdentifier: appIdentifier, cacheDirectory: cacheDirectory,
                  refreshInterval: refreshInterval, gravity: gravity, transport: transport, time: .system)
    }

    /// Creates a client with a substitute clock (for tests).
    init(
        endpoint: URL,
        appIdentifier: String,
        cacheDirectory: URL?,
        refreshInterval: TimeInterval,
        gravity: GravityModel,
        transport: any CatalogTransport,
        time: TimeSource
    ) {
        let identifier = appIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        precondition(!identifier.isEmpty, "appIdentifier must name your app, for example \"MyTracker/1.0\"")

        let scheme = endpoint.scheme?.lowercased()
        precondition(scheme == "https" || scheme == "http", "endpoint must be an http or https URL")

        let directory = cacheDirectory ?? Self.defaultCacheDirectory(for: endpoint)
        self.endpoint = endpoint
        self.refreshInterval = max(refreshInterval, Self.minimumRefreshInterval)
        self.cacheDirectory = directory
        self.userAgent = "\(identifier) Ephemeris/2.0 (+https://github.com/mvdmakesthings/ephemeris)"
        self.gravity = gravity
        self.transport = transport
        self.time = time
        self.cache = CatalogCache(directory: directory)
    }

    /// `Ephemeris/ElementSets/<host>` in the user's Caches directory. The system may delete
    /// caches when storage runs low, which is fine: the data is downloaded again when needed.
    static func defaultCacheDirectory(for endpoint: URL) -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        // Host names are letters, digits, dots and hyphens; anything else becomes "_"
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-"))
        let host = (endpoint.host ?? "server").lowercased().unicodeScalars
            .map { allowed.contains($0) ? String($0) : "_" }.joined()
        return caches.appendingPathComponent("Ephemeris", isDirectory: true)
            .appendingPathComponent("ElementSets", isDirectory: true)
            .appendingPathComponent(host, isDirectory: true)
    }

    // MARK: - Fetching

    /// Returns the satellites for a query, from the cache when it is fresh enough and from
    /// the server otherwise.
    ///
    /// - Parameter query: What to fetch
    /// - Returns: The catalog, when it was downloaded, and whether it came from the network,
    ///   the cache, or an expired cache entry after a failed refresh
    /// - Throws: `CatalogFetchError` when the query is invalid, or when the download fails and
    ///   there is no cached copy at all
    ///
    /// ## Order of Checks
    /// 1. A cached copy of this exact query, younger than `refreshInterval`
    /// 2. For `.catalogNumber`, any fresh cached group that contains the satellite
    /// 3. A download of the same query already in progress, which this call joins
    /// 4. A new download, unless a rate-limit pause or a retry wait is in effect
    /// 5. If the download fails, the expired cached copy if there is one
    public func catalog(for query: ElementSetQuery) async throws -> FetchedCatalog {
        try query.validate()
        let key = query.cacheKey
        let now = time.now()

        // 1. This query's own cached copy
        if let cached = cachedEntry(forKey: key), cached.age(at: now) < refreshInterval {
            return cached.withSource(.cache)
        }

        // 2. A single satellite that is already in a cached group
        if case .catalogNumber(let number) = query, let fromGroup = freshGroupEntry(containing: number, at: now) {
            return fromGroup
        }

        // 3. Join a download that is already running
        if let running = inFlight[key] {
            return try await running.value
        }

        // 4 and 5. Download, falling back to the expired copy
        let download = Task { try await self.refresh(query, key: key) }
        inFlight[key] = download
        defer { inFlight[key] = nil }
        return try await download.value
    }

    /// Returns the cached copy of a query, however old, without ever going to the network.
    ///
    /// Useful at launch to show something immediately, then call `catalog(for:)` to refresh.
    ///
    /// - Throws: `CatalogFetchError.notCached` if the query has never been downloaded
    public func cachedCatalog(for query: ElementSetQuery) throws -> FetchedCatalog {
        try query.validate()
        guard let cached = cachedEntry(forKey: query.cacheKey) else {
            throw CatalogFetchError.notCached
        }
        return cached.withSource(.cache)
    }

    /// Deletes every cached response. The next call for each query downloads it again.
    ///
    /// A rate-limit pause from the server is kept, so clearing the cache can't be used to get
    /// around it.
    public func clearCache() throws {
        try cache.removeResponses()
        parsed.removeAll()
    }

    // MARK: - Cache Lookups

    /// The cached entry for a key, parsed once and then kept in memory.
    private func cachedEntry(forKey key: String) -> FetchedCatalog? {
        if let entry = parsed[key] {
            return entry
        }
        // An entry that can't be parsed (for example, written by a different version) is
        // treated as missing; the next download replaces it
        guard let stored = cache.entry(forKey: key),
              let catalog = try? ElementSetResponse.catalog(from: stored.body, gravity: gravity) else {
            return nil
        }
        let entry = FetchedCatalog(catalog: catalog, fetchedAt: stored.metadata.fetchedAt, source: .cache)
        parsed[key] = entry
        return entry
    }

    /// The newest fresh cached group containing a satellite, narrowed to that satellite.
    ///
    /// Only catalog numbers are answered this way: they identify exactly one satellite, so a
    /// group either has it or doesn't. A name or launch search could match satellites that
    /// are in no cached group, so those always use their own query.
    private func freshGroupEntry(containing catalogNumber: Int, at now: Date) -> FetchedCatalog? {
        let groups = cache.allKeys()
            .filter { $0.hasPrefix("group-") }
            .compactMap { cachedEntry(forKey: $0) }
            .filter { $0.age(at: now) < refreshInterval && $0.catalog[catalogNumber: catalogNumber] != nil }
        guard let newest = groups.max(by: { $0.fetchedAt < $1.fetchedAt }) else {
            return nil
        }
        return FetchedCatalog(catalog: newest.catalog.filter { $0.catalogNumber == catalogNumber },
                              fetchedAt: newest.fetchedAt, source: .cache)
    }

    // MARK: - Downloading

    /// Downloads a query, or falls back to its expired cached copy if that fails.
    private func refresh(_ query: ElementSetQuery, key: String) async throws -> FetchedCatalog {
        do {
            return try await download(query, key: key)
        } catch let error as CatalogFetchError {
            // A query the server calls invalid will never succeed, so report it even if an old
            // copy exists. Anything else (offline, server trouble, rate limit) is temporary.
            if case .invalidQuery = error {
                throw error
            }
            if let stale = cachedEntry(forKey: key) {
                return stale.withSource(.staleCache(error))
            }
            throw error
        }
    }

    /// Sends one request, subject to the pauses and pacing, and caches the result.
    private func download(_ query: ElementSetQuery, key: String) async throws -> FetchedCatalog {
        try checkPauses(forKey: key)

        // Pacing: reserve the next free slot before waiting, so callers that arrive while this
        // one sleeps line up behind it instead of all waking at the same moment
        let now = time.now()
        let sendTime = max(now, nextRequestTime)
        nextRequestTime = sendTime.addingTimeInterval(Self.minimumRequestSpacing)
        if sendTime > now {
            try await time.sleep(sendTime.timeIntervalSince(now))
            // A rate limit may have been reported by another request while this one waited
            try checkPauses(forKey: key)
        }

        let body: Data
        let response: HTTPURLResponse
        do {
            (body, response) = try await transport.send(try request(for: query))
        } catch let error as CatalogFetchError {
            recordFailure(forKey: key)
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            recordFailure(forKey: key)
            throw CatalogFetchError.transport(error.localizedDescription)
        }

        let receivedAt = time.now()
        switch response.statusCode {
        case 200:
            let catalog: SatelliteCatalog
            do {
                catalog = try ElementSetResponse.catalog(from: body, gravity: gravity)
            } catch {
                recordFailure(forKey: key)
                throw error
            }
            try? cache.store(body, forKey: key, fetchedAt: receivedAt)   // a full disk still returns the data
            let entry = FetchedCatalog(catalog: catalog, fetchedAt: receivedAt, source: .network)
            parsed[key] = entry
            retryAfter[key] = nil
            return entry

        case 403, 429:
            // The server says this client is sending too much. Stop everything, and remember it
            // across launches. Honor a longer Retry-After if the server sends one.
            let requested = response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init) ?? 0
            let until = receivedAt.addingTimeInterval(max(Self.rateLimitPause, requested))
            try? cache.recordRateLimit(until: until)
            throw CatalogFetchError.rateLimited(until: until)

        default:
            recordFailure(forKey: key)
            throw CatalogFetchError.httpStatus(response.statusCode)
        }
    }

    /// Throws if a rate-limit pause or this query's retry wait is still running.
    private func checkPauses(forKey key: String) throws {
        let now = time.now()
        if let until = cache.rateLimitedUntil(), until > now {
            throw CatalogFetchError.rateLimited(until: until)
        }
        if let until = retryAfter[key], until > now {
            throw CatalogFetchError.backingOff(until: until)
        }
    }

    /// Starts this query's retry wait after a failed request.
    private func recordFailure(forKey key: String) {
        retryAfter[key] = time.now().addingTimeInterval(Self.retryInterval)
    }

    /// The GP request for a query, always asking for OMM JSON. Any query parameters already
    /// on the endpoint (an API key, for example) are kept.
    nonisolated func request(for query: ElementSetQuery) throws -> URLRequest {
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw CatalogFetchError.invalidQuery("Could not read the endpoint \(endpoint)")
        }
        components.queryItems = (components.queryItems ?? []) + [query.queryItem, URLQueryItem(name: "FORMAT", value: "JSON")]
        guard let url = components.url else {
            throw CatalogFetchError.invalidQuery("Could not build a URL for \(query)")
        }

        var request = URLRequest(url: url, timeoutInterval: 60)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
