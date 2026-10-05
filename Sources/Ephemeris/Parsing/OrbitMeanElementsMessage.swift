//
//  OrbitMeanElementsMessage.swift
//  Ephemeris
//
//  CCSDS Orbit Mean-Elements Message (OMM): the modern format for SGP4 element sets.
//

import Foundation

/// Errors that can occur while parsing an Orbit Mean-Elements Message.
public enum OMMParsingError: Error, Equatable, Sendable {
    /// The text is not valid JSON, XML, KVN or CSV, or has no OMM records
    case invalidFormat(String)
    /// A required keyword is missing from a record
    case missingField(String)
    /// A keyword's value cannot be read
    case invalidValue(field: String, value: String)
    /// The message describes something this library cannot propagate (another central
    /// body, reference frame, time system or mean element theory)
    case unsupported(field: String, value: String)
}

extension OMMParsingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let message):
            return "Invalid OMM: \(message)"
        case .missingField(let field):
            return "Invalid OMM: missing required field \(field)"
        case .invalidValue(let field, let value):
            return "Invalid OMM: field \(field) has unreadable value '\(value)'"
        case .unsupported(let field, let value):
            return "Unsupported OMM: \(field) = \(value)"
        }
    }
}

/// A CCSDS Orbit Mean-Elements Message (OMM): the modern, standardized way to publish
/// the same SGP4 elements a TLE carries.
///
/// ## Why OMM?
/// The TLE format dates from the punched-card era and packs everything into fixed columns.
/// That causes real problems now:
/// - **Catalog numbers run out.** A TLE has room for 5 characters. Plain digits stop at
///   99999, and the Alpha-5 workaround (`A0001` = 100001) only reaches 339999. OMM stores the
///   number as a normal integer.
/// - **Two-digit years.** TLE years 57-99 mean 1957-1999 and 00-56 mean 2000-2056; the scheme
///   breaks in 2057. OMM uses a full ISO 8601 date.
/// - **Precision.** A TLE epoch resolves about 1 ms; an OMM epoch carries microseconds.
/// - **Self-description.** A TLE assumes its frame (TEME), time system (UTC) and model
///   (SGP4). An OMM names them, along with the producer and creation date.
///
/// OMM is defined by CCSDS 502.0-B ("Orbit Data Messages"), the international standard
/// space agencies use to exchange orbit data. The public catalogs publish every satellite in
/// it, and it is the recommended format for new software.
///
/// ## Same Data, Different Encodings
/// An OMM is a set of named keywords. The standard allows several encodings, and this type
/// reads all of them:
/// - **JSON**: the most popular format from public GP servers (an array of objects)
/// - **XML**: the CCSDS NDM/XML schema
/// - **KVN**: CCSDS "keyword = value" text
/// - **CSV**: one header row of keywords, one row per satellite
///
/// ```json
/// { "OBJECT_NAME": "ISS (ZARYA)", "OBJECT_ID": "1998-067A", "EPOCH": "2020-04-06T19:53:20.932800",
///   "MEAN_MOTION": 15.48685836, "ECCENTRICITY": 0.000388, "INCLINATION": 51.6465,
///   "RA_OF_ASC_NODE": 341.5807, "ARG_OF_PERICENTER": 94.4223, "MEAN_ANOMALY": 26.1197,
///   "EPHEMERIS_TYPE": 0, "CLASSIFICATION_TYPE": "U", "NORAD_CAT_ID": 25544,
///   "ELEMENT_SET_NO": 999, "REV_AT_EPOCH": 22095, "BSTAR": 2.4271e-5,
///   "MEAN_MOTION_DOT": 8.74e-6, "MEAN_MOTION_DDOT": 0 }
/// ```
///
/// ## Usage
/// ```swift
/// let messages = try OrbitMeanElementsMessage.parse(jsonData)   // format detected
/// let iss = messages[0]
/// let sgp4 = try SGP4(elements: iss)
/// ```
///
/// - Note: References: CCSDS 502.0-B-3, "Orbit Data Messages"; CelesTrak,
///         "GP Data Formats" (https://celestrak.org/NORAD/documentation/gp-data-formats.php)
public struct OrbitMeanElementsMessage: MeanElementSet, Hashable, Codable, Sendable {

    // MARK: - Metadata

    /// Common name of the object (`OBJECT_NAME`)
    public let name: String

    /// International designator in COSPAR form, e.g. "1998-067A" (`OBJECT_ID`)
    public let internationalDesignator: String

    /// Body the orbit is around (`CENTER_NAME`), always "EARTH" here
    public let centerName: String

    /// Reference frame of the elements (`REF_FRAME`), always "TEME" for SGP4
    public let referenceFrame: String

    /// Time system of the epoch (`TIME_SYSTEM`), always "UTC" for SGP4
    public let timeSystem: String

    /// Theory the mean elements belong to (`MEAN_ELEMENT_THEORY`): "SGP4" or "SGP4-XP"
    public let meanElementTheory: String

