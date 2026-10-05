//
//  CelesTrakResponse.swift
//  EphemerisCatalog
//
//  Turning a CelesTrak response body into a catalog.
//

import Foundation
import Ephemeris

/// Reads the body of a `gp.php` response.
enum CelesTrakResponse {

    /// Builds a catalog from a response body.
    ///
    /// CelesTrak answers a JSON request in one of three ways:
    /// - A JSON array of OMM records: the normal case
    /// - The plain text `No GP data found`: the query was valid but matched nothing (for
    ///   example a catalog number that has decayed). This becomes an empty catalog.
    /// - Plain text such as `Invalid query`: the request itself was wrong
    ///
    /// - Throws: `CelesTrakError.invalidQuery` or `.invalidResponse`
    static func catalog(from body: Data, gravity: GravityModel) throws -> SatelliteCatalog {
        guard let text = String(bytes: body, encoding: .utf8) else {
            throw CelesTrakError.invalidResponse("The response is not UTF-8 text")
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("[") {
            // An empty array also means "nothing matched"
            if trimmed.filter({ !$0.isWhitespace }) == "[]" {
                return SatelliteCatalog(elementSets: [])
            }
            do {
                return try SatelliteCatalog(omm: trimmed, format: .json, gravity: gravity)
            } catch {
                throw CelesTrakError.invalidResponse("Could not read OMM JSON: \(error)")
            }
        }

        let lowercased = trimmed.lowercased()
        if lowercased.contains("no gp data found") {
            return SatelliteCatalog(elementSets: [])
        }
        if lowercased.contains("invalid query") {
            throw CelesTrakError.invalidQuery(String(trimmed.prefix(200)))
        }
        throw CelesTrakError.invalidResponse(String(trimmed.prefix(200)))
    }
}
