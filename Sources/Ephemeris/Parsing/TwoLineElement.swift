//
//  TwoLineElement.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/6/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// Errors that can occur while parsing a Two-Line Element set.
public enum TLEParsingError: Error, Equatable, Sendable {
    /// The text is not laid out like a TLE (wrong prefix, too short, non-ASCII, ...)
    case invalidFormat(String)
    /// A field does not contain a valid number
    case invalidNumber(field: String, value: String)
    /// The text does not contain two data lines (optionally preceded by a name line)
    case missingLine(expected: Int, actual: Int)
    /// A line's modulo-10 checksum does not match its last digit
    case invalidChecksum(line: Int, expected: Int, actual: Int)
    /// Eccentricity is outside the range 0 ≤ e < 1
    case invalidEccentricity(value: Double)
}

extension TLEParsingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let message):
            return "Invalid TLE format: \(message)"
        case .invalidNumber(let field, let value):
            return "Invalid number in field '\(field)': '\(value)' is not a valid number"
        case .missingLine(let expected, let actual):
            return "Invalid TLE: expected \(expected) lines but got \(actual)"
        case .invalidChecksum(let line, let expected, let actual):
            return "Invalid checksum for line \(line): expected \(expected) but got \(actual)"
        case .invalidEccentricity(let value):
            return "Invalid eccentricity: \(value) must be less than 1.0"
        }
    }
}

/// A NORAD Two-Line Element set: the standard published orbit for a satellite.
///
/// TLEs are mean elements fitted with the SGP4 model, so propagate them with `SGP4`.
/// They are most accurate near their epoch; refresh them every day or two for tracking.
///
/// ## TLE Format
/// Two fixed-width 69-character data lines, usually preceded by a name line:
/// ```
/// ISS (ZARYA)
/// 1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
/// 2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
/// ```
///
/// | Line | Columns | Field                                              |
/// |------|---------|----------------------------------------------------|
/// | 1    | 3-7     | Catalog number (Alpha-5 allowed)                   |
/// | 1    | 8       | Classification (U = unclassified)                  |
/// | 1    | 10-17   | International designator                           |
/// | 1    | 19-32   | Epoch: 2-digit year, day of year with fraction     |
/// | 1    | 34-43   | First derivative of mean motion ÷ 2                |
/// | 1    | 45-52   | Second derivative of mean motion ÷ 6 (exponential) |
/// | 1    | 54-61   | B* drag term (exponential)                         |
/// | 1    | 63      | Ephemeris type (0 = SGP4)                          |
/// | 1    | 65-68   | Element set number                                 |
/// | 1, 2 | 69      | Modulo-10 checksum                                 |
/// | 2    | 9-16    | Inclination (°)                                    |
/// | 2    | 18-25   | Right ascension of the ascending node (°)          |
/// | 2    | 27-33   | Eccentricity (assumed leading decimal point)       |
/// | 2    | 35-42   | Argument of perigee (°)                            |
/// | 2    | 44-51   | Mean anomaly (°)                                   |
/// | 2    | 53-63   | Mean motion (revolutions per day)                  |
/// | 2    | 64-68   | Revolution number at epoch                         |
///
/// ## Usage
/// ```swift
/// let tle = try TwoLineElement(from: tleString)
/// print("\(tle.name) #\(tle.catalogNumber), epoch \(tle.epoch)")
/// let sgp4 = try SGP4(tle: tle)
/// ```
///
/// ## TLE or OMM?
/// A TLE and an OMM (`OrbitMeanElementsMessage`) carry the same SGP4 elements. TLEs are
/// compact and universal, but their 5-character catalog field cannot hold numbers above
/// 339999 even with Alpha-5, and their 2-digit years end in 2056. Prefer OMM for new data.
///
/// ## Where to Get TLE Data
/// - [CelesTrak](https://celestrak.org/NORAD/elements/)
/// - [Space-Track.org](https://www.space-track.org/) (requires registration)
///
/// - Note: Reference: https://celestrak.org/columns/v04n03/
public struct TwoLineElement: MeanElementSet, Hashable, Codable, Sendable {

    // MARK: - Identification

    /// Common name of the object, or an empty string for a bare two-line set
    public let name: String

