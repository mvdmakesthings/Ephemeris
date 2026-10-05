//
//  OrbitMeanElementsMessage+Formats.swift
//  Ephemeris
//
//  Readers for the four OMM encodings: JSON, XML, KVN and CSV. Each one reduces its
//  text to records of CCSDS keyword → value, which `OrbitMeanElementsMessage(fields:)`
//  then turns into typed elements.
//

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

extension OrbitMeanElementsMessage {

    /// The text encodings an OMM can arrive in.
    public enum Format: String, CaseIterable, Sendable {
        /// JSON array (or single object) of keyword → value, as served by CelesTrak and Space-Track
        case json
        /// CCSDS NDM/XML
        case xml
        /// CCSDS keyword = value notation
        case kvn
        /// Comma-separated values with a header row of keywords
        case csv
    }

    // MARK: - Parsing

    /// Parses every OMM record in a document.
    ///
    /// - Parameters:
    ///   - data: The document, UTF-8 encoded
    ///   - format: The encoding, or `nil` to detect it from the content
    /// - Returns: One message per satellite, in document order
    /// - Throws: `OMMParsingError` if the document cannot be read or a record is invalid
    ///
    /// ## Example
    /// ```swift
    /// let (data, _) = try await URLSession.shared.data(from: celestrakURL)  // FORMAT=JSON
    /// let satellites = try OrbitMeanElementsMessage.parse(data)
    /// ```
    public static func parse(_ data: Data, format: Format? = nil) throws -> [OrbitMeanElementsMessage] {
        guard let text = String(data: data, encoding: .utf8) else {
            throw OMMParsingError.invalidFormat("document is not UTF-8 text")
        }
        return try parse(text, format: format)
    }

    /// Parses every OMM record in a document.
    ///
    /// - Parameters:
    ///   - text: The document
    ///   - format: The encoding, or `nil` to detect it from the content
    /// - Returns: One message per satellite, in document order
    /// - Throws: `OMMParsingError` if the document cannot be read or a record is invalid
    public static func parse(_ text: String, format: Format? = nil) throws -> [OrbitMeanElementsMessage] {
        return try records(in: text, format: format).map { try OrbitMeanElementsMessage(fields: $0) }
    }

    /// Parses each OMM record in a document independently, so one invalid record does not
    /// stop the rest. Use this for large catalogs.
    ///
    /// - Parameters:
    ///   - text: The document
    ///   - format: The encoding, or `nil` to detect it from the content
    /// - Returns: One result per record, in document order
    /// - Throws: `OMMParsingError` only if the document as a whole cannot be read
    public static func parseEach(_ text: String, format: Format? = nil) throws
        -> [Result<OrbitMeanElementsMessage, OMMParsingError>] {
        return try records(in: text, format: format).map { fields in
            Result { try OrbitMeanElementsMessage(fields: fields) }.mapError { error in
                error as? OMMParsingError ?? .invalidFormat(error.localizedDescription)
            }
        }
    }

    /// Splits a document into keyword → value records using the right reader.
    private static func records(in text: String, format: Format?) throws -> [[String: String]] {
        let records: [[String: String]]
        switch format ?? detectFormat(text) {
        case .json: records = try jsonRecords(text)
        case .xml: records = try xmlRecords(text)
        case .kvn: records = kvnRecords(text)
        case .csv: records = try csvRecords(text)
        }
        guard !records.isEmpty else {
            throw OMMParsingError.invalidFormat("no OMM records found")
        }
        return records
    }

    /// Guesses the encoding from the first meaningful characters of the document.
    static func detectFormat(_ text: String) -> Format {
        let trimmed = text.drop { $0.isWhitespace || $0 == "\u{FEFF}" }
        switch trimmed.first {
        case "[", "{": return .json
        case "<": return .xml
        default:
            // KVN lines look like "KEYWORD = value"; CSV starts with a header row of keywords
            let firstLine = trimmed.prefix { !$0.isNewline }
            return firstLine.contains("=") ? .kvn : .csv
        }
    }
}

// MARK: - JSON