    // MARK: - Mean Elements

    /// The instant the elements describe, UTC (`EPOCH`)
    public let epoch: Date

    /// Mean motion in revolutions per day (`MEAN_MOTION`)
    public let meanMotion: Double

    /// Eccentricity (`ECCENTRICITY`)
    public let eccentricity: Double

    /// Inclination in degrees (`INCLINATION`)
    public let inclination: Degrees

    /// Right ascension of the ascending node in degrees (`RA_OF_ASC_NODE`)
    public let rightAscensionOfAscendingNode: Degrees

    /// Argument of perigee in degrees (`ARG_OF_PERICENTER`)
    public let argumentOfPerigee: Degrees

    /// Mean anomaly at epoch in degrees (`MEAN_ANOMALY`)
    public let meanAnomaly: Degrees

    // MARK: - TLE-Compatible Parameters

    /// Theory the elements were fitted with: 0 for standard SGP4/SDP4, 4 for SGP4-XP
    /// (`EPHEMERIS_TYPE`)
    public let ephemerisType: Int

    /// Security classification, "U" for unclassified (`CLASSIFICATION_TYPE`)
    public let classification: String

    /// NORAD satellite catalog number, with no 5-digit limit (`NORAD_CAT_ID`)
    public let catalogNumber: Int

    /// Running count of element sets published for this object (`ELEMENT_SET_NO`)
    public let elementSetNumber: Int

    /// Number of complete orbits at epoch (`REV_AT_EPOCH`)
    public let revolutionNumberAtEpoch: Int

    /// B* drag term in 1 / Earth radii (`BSTAR`)
    public let bstarDragTerm: Double

    /// First derivative of mean motion divided by two, rev/day², same value as the TLE
    /// field (`MEAN_MOTION_DOT`). Not used by SGP4.
    public let meanMotionFirstDerivative: Double

    /// Second derivative of mean motion divided by six, rev/day³, same value as the TLE
    /// field (`MEAN_MOTION_DDOT`). Not used by SGP4.
    public let meanMotionSecondDerivative: Double

    // MARK: - Initialization

    /// Builds a message from its keywords and values, as read from any encoding.
    ///
    /// Keywords are the CCSDS names (`EPOCH`, `MEAN_MOTION`, ...). Metadata that is absent
    /// takes the values SGP4 element sets always use (EARTH, TEME, UTC, SGP4), as in
    /// JSON and CSV from public GP servers, which omit them.
    ///
    /// - Parameter fields: Keyword → value text
    /// - Throws: `OMMParsingError` if a required keyword is missing or unreadable, or the
    ///           metadata describes an orbit SGP4 cannot use
    public init(fields: [String: String]) throws {
        let record = FieldReader(fields: fields)

        // Metadata: check that this is an Earth orbit in TEME/UTC from an SGP4-family fit
        self.name = record.text("OBJECT_NAME") ?? ""
        self.internationalDesignator = record.text("OBJECT_ID") ?? ""
        self.centerName = try record.expect("CENTER_NAME", default: "EARTH", allowed: ["EARTH"])
        self.referenceFrame = try record.expect("REF_FRAME", default: "TEME", allowed: ["TEME"])
        self.timeSystem = try record.expect("TIME_SYSTEM", default: "UTC", allowed: ["UTC"])
        self.meanElementTheory = try record.expect("MEAN_ELEMENT_THEORY", default: "SGP4",
                                                   allowed: ["SGP4", "SGP4-XP"])

        // Mean elements
        let epochText = try record.required("EPOCH")
        guard let epoch = Self.parseEpoch(epochText) else {
            throw OMMParsingError.invalidValue(field: "EPOCH", value: epochText)
        }
        self.epoch = epoch
        self.meanMotion = try record.number("MEAN_MOTION")
        self.eccentricity = try record.number("ECCENTRICITY")
        self.inclination = try record.number("INCLINATION")
        self.rightAscensionOfAscendingNode = try record.number("RA_OF_ASC_NODE")
        self.argumentOfPerigee = try record.number("ARG_OF_PERICENTER")
        self.meanAnomaly = try record.number("MEAN_ANOMALY")
        guard (0..<1).contains(eccentricity) else {
            throw OMMParsingError.invalidValue(field: "ECCENTRICITY", value: String(eccentricity))
        }

        // TLE-compatible parameters. Only the catalog number and B* are essential.
        self.catalogNumber = try record.integer("NORAD_CAT_ID")
        self.bstarDragTerm = try record.number("BSTAR")
        // SGP4-XP elements must be marked as ephemeris type 4 so SGP4 can refuse them
        let declaredType = try record.integer("EPHEMERIS_TYPE", default: 0)
        self.ephemerisType = meanElementTheory == "SGP4-XP" ? 4 : declaredType
        self.classification = record.text("CLASSIFICATION_TYPE") ?? "U"
        self.elementSetNumber = try record.integer("ELEMENT_SET_NO", default: 0)
        self.revolutionNumberAtEpoch = try record.integer("REV_AT_EPOCH", default: 0)
        self.meanMotionFirstDerivative = try record.number("MEAN_MOTION_DOT", default: 0)
        self.meanMotionSecondDerivative = try record.number("MEAN_MOTION_DDOT", default: 0)
    }
}