    /// NORAD satellite catalog number (Alpha-5 numbers are decoded, e.g. `A0001` → 100001)
    public let catalogNumber: Int

    /// International designator: launch year, launch number and piece (e.g. "98067A")
    public let internationalDesignator: String

    /// Security classification: "U" (unclassified), "C" or "S"
    public let classification: String

    /// Running count of element sets published for this object (wraps at 9999)
    public let elementSetNumber: Int

    // MARK: - Epoch

    /// The instant the elements describe (UTC)
    public let epoch: Date

    /// Four-digit epoch year (SGP4 reproduces the reference epoch arithmetic from it)
    let epochYear: Int

    /// Epoch day of year with fraction, where 1.0 is January 1 at 00:00 UTC
    let epochDayOfYear: Double

    // MARK: - Drag Terms

    /// First derivative of mean motion divided by two, as printed in the TLE (rev/day²).
    /// Not used by SGP4.
    public let meanMotionFirstDerivative: Double

    /// Second derivative of mean motion divided by six, as printed in the TLE (rev/day³).
    /// Not used by SGP4.
    public let meanMotionSecondDerivative: Double

    /// B* drag term (1 / Earth radii). SGP4's measure of atmospheric drag.
    public let bstarDragTerm: Double

    /// Theory the elements were fitted with: 0 for standard SGP4/SDP4, 4 for SGP4-XP
    public let ephemerisType: Int

    // MARK: - Orbital Elements

    /// Inclination of the orbital plane to the equator (degrees, 0-180)
    public let inclination: Degrees

    /// Right ascension of the ascending node (degrees, 0-360)
    public let rightAscensionOfAscendingNode: Degrees

    /// Eccentricity (0 ≤ e < 1)
    public let eccentricity: Double

    /// Argument of perigee (degrees, 0-360)
    public let argumentOfPerigee: Degrees

    /// Mean anomaly at epoch (degrees, 0-360)
    public let meanAnomaly: Degrees

    /// Mean motion (revolutions per day)
    public let meanMotion: Double

    /// Number of complete orbits at epoch
    public let revolutionNumberAtEpoch: Int

    // MARK: - Initialization

    /// Parses a NORAD TLE.
    ///
    /// Both the three-line form (name + two data lines) and the bare two-line form are
    /// accepted. Text copied from files or web pages works as-is: `\n`, `\r\n` and `\r`
    /// line endings, blank lines and trailing whitespace are all handled, and the `0 `
    /// prefix Space-Track puts on name lines is removed.
    ///
    /// - Parameter tle: Two or three lines of TLE text
    /// - Throws: `TLEParsingError` if the text is malformed, a checksum fails, the two data
    ///           lines describe different objects, or a value is out of range
    ///
    /// ## Validation Performed
    /// - Data lines start with `1 ` and `2 ` and are at least 69 ASCII characters
    /// - Both checksums match
    /// - Both lines carry the same catalog number
    /// - Every numeric field parses and eccentricity is below 1
    ///
    /// - Note: Two-digit epoch years follow the NORAD convention: 57-99 map to 1957-1999
    ///         and 00-56 map to 2000-2056.
    public init(from tle: String) throws {
        let lines = tle
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let nameLine: String
        let dataLines: [String]
        if lines.count == 3 {
            nameLine = lines[0].hasPrefix("0 ") ? String(lines[0].dropFirst(2)) : lines[0]
            dataLines = [lines[1], lines[2]]
        } else if lines.count == 2 && lines[0].hasPrefix("1 ") {
            nameLine = ""
            dataLines = lines
        } else {
            throw TLEParsingError.missingLine(expected: 3, actual: lines.count)
        }

        let line1 = try DataLine(dataLines[0], number: 1)
        let line2 = try DataLine(dataLines[1], number: 2)

        self.name = String(nameLine.prefix(24)).trimmingCharacters(in: .whitespaces)

        // ---------------------------- Line 1 ----------------------------
        let catalogField = line1.text(3...7)
        guard let catalogNumber = Self.parseCatalogNumber(catalogField) else {
            throw TLEParsingError.invalidNumber(field: "catalogNumber", value: catalogField)
        }
        guard Self.parseCatalogNumber(line2.text(3...7)) == catalogNumber else {
            throw TLEParsingError.invalidFormat(
                "Catalog number on line 2 (\(line2.text(3...7))) does not match line 1 (\(catalogField))"
            )
        }
        self.catalogNumber = catalogNumber
        self.classification = line1.text(8...8)
        self.internationalDesignator = line1.text(10...17)

        self.epochYear = Self.parse2DigitYear(try line1.integer(19...20, field: "epochYear"))
        self.epochDayOfYear = try line1.decimal(21...32, field: "epochDayOfYear")
        self.epoch = Self.date(year: epochYear, dayOfYear: epochDayOfYear)

        self.meanMotionFirstDerivative = try line1.decimal(34...43, field: "meanMotionFirstDerivative")
        self.meanMotionSecondDerivative = try line1.exponential(45...52, field: "meanMotionSecondDerivative")
        self.bstarDragTerm = try line1.exponential(54...61, field: "bstarDragTerm")
        self.ephemerisType = try line1.integer(63...63, field: "ephemerisType")
        self.elementSetNumber = try line1.integer(65...68, field: "elementSetNumber")

        // ---------------------------- Line 2 ----------------------------
        self.inclination = try line2.decimal(9...16, field: "inclination")
        self.rightAscensionOfAscendingNode = try line2.decimal(18...25, field: "rightAscensionOfAscendingNode")
        self.eccentricity = try line2.assumedDecimal(27...33, field: "eccentricity")
        guard eccentricity < 1.0 else {
            throw TLEParsingError.invalidEccentricity(value: eccentricity)
        }
        self.argumentOfPerigee = try line2.decimal(35...42, field: "argumentOfPerigee")
        self.meanAnomaly = try line2.decimal(44...51, field: "meanAnomaly")
        self.meanMotion = try line2.decimal(53...63, field: "meanMotion")
        self.revolutionNumberAtEpoch = try line2.integer(64...68, field: "revolutionNumberAtEpoch")
    }
}

