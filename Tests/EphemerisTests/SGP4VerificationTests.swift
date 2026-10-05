//
//  SGP4VerificationTests.swift
//  EphemerisTests
//
//  Verifies the SGP4/SDP4 port against Vallado's published test vectors.
//
//  Resources/SGP4-VER.TLE lists 33 element sets chosen to exercise every branch of
//  the algorithm (near-Earth, simplified drag, deep space, 12-hour and 24-hour
//  resonance, Lyddane low-inclination fix, decay and error paths). Each line 2 is
//  followed by a start, stop and step time in minutes. Resources/tcppver.out is the
//  output of Vallado's reference C++ implementation for those inputs.
//
//  Source: Vallado, Crawford, Hujsak, Kelso, "Revisiting Spacetrack Report #3",
//  AIAA 2006-6753, companion files (as distributed with python-sgp4, MIT license).
//

import Foundation
import XCTest
@testable import Ephemeris

final class SGP4VerificationTests: XCTestCase {

    // MARK: - Types

    /// One satellite's block in tcppver.out: its catalog number and data lines.
    private struct ExpectedBlock {
        let catalogNumber: Int
        var lines: [[Double]]
    }

    /// One satellite from SGP4-VER.TLE with its requested time span.
    private struct VerificationCase {
        let line1: String
        let line2: String
        let start: Double
        let stop: Double
        let step: Double
    }

    // MARK: - Tolerances

    /// tcppver.out prints positions to 1e-8 km and velocities to 1e-9 km/s. The port
    /// should agree to a few units in that last place; 1e-6 km is 1 millimeter.
    private let positionToleranceKm = 1e-6
    private let velocityToleranceKmPerSec = 1e-9

    // MARK: - Helpers

    private func loadResource(_ name: String, _ ext: String) throws -> String {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Resources"))
        return try String(contentsOf: url, encoding: .ascii).replacingOccurrences(of: "\r", with: "")
    }

    private func loadCases() throws -> [VerificationCase] {
        let lines = try loadResource("SGP4-VER", "TLE").components(separatedBy: "\n")
        var cases: [VerificationCase] = []
        var index = 0
        while index < lines.count {
            let line = lines[index]
            if line.hasPrefix("1 ") && index + 1 < lines.count {
                let line2 = lines[index + 1]
                let times = line2.dropFirst(69).split(separator: " ").compactMap { Double($0) }
                XCTAssertEqual(times.count, 3, "Missing start/stop/step on: \(line2)")
                cases.append(VerificationCase(
                    line1: String(line.prefix(69)),
                    line2: String(line2.prefix(69)),
                    start: times[0], stop: times[1], step: times[2]
                ))
                index += 2
            } else {
                index += 1
            }
        }
        return cases
    }

    private func loadExpected() throws -> [ExpectedBlock] {
        var blocks: [ExpectedBlock] = []
        for line in try loadResource("tcppver", "out").components(separatedBy: "\n") where !line.isEmpty {
            let fields = line.split(separator: " ")
            if fields.count == 2 && fields[1] == "xx" {
                blocks.append(ExpectedBlock(catalogNumber: try XCTUnwrap(Int(fields[0])), lines: []))
            } else {
                // First seven fields: tsince, position xyz, velocity xyz
                let values = fields.prefix(7).compactMap { Double($0) }
                XCTAssertEqual(values.count, 7, "Unparseable reference line: \(line)")
                blocks[blocks.count - 1].lines.append(values)
            }
        }
        return blocks
    }

    /// The propagation times the reference harness uses for one case.
    private func times(for testCase: VerificationCase) -> [Double] {
        var result: [Double] = [0.0]
        var tsince = testCase.start
        while tsince <= testCase.stop {
            if !(tsince == testCase.start && tsince == 0.0) {
                result.append(tsince)
            }
            tsince += testCase.step
        }
        // Do not miss the final requested time
        if tsince - testCase.stop < testCase.step - 1e-6 {
            result.append(testCase.stop)
        }
        return result
    }

    // MARK: - Verification

    func testSGP4_againstValladoVerificationVectors_shouldMatchReferenceOutput() throws {
        // Given
        let cases = try loadCases()
        let expected = try loadExpected()
        XCTAssertEqual(cases.count, expected.count, "Every verification TLE should have a reference block")

        var errorCodes: [Int] = []
        var comparedPoints = 0
        var maxPositionError = 0.0
        var maxVelocityError = 0.0

        for (testCase, block) in zip(cases, expected) {
            // TLE parsing is not under test here. Satellites 33333-33335 have deliberately
            // wrong checksums (they test SGP4's error paths), so repair them before parsing.
            let line1 = MockTLEs.fixChecksum(for: testCase.line1)
            let line2 = MockTLEs.fixChecksum(for: testCase.line2)
            let tle = try TwoLineElement(from: "\(line1)\n\(line2)")
            XCTAssertEqual(tle.catalogNumber, block.catalogNumber)

            // When
            let sgp4: SGP4
            do {
                sgp4 = try SGP4(tle: tle)
            } catch let error as SGP4Error {
                // Fails at epoch: the reference prints a single placeholder line
                errorCodes.append(error.code)
                XCTAssertEqual(block.lines.count, 1, "Satellite \(block.catalogNumber)")
                continue
            }

            var produced = 0
            for tsince in times(for: testCase) {
                let state: StateVector
                do {
                    state = try sgp4.propagate(minutesSinceEpoch: tsince)
                } catch let error as SGP4Error {
                    errorCodes.append(error.code)
                    break
                }

                // Then
                guard produced < block.lines.count else {
                    XCTFail("Satellite \(block.catalogNumber) produced more points than the reference")
                    break
                }
                let reference = block.lines[produced]
                XCTAssertEqual(tsince, reference[0], accuracy: 1e-8)

                let actual = [state.position.x, state.position.y, state.position.z,
                              state.velocity.x, state.velocity.y, state.velocity.z]
                for axis in 0..<3 {
                    let positionError = abs(actual[axis] - reference[axis + 1])
                    let velocityError = abs(actual[axis + 3] - reference[axis + 4])
                    maxPositionError = max(maxPositionError, positionError)
                    maxVelocityError = max(maxVelocityError, velocityError)
                    XCTAssertLessThan(positionError, positionToleranceKm,
                                      "Satellite \(block.catalogNumber) position at t=\(tsince)")
                    XCTAssertLessThan(velocityError, velocityToleranceKmPerSec,
                                      "Satellite \(block.catalogNumber) velocity at t=\(tsince)")
                }
                produced += 1
                comparedPoints += 1
            }
            XCTAssertEqual(produced, block.lines.count, "Satellite \(block.catalogNumber) point count")
        }

        // The reference run reports exactly these errors, in this order
        XCTAssertEqual(errorCodes, [1, 1, 6, 6, 4, 3, 6])
        print("SGP4 verification: \(comparedPoints) points, max position error \(maxPositionError) km, "
              + "max velocity error \(maxVelocityError) km/s")
    }
}
