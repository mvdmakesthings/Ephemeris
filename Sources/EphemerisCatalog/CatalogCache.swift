//
//  CatalogCache.swift
//  EphemerisCatalog
//
//  Files on disk that remember every server response and when it was downloaded, so an
//  app can relaunch as often as it likes without downloading anything again.
//

import Foundation

/// A directory of cached element-set server responses.
///
/// Each query has two files:
/// - `<key>.body`: the response exactly as the server sent it (OMM JSON, or the plain-text
///   "No GP data found" answer, which is cached too so a missing satellite is not looked up
///   again and again)
/// - `<key>.meta.json`: when it was downloaded
///
/// One more file, `rate-limit.json`, remembers a rate-limit pause so it survives relaunches.
struct CatalogCache: Sendable {

    /// What is stored next to each response
    struct Metadata: Codable, Equatable {
        /// When the response was downloaded
        let fetchedAt: Date
    }

    /// A cached response and its metadata
    struct Entry {
        let body: Data
        let metadata: Metadata
    }

    /// The directory holding the cache files
    let directory: URL

    // MARK: - Responses

    /// Reads a cached response, or `nil` if there is none (or it can't be read).
    func entry(forKey key: String) -> Entry? {
        guard let metadataData = try? Data(contentsOf: metadataURL(forKey: key)),
              let metadata = try? JSONDecoder().decode(Metadata.self, from: metadataData),
              let body = try? Data(contentsOf: bodyURL(forKey: key)) else {
            return nil
        }
        return Entry(body: body, metadata: metadata)
    }

    /// Stores a response. The body is written before the metadata, so a crash in between
    /// leaves no metadata and the half-written entry is simply ignored.
    func store(_ body: Data, forKey key: String, fetchedAt: Date) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try body.write(to: bodyURL(forKey: key), options: .atomic)
        try JSONEncoder().encode(Metadata(fetchedAt: fetchedAt)).write(to: metadataURL(forKey: key), options: .atomic)
    }

    /// The keys of every cached response.
    func allKeys() -> [String] {
        let suffix = ".meta.json"
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return names.filter { $0.hasSuffix(suffix) }.map { String($0.dropLast(suffix.count)) }.sorted()
    }

    // MARK: - Rate Limit

    /// The end of a rate-limit pause, if one was recorded and hasn't been cleared.
    func rateLimitedUntil() -> Date? {
        guard let data = try? Data(contentsOf: rateLimitURL),
              let metadata = try? JSONDecoder().decode(Metadata.self, from: data) else {
            return nil
        }
        return metadata.fetchedAt
    }

    /// Records a rate-limit pause that lasts until `date`.
    func recordRateLimit(until date: Date) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(Metadata(fetchedAt: date)).write(to: rateLimitURL, options: .atomic)
    }

    // MARK: - Clearing

    /// Deletes every cached response. A recorded rate-limit pause is kept on purpose:
    /// clearing the cache must never become a way around it.
    func removeResponses() throws {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        for name in names where name.hasSuffix(".body") || name.hasSuffix(".meta.json") {
            try FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }
    }

    // MARK: - File Names

    private func bodyURL(forKey key: String) -> URL {
        directory.appendingPathComponent(key + ".body")
    }

    private func metadataURL(forKey key: String) -> URL {
        directory.appendingPathComponent(key + ".meta.json")
    }

    private var rateLimitURL: URL {
        directory.appendingPathComponent("rate-limit.json")
    }
}