// MARK: - Field Conventions

extension TwoLineElement {
    /// Converts a 2-digit TLE epoch year to a 4-digit year.
    ///
    /// Uses the fixed NORAD convention, so the same TLE always parses to the same epoch:
    /// - 57-99 → 1957-1999 (no satellites existed before Sputnik 1 in 1957)
    /// - 00-56 → 2000-2056
    ///
    /// - Parameter twoDigitYear: A 2-digit year value (00-99)
    /// - Returns: A 4-digit year value
    static func parse2DigitYear(_ twoDigitYear: Int) -> Int {
        return twoDigitYear < 57 ? 2000 + twoDigitYear : 1900 + twoDigitYear
    }

    /// Parses a 5-character catalog number, including the Alpha-5 format.
    ///
    /// Alpha-5 extends the catalog beyond 99999 by replacing the first digit with a letter.
    /// Letters I and O are skipped to avoid confusion with 1 and 0: A=10, …, H=17, J=18, …,
    /// N=22, P=23, …, Z=33. So `A0001` → 100001 and `Z9999` → 339999.
    ///
    /// - Parameter string: The catalog number field, trimmed
    /// - Returns: The numeric catalog number, or `nil` if the field is invalid
    static func parseCatalogNumber(_ string: String) -> Int? {
        guard let first = string.first else { return nil }
        let isDigit: (Character) -> Bool = { $0.isASCII && $0.isNumber }

        if isDigit(first) {
            return string.allSatisfy(isDigit) ? Int(string) : nil
        }

        let alpha5Letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
        let digits = string.dropFirst()
        guard string.count == 5,
              let letterIndex = alpha5Letters.firstIndex(of: first),
              digits.allSatisfy(isDigit),
              let remainder = Int(digits) else {
            return nil
        }
        return (10 + letterIndex) * 10000 + remainder
    }

    /// Converts a year and fractional day of year (1.0 = January 1, 00:00 UTC) to a `Date`.
    static func date(year: Int, dayOfYear: Double) -> Date {
        // Days from 1970-01-01 to January 1 of `year` (Howard Hinnant's days_from_civil
        // with month = 1, day = 1, which counts from the previous March)
        let y = year - 1
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + 306
        let daysToJanuary1 = era * 146097 + doe - 719468
        return Date(timeIntervalSince1970: (Double(daysToJanuary1) + dayOfYear - 1.0) * PhysicalConstants.Time.secondsPerDay)
    }
}