extension OrbitMeanElementsMessage {
    /// A JSON scalar decoded without losing the original number's exact value.
    private enum JSONScalar: Decodable {
        case text(String)
        case none

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .none
            } else if let string = try? container.decode(String.self) {
                self = .text(string)
            } else if let integer = try? container.decode(Int.self) {
                self = .text(String(integer))
            } else if let number = try? container.decode(Double.self) {
                // Swift prints the shortest text that reads back as the same Double
                self = .text(String(number))
            } else {
                // Nested objects or booleans are not OMM keywords; ignore them
                self = .none
            }
        }

        var string: String? {
            if case .text(let value) = self { return value }
            return nil
        }
    }

    /// CelesTrak sends numbers as JSON numbers; Space-Track sends every value as a string.
    /// Both are accepted, as an array of records or a single record.
    private static func jsonRecords(_ text: String) throws -> [[String: String]] {
        let data = Data(text.utf8)
        let decoder = JSONDecoder()
        let objects: [[String: JSONScalar]]
        if let array = try? decoder.decode([[String: JSONScalar]].self, from: data) {
            objects = array
        } else if let single = try? decoder.decode([String: JSONScalar].self, from: data) {
            objects = [single]
        } else {
            throw OMMParsingError.invalidFormat("not a JSON object or array of objects")
        }
        return objects.map { object in object.compactMapValues(\.string) }
    }
}

// MARK: - XML

extension OrbitMeanElementsMessage {
    /// Collects the text of every leaf element in each `<segment>` (one per satellite).
    ///
    /// The CCSDS layout is `ndm › omm › body › segment › {metadata, data › {meanElements,
    /// tleParameters}}`, and every value sits in a leaf element named after its keyword,
    /// so the nesting can be flattened.
    private final class XMLRecordCollector: NSObject, XMLParserDelegate {
        var records: [[String: String]] = []
        private var current: [String: String]?
        private var text = ""

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            if localName(elementName) == "segment" {
                current = [:]
            }
            text = ""
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            text += string
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?) {
            let name = localName(elementName)
            if name == "segment", let record = current {
                records.append(record)
                current = nil
            } else if current != nil {
                let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    current?[name] = value
                }
            }
            text = ""
        }

        /// Drops any namespace prefix, e.g. "ndm:EPOCH" → "EPOCH"
        private func localName(_ name: String) -> String {
            return name.split(separator: ":").last.map(String.init) ?? name
        }
    }

    private static func xmlRecords(_ text: String) throws -> [[String: String]] {
        let parser = XMLParser(data: Data(text.utf8))
        let collector = XMLRecordCollector()
        parser.delegate = collector
        guard parser.parse() else {
            throw OMMParsingError.invalidFormat("XML could not be parsed: \(parser.parserError?.localizedDescription ?? "unknown error")")
        }
        return collector.records
    }
}

// MARK: - KVN

extension OrbitMeanElementsMessage {
    /// Reads "KEYWORD = value" lines. Each `CCSDS_OMM_VERS` line starts a new message;
    /// `COMMENT` lines are skipped.
    private static func kvnRecords(_ text: String) -> [[String: String]] {
        var records: [[String: String]] = []
        var current: [String: String] = [:]

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("COMMENT"),
                  let equals = trimmed.firstIndex(of: "=") else {
                continue
            }
            let key = trimmed[..<equals].trimmingCharacters(in: .whitespaces)
            let value = trimmed[trimmed.index(after: equals)...].trimmingCharacters(in: .whitespaces)

            if key == "CCSDS_OMM_VERS" && !current.isEmpty {
                records.append(current)
                current = [:]
            }
            current[key] = value
        }
        if !current.isEmpty {
            records.append(current)
        }
        return records
    }
}

// MARK: - CSV

extension OrbitMeanElementsMessage {
    /// Reads a header row of keywords followed by one row per satellite.
    private static func csvRecords(_ text: String) throws -> [[String: String]] {
        let rows = text
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map(splitCSVRow)
        guard let header = rows.first?.map({ $0.trimmingCharacters(in: .whitespaces) }) else {
            return []
        }
        return try rows.dropFirst().enumerated().map { index, row in
            guard row.count == header.count else {
                throw OMMParsingError.invalidFormat("CSV row \(index + 2) has \(row.count) fields, header has \(header.count)")
            }
            return Dictionary(uniqueKeysWithValues: zip(header, row))
        }
    }

    /// Splits one CSV row, honoring double-quoted fields (which may contain commas and
    /// doubled "" quotes).
    private static func splitCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var field = ""
        var inQuotes = false
        var characters = row.makeIterator()
        while let character = characters.next() {
            switch character {
            case "\"" where inQuotes:
                // A doubled quote inside quotes is a literal quote
                if let next = characters.next() {
                    if next == "\"" {
                        field.append("\"")
                    } else {
                        inQuotes = false
                        if next == "," {
                            fields.append(field)
                            field = ""
                        } else {
                            field.append(next)
                        }
                    }
                } else {
                    inQuotes = false
                }
            case "\"":
                inQuotes = true
            case "," where !inQuotes:
                fields.append(field)
                field = ""
            default:
                field.append(character)
            }
        }
        fields.append(field)
        return fields
    }
}