// MARK: - Epoch Parsing

extension OrbitMeanElementsMessage {
    /// Parses a CCSDS epoch: `YYYY-MM-DDThh:mm:ss[.fff…][Z]` or the day-of-year form
    /// `YYYY-DDDThh:mm:ss[.fff…][Z]`.
    ///
    /// Done by hand rather than with `ISO8601DateFormatter`, which keeps only milliseconds
    /// and does not accept the day-of-year form. The arithmetic is exact to the microsecond.
    ///
    /// - Parameter text: The epoch text
    /// - Returns: The epoch as a `Date`, or `nil` if the text is not a valid epoch
    static func parseEpoch(_ text: String) -> Date? {
        var value = text.trimmingCharacters(in: .whitespaces)
        if value.hasSuffix("Z") {
            value.removeLast()
        }
        let parts = value.split(separator: "T", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }

        // Date part: year-month-day or year-dayOfYear
        let dateFields = parts[0].split(separator: "-").map { Int($0) }
        guard dateFields.allSatisfy({ $0 != nil }) else { return nil }
        let numbers = dateFields.compactMap { $0 }
        let year: Int
        let dayOfYear: Int
        switch numbers.count {
        case 3:
            year = numbers[0]
            guard (1...12).contains(numbers[1]), (1...31).contains(numbers[2]) else { return nil }
            dayOfYear = Self.dayOfYear(year: year, month: numbers[1], day: numbers[2])
        case 2:
            year = numbers[0]
            dayOfYear = numbers[1]
            guard (1...366).contains(dayOfYear) else { return nil }
        default:
            return nil
        }

        // Time part: hh:mm:ss with optional fractional seconds
        let timeFields = parts[1].split(separator: ":")
        guard timeFields.count == 3,
              let hour = Int(timeFields[0]), (0...23).contains(hour),
              let minute = Int(timeFields[1]), (0...59).contains(minute),
              let second = Double(timeFields[2]), (0..<61).contains(second) else {
            return nil
        }

        // TwoLineElement.date counts whole days from 1970 exactly, then adds the fraction
        let secondsIntoDay = Double(hour) * 3600 + Double(minute) * 60 + second
        let midnight = TwoLineElement.date(year: year, dayOfYear: Double(dayOfYear))
        return midnight.addingTimeInterval(secondsIntoDay)
    }

    /// Day of the year (1 = January 1) for a Gregorian date.
    private static func dayOfYear(year: Int, month: Int, day: Int) -> Int {
        let isLeapYear = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
        let daysBeforeMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
        return daysBeforeMonth[month - 1] + day + (isLeapYear && month > 2 ? 1 : 0)
    }
}

// MARK: - Field Reading

extension OrbitMeanElementsMessage {
    /// Reads typed values from an OMM record's keyword → text dictionary.
    private struct FieldReader {
        let fields: [String: String]

        /// The trimmed text for a keyword, or `nil` if absent or empty. Trailing unit
        /// annotations allowed in KVN, such as `15.49 [rev/day]`, are removed.
        func text(_ key: String) -> String? {
            guard var value = fields[key]?.trimmingCharacters(in: .whitespaces) else { return nil }
            if let bracket = value.firstIndex(of: "[") {
                value = String(value[..<bracket]).trimmingCharacters(in: .whitespaces)
            }
            return value.isEmpty ? nil : value
        }

        func required(_ key: String) throws -> String {
            guard let value = text(key) else { throw OMMParsingError.missingField(key) }
            return value
        }

        /// A decimal number. Accepts forms like ".0014649", "2.4271e-5" and ".1568E-2".
        func number(_ key: String, default defaultValue: Double? = nil) throws -> Double {
            guard let value = text(key) else {
                if let defaultValue { return defaultValue }
                throw OMMParsingError.missingField(key)
            }
            guard let number = Double(value) else {
                throw OMMParsingError.invalidValue(field: key, value: value)
            }
            return number
        }

        func integer(_ key: String, default defaultValue: Int? = nil) throws -> Int {
            guard let value = text(key) else {
                if let defaultValue { return defaultValue }
                throw OMMParsingError.missingField(key)
            }
            guard let number = Int(value) else {
                throw OMMParsingError.invalidValue(field: key, value: value)
            }
            return number
        }

        /// A metadata keyword that must have one of a few values (case-insensitive).
        func expect(_ key: String, default defaultValue: String, allowed: Set<String>) throws -> String {
            let value = (text(key) ?? defaultValue).uppercased()
            guard allowed.contains(value) else {
                throw OMMParsingError.unsupported(field: key, value: value)
            }
            return value
        }
    }
}