// MARK: - Data Line Parsing

extension TwoLineElement {
    /// One validated TLE data line, read by the 1-based column numbers of the format table.
    private struct DataLine {
        let bytes: [UInt8]
        let number: Int

        /// Validates the prefix, length, character set and checksum of a data line.
        init(_ line: String, number: Int) throws {
            guard line.hasPrefix("\(number) ") else {
                throw TLEParsingError.invalidFormat("Line \(number) must start with '\(number) '")
            }
            guard line.allSatisfy(\.isASCII) else {
                throw TLEParsingError.invalidFormat("Line \(number) contains non-ASCII characters")
            }
            self.bytes = Array(line.utf8)
            self.number = number
            guard bytes.count >= 69 else {
                throw TLEParsingError.invalidFormat("Line \(number) is too short (expected at least 69 characters)")
            }

            // Checksum: sum of all digits in columns 1-68, with each minus sign counting
            // as 1, modulo 10, must equal the digit in column 69
            guard let expected = Self.digitValue(bytes[68]) else {
                throw TLEParsingError.invalidFormat("Line \(number) checksum character is not a digit")
            }
            let sum = bytes[0..<68].reduce(0) { total, byte in
                if let digit = Self.digitValue(byte) { return total + digit }
                return byte == UInt8(ascii: "-") ? total + 1 : total
            }
            guard sum % 10 == expected else {
                throw TLEParsingError.invalidChecksum(line: number, expected: expected, actual: sum % 10)
            }
        }

        /// The trimmed text in the given 1-based, inclusive column range.
        func text(_ columns: ClosedRange<Int>) -> String {
            let slice = bytes[(columns.lowerBound - 1)...(columns.upperBound - 1)]
            // Lines are validated as ASCII on creation, so decoding cannot fail
            return (String(bytes: slice, encoding: .ascii) ?? "").trimmingCharacters(in: .whitespaces)
        }

        /// A plain decimal number, e.g. " 51.6465" or "-.00000084".
        func decimal(_ columns: ClosedRange<Int>, field: String) throws -> Double {
            let value = text(columns)
            guard let number = Double(value) else {
                throw TLEParsingError.invalidNumber(field: field, value: value)
            }
            return number
        }

        /// An integer; a blank field reads as 0.
        func integer(_ columns: ClosedRange<Int>, field: String) throws -> Int {
            let value = text(columns)
            if value.isEmpty { return 0 }
            guard let number = Int(value) else {
                throw TLEParsingError.invalidNumber(field: field, value: value)
            }
            return number
        }

        /// Digits with an assumed leading decimal point, e.g. "0003880" → 0.000388.
        func assumedDecimal(_ columns: ClosedRange<Int>, field: String) throws -> Double {
            let value = text(columns)
            guard !value.isEmpty, value.allSatisfy({ $0.isASCII && $0.isNumber }),
                  let number = Double("0." + value) else {
                throw TLEParsingError.invalidNumber(field: field, value: value)
            }
            return number
        }

        /// TLE exponential notation with an assumed leading decimal point:
        /// "±MMMMM±E" means ±0.MMMMM × 10^±E, e.g. " 24271-4" → 0.000024271.
        func exponential(_ columns: ClosedRange<Int>, field: String) throws -> Double {
            let value = text(columns)
            if value.isEmpty { return 0 }
            guard value.count >= 3 else {
                throw TLEParsingError.invalidNumber(field: field, value: value)
            }
            var mantissa = String(value.dropLast(2))
            let exponent = String(value.suffix(2))
            var sign = 1.0
            if mantissa.hasPrefix("-") {
                sign = -1.0
                mantissa.removeFirst()
            } else if mantissa.hasPrefix("+") {
                mantissa.removeFirst()
            }
            guard mantissa.allSatisfy({ $0.isASCII && $0.isNumber }),
                  let mantissaValue = Double("0." + mantissa),
                  let exponentValue = Int(exponent) else {
                throw TLEParsingError.invalidNumber(field: field, value: value)
            }
            return sign * mantissaValue * pow(10.0, Double(exponentValue))
        }

        private static func digitValue(_ byte: UInt8) -> Int? {
            guard byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9") else { return nil }
            return Int(byte - UInt8(ascii: "0"))
        }
    }
}
