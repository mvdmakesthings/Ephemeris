//
//  OMMTests.swift
//  EphemerisTests
//
//  Orbit Mean-Elements Message parsing in all four encodings, and propagation from OMM.
//
//  The MARIO fixtures are one real element set in several formats. The XML and CSV are
//  CelesTrak's output as captured in python-sgp4's test suite; the JSON and KVN carry the
//  same values in CelesTrak's JSON layout and CCSDS KVN. The equivalent TLE is:
//    1 55123U 98067UQ  23115.44827133  .00787702  29408-3  15680-2 0  9999
//    2 55123  51.6242 216.2930 0014649 331.8976  28.1241 15.99081912 18396
//

import Foundation
import XCTest
@testable import Ephemeris

final class OMMTests: XCTestCase {

    // MARK: - Fixtures

    private let marioTLE = """
        MARIO
        1 55123U 98067UQ  23115.44827133  .00787702  29408-3  15680-2 0  9999
        2 55123  51.6242 216.2930 0014649 331.8976  28.1241 15.99081912 18396
        """

    private let marioXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ndm xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://sanaregistry.org/r/ndmxml_unqualified/ndmxml-2.0.0-master-2.0.xsd">
        <omm id="CCSDS_OMM_VERS" version="2.0">
        <header><CREATION_DATE/><ORIGINATOR/></header><body><segment><metadata><OBJECT_NAME>MARIO</OBJECT_NAME><OBJECT_ID>1998-067UQ</OBJECT_ID><CENTER_NAME>EARTH</CENTER_NAME><REF_FRAME>TEME</REF_FRAME><TIME_SYSTEM>UTC</TIME_SYSTEM><MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY></metadata><data><meanElements><EPOCH>2023-04-25T10:45:30.642912</EPOCH><MEAN_MOTION>15.99081912</MEAN_MOTION><ECCENTRICITY>.0014649</ECCENTRICITY><INCLINATION>51.6242</INCLINATION><RA_OF_ASC_NODE>216.2930</RA_OF_ASC_NODE><ARG_OF_PERICENTER>331.8976</ARG_OF_PERICENTER><MEAN_ANOMALY>28.1241</MEAN_ANOMALY></meanElements><tleParameters><EPHEMERIS_TYPE>0</EPHEMERIS_TYPE><CLASSIFICATION_TYPE>U</CLASSIFICATION_TYPE><NORAD_CAT_ID>55123</NORAD_CAT_ID><ELEMENT_SET_NO>999</ELEMENT_SET_NO><REV_AT_EPOCH>1839</REV_AT_EPOCH><BSTAR>.1568E-2</BSTAR><MEAN_MOTION_DOT>.787702E-2</MEAN_MOTION_DOT><MEAN_MOTION_DDOT>.29408E-3</MEAN_MOTION_DDOT></tleParameters></data></segment></body></omm>
        </ndm>
        """

    private let marioCSV = """
        OBJECT_NAME,OBJECT_ID,EPOCH,MEAN_MOTION,ECCENTRICITY,INCLINATION,RA_OF_ASC_NODE,ARG_OF_PERICENTER,MEAN_ANOMALY,EPHEMERIS_TYPE,CLASSIFICATION_TYPE,NORAD_CAT_ID,ELEMENT_SET_NO,REV_AT_EPOCH,BSTAR,MEAN_MOTION_DOT,MEAN_MOTION_DDOT
        MARIO,1998-067UQ,2023-04-25T10:45:30.642912,15.99081912,.0014649,51.6242,216.2930,331.8976,28.1241,0,U,55123,999,1839,.1568E-2,.787702E-2,.29408E-3
        """

    /// CelesTrak JSON layout: an array of objects with numbers as JSON numbers
    private let marioJSON = """
        [{"OBJECT_NAME":"MARIO","OBJECT_ID":"1998-067UQ","EPOCH":"2023-04-25T10:45:30.642912",
          "MEAN_MOTION":15.99081912,"ECCENTRICITY":0.0014649,"INCLINATION":51.6242,
          "RA_OF_ASC_NODE":216.293,"ARG_OF_PERICENTER":331.8976,"MEAN_ANOMALY":28.1241,
          "EPHEMERIS_TYPE":0,"CLASSIFICATION_TYPE":"U","NORAD_CAT_ID":55123,"ELEMENT_SET_NO":999,
          "REV_AT_EPOCH":1839,"BSTAR":0.001568,"MEAN_MOTION_DOT":0.00787702,"MEAN_MOTION_DDOT":0.00029408}]
        """

    /// CCSDS keyword = value notation, with a comment and unit annotations
    private let marioKVN = """
        CCSDS_OMM_VERS = 2.0
        COMMENT Generated for testing
        CREATION_DATE = 2023-04-25T12:00:00
        ORIGINATOR = 18 SPCS
        OBJECT_NAME = MARIO
        OBJECT_ID = 1998-067UQ
        CENTER_NAME = EARTH
        REF_FRAME = TEME
        TIME_SYSTEM = UTC
        MEAN_ELEMENT_THEORY = SGP4
        EPOCH = 2023-04-25T10:45:30.642912
        MEAN_MOTION = 15.99081912 [rev/day]
        ECCENTRICITY = 0.0014649
        INCLINATION = 51.6242 [deg]
        RA_OF_ASC_NODE = 216.2930 [deg]
        ARG_OF_PERICENTER = 331.8976 [deg]
        MEAN_ANOMALY = 28.1241 [deg]
        EPHEMERIS_TYPE = 0
        CLASSIFICATION_TYPE = U
        NORAD_CAT_ID = 55123
        ELEMENT_SET_NO = 999
        REV_AT_EPOCH = 1839
        BSTAR = 0.1568E-2 [1/ER]
        MEAN_MOTION_DOT = 0.787702E-2 [rev/day**2]
        MEAN_MOTION_DDOT = 0.29408E-3 [rev/day**3]
        """

    private func mario(_ format: OrbitMeanElementsMessage.Format? = nil, _ text: String) throws -> OrbitMeanElementsMessage {
        let messages = try OrbitMeanElementsMessage.parse(text, format: format)
        XCTAssertEqual(messages.count, 1)
        return try XCTUnwrap(messages.first)
    }

    // MARK: - Parsing

    func testParse_marioXML_shouldReadEveryField() throws {
        // Given/When
        let omm = try mario(.xml, marioXML)

        // Then
        XCTAssertEqual(omm.name, "MARIO")
        XCTAssertEqual(omm.internationalDesignator, "1998-067UQ")
        XCTAssertEqual(omm.centerName, "EARTH")
        XCTAssertEqual(omm.referenceFrame, "TEME")
        XCTAssertEqual(omm.timeSystem, "UTC")
        XCTAssertEqual(omm.meanElementTheory, "SGP4")
        XCTAssertEqual(omm.meanMotion, 15.99081912)
        XCTAssertEqual(omm.eccentricity, 0.0014649)
        XCTAssertEqual(omm.inclination, 51.6242)
        XCTAssertEqual(omm.rightAscensionOfAscendingNode, 216.2930)
        XCTAssertEqual(omm.argumentOfPerigee, 331.8976)
        XCTAssertEqual(omm.meanAnomaly, 28.1241)
        XCTAssertEqual(omm.ephemerisType, 0)
        XCTAssertEqual(omm.classification, "U")
        XCTAssertEqual(omm.catalogNumber, 55123)
        XCTAssertEqual(omm.elementSetNumber, 999)
        XCTAssertEqual(omm.revolutionNumberAtEpoch, 1839)
        XCTAssertEqual(omm.bstarDragTerm, 0.001568)
        XCTAssertEqual(omm.meanMotionFirstDerivative, 0.00787702)
        XCTAssertEqual(omm.meanMotionSecondDerivative, 0.00029408)
    }

    func testParse_allFourEncodings_shouldProduceIdenticalMessages() throws {
        // Given/When
        // KVN carries metadata the others imply; the parsed values must still be equal
        let xml = try mario(.xml, marioXML)
        let csv = try mario(.csv, marioCSV)
        let json = try mario(.json, marioJSON)
        let kvn = try mario(.kvn, marioKVN)

        // Then
        XCTAssertEqual(csv, xml)
        XCTAssertEqual(json, xml)
        XCTAssertEqual(kvn, xml)
    }

    func testParse_withoutFormat_shouldDetectEachEncoding() throws {
        // Given/When/Then
        XCTAssertEqual(OrbitMeanElementsMessage.detectFormat(marioXML), .xml)
        XCTAssertEqual(OrbitMeanElementsMessage.detectFormat(marioCSV), .csv)
        XCTAssertEqual(OrbitMeanElementsMessage.detectFormat(marioJSON), .json)
        XCTAssertEqual(OrbitMeanElementsMessage.detectFormat(marioKVN), .kvn)
        XCTAssertEqual(try mario(nil, marioJSON), try mario(.xml, marioXML))
    }

    func testParse_fromData_shouldMatchParseFromString() throws {
        // Given/When
        let fromData = try OrbitMeanElementsMessage.parse(Data(marioJSON.utf8))

        // Then
        XCTAssertEqual(fromData, [try mario(.json, marioJSON)])
    }

    func testParse_spaceTrackStyleJSON_withStringValuesAndExtraKeys_shouldParse() throws {
        // Given
        // Space-Track sends every value as a string and adds its own keys
        let json = """
            {"CCSDS_OMM_VERS":"2.0","COMMENT":"GENERATED VIA SPACE-TRACK.ORG API","OBJECT_NAME":"MARIO",
             "OBJECT_ID":"1998-067UQ","CENTER_NAME":"EARTH","REF_FRAME":"TEME","TIME_SYSTEM":"UTC",
             "MEAN_ELEMENT_THEORY":"SGP4","EPOCH":"2023-04-25T10:45:30.642912","MEAN_MOTION":"15.99081912",
             "ECCENTRICITY":"0.00146490","INCLINATION":"51.6242","RA_OF_ASC_NODE":"216.2930",
             "ARG_OF_PERICENTER":"331.8976","MEAN_ANOMALY":"28.1241","EPHEMERIS_TYPE":"0",
             "CLASSIFICATION_TYPE":"U","NORAD_CAT_ID":"55123","ELEMENT_SET_NO":"999","REV_AT_EPOCH":"1839",
             "BSTAR":"0.00156800000000","MEAN_MOTION_DOT":"0.00787702","MEAN_MOTION_DDOT":"0.0002940800000",
             "SEMIMAJOR_AXIS":"6736.433","DECAYED":"0","TLE_LINE0":"0 MARIO"}
            """

        // When
        let omm = try mario(nil, json)

        // Then
        XCTAssertEqual(omm, try mario(.xml, marioXML))
    }

    func testParse_multipleRecords_shouldReturnOnePerSatellite() throws {
        // Given
        let csv = marioCSV + "\nSECOND,2020-001A,2023-04-25T00:00:00.000000,15.5,.001,51.6,10,20,30,0,U,99001,1,2,.0001,0,0"
        let kvn = marioKVN + "\n" + marioKVN.replacingOccurrences(of: "NORAD_CAT_ID = 55123", with: "NORAD_CAT_ID = 99001")
        let json = "[" + marioJSON.dropFirst().dropLast() + "," + marioJSON.dropFirst().dropLast() + "]"

        // When/Then
        XCTAssertEqual(try OrbitMeanElementsMessage.parse(csv).map(\.catalogNumber), [55123, 99001])
        XCTAssertEqual(try OrbitMeanElementsMessage.parse(kvn).map(\.catalogNumber), [55123, 99001])
        XCTAssertEqual(try OrbitMeanElementsMessage.parse(json).count, 2)
    }

    // MARK: - Epoch

    func testEpoch_shouldMatchTLEEpochToTheMicrosecond() throws {
        // Given
        // TLE day 115.44827133 = 38730.642912 s after midnight, exactly the OMM epoch
        let tle = try TwoLineElement(from: marioTLE)

        // When
        let omm = try mario(.xml, marioXML)

        // Then
        XCTAssertEqual(omm.epoch.timeIntervalSince(tle.epoch), 0, accuracy: 1e-6)
    }

    func testParseEpoch_shouldAcceptCalendarDayOfYearAndZuluForms() throws {
        // Given
        let expected = try XCTUnwrap(OrbitMeanElementsMessage.parseEpoch("2023-04-25T10:45:30.642912"))

        // When/Then
        // April 25, 2023 is day 115
        XCTAssertEqual(OrbitMeanElementsMessage.parseEpoch("2023-115T10:45:30.642912"), expected)
        XCTAssertEqual(OrbitMeanElementsMessage.parseEpoch("2023-04-25T10:45:30.642912Z"), expected)
        XCTAssertEqual(try XCTUnwrap(OrbitMeanElementsMessage.parseEpoch("2024-03-01T00:00:00")),
                       try XCTUnwrap(ISO8601DateFormatter().date(from: "2024-03-01T00:00:00Z")))
        XCTAssertNil(OrbitMeanElementsMessage.parseEpoch("2023-13-01T00:00:00"))
        XCTAssertNil(OrbitMeanElementsMessage.parseEpoch("not a date"))
    }

    // MARK: - Propagation

    func testSGP4FromOMM_shouldMatchPythonSGP4() throws {
        // Given
        // python-sgp4 2.27: omm.initialize() on the MARIO XML, then sgp4_tsince()
        let sgp4 = try SGP4(elements: try mario(.xml, marioXML))
        let reference: [(minutes: Double, position: [Double])] = [
            (0, [-5357.6986727762815, -3934.6109046434312, -0.00239536765505865]),
            (720, [-5490.038306922299, -3742.6513290039406, 96.22012243244025]),
            (1440, [-5551.161829635572, -3633.5477705749504, 329.02730913708206])
        ]

        for expected in reference {
            // When
            let position = try sgp4.propagate(minutesSinceEpoch: expected.minutes).position

            // Then
            XCTAssertEqual(position.x, expected.position[0], accuracy: 1e-6, "t = \(expected.minutes)")
            XCTAssertEqual(position.y, expected.position[1], accuracy: 1e-6, "t = \(expected.minutes)")
            XCTAssertEqual(position.z, expected.position[2], accuracy: 1e-6, "t = \(expected.minutes)")
        }
    }

    func testSGP4FromOMM_shouldMatchSGP4FromEquivalentTLE() throws {
        // Given
        // Same satellite, same elements, two formats: positions must agree
        let fromOMM = try SGP4(elements: try mario(.json, marioJSON))
        let fromTLE = try SGP4(tle: try TwoLineElement(from: marioTLE))

        for minutes in stride(from: 0.0, through: 1440.0, by: 60.0) {
            // When
            let date = fromTLE.epoch.addingTimeInterval(minutes * 60)
            let difference = try fromOMM.stateVector(at: date).position - fromTLE.stateVector(at: date).position

            // Then
            XCTAssertLessThan(difference.magnitude, 1e-6, "t = \(minutes) min")
        }
    }

    func testSGP4FromOMM_shouldUseTheSameEpochAsPythonSGP4() throws {
        // Given
        // python-sgp4 passes the OMM epoch to sgp4init as the exact elapsed time since
        // 1949-12-31: 26778.44827133 days for MARIO. Going through a full Julian date
        // instead rounds it (to 26778.44827132998 here, and by up to ~2e-10 days in general).
        let omm = try mario(.xml, marioXML)

        // When
        let sgp4 = try SGP4(elements: omm)

        // Then
        XCTAssertEqual(sgp4.elements.epochDaysSince1950, 26778.44827133, accuracy: 5e-12)
    }

    func testOMM_withSixDigitCatalogNumber_shouldPropagate() throws {
        // Given
        // Catalog numbers past 339999 cannot be written in a TLE at all, even with Alpha-5
        let json = marioJSON.replacingOccurrences(of: "\"NORAD_CAT_ID\":55123", with: "\"NORAD_CAT_ID\":412345")

        // When
        let omm = try mario(.json, json)
        let sgp4 = try SGP4(elements: omm)

        // Then
        XCTAssertEqual(omm.catalogNumber, 412345)
        XCTAssertNoThrow(try sgp4.propagate(minutesSinceEpoch: 90))
    }

    func testSGP4_withSGP4XPElements_shouldRefuseToPropagate() throws {
        // Given
        let byTheory = marioKVN.replacingOccurrences(of: "MEAN_ELEMENT_THEORY = SGP4", with: "MEAN_ELEMENT_THEORY = SGP4-XP")
        let byType = marioJSON.replacingOccurrences(of: "\"EPHEMERIS_TYPE\":0", with: "\"EPHEMERIS_TYPE\":4")

        for text in [byTheory, byType] {
            // When
            let omm = try mario(nil, text)

            // Then
            XCTAssertEqual(omm.ephemerisType, 4)
            XCTAssertThrowsError(try SGP4(elements: omm)) { error in
                XCTAssertEqual(error as? SGP4Error, .unsupportedEphemerisType(4))
            }
        }
    }

    func testKeplerianOrbit_fromOMM_shouldUseSameElements() throws {
        // Given/When
        let omm = try mario(.csv, marioCSV)
        let orbit = KeplerianOrbit(elements: omm)

        // Then
        XCTAssertEqual(orbit.inclination, omm.inclination)
        XCTAssertEqual(orbit.meanMotion, omm.meanMotion)
        XCTAssertEqual(orbit.epoch, omm.epoch)
    }

    // MARK: - Errors

    func testParse_withMissingEpoch_shouldThrowMissingField() {
        // Given
        let json = marioJSON.replacingOccurrences(of: "\"EPOCH\":\"2023-04-25T10:45:30.642912\",", with: "")

        // When/Then
        XCTAssertThrowsError(try OrbitMeanElementsMessage.parse(json)) { error in
            XCTAssertEqual(error as? OMMParsingError, .missingField("EPOCH"))
        }
    }

    func testParse_withNonTEMEFrame_shouldThrowUnsupported() {
        // Given
        let kvn = marioKVN.replacingOccurrences(of: "REF_FRAME = TEME", with: "REF_FRAME = GCRF")

        // When/Then
        XCTAssertThrowsError(try OrbitMeanElementsMessage.parse(kvn)) { error in
            XCTAssertEqual(error as? OMMParsingError, .unsupported(field: "REF_FRAME", value: "GCRF"))
        }
    }

    func testParse_withUnreadableNumber_shouldThrowInvalidValue() {
        // Given
        let csv = marioCSV.replacingOccurrences(of: ",51.6242,", with: ",fifty,")

        // When/Then
        XCTAssertThrowsError(try OrbitMeanElementsMessage.parse(csv)) { error in
            XCTAssertEqual(error as? OMMParsingError, .invalidValue(field: "INCLINATION", value: "fifty"))
        }
    }

    func testParse_withEmptyOrMalformedDocuments_shouldThrowInvalidFormat() {
        // Given/When/Then
        for text in ["", "[]", "<ndm><omm></omm></ndm>", "{ not json", "OBJECT_NAME,EPOCH\nONLY_ONE_FIELD"] {
            XCTAssertThrowsError(try OrbitMeanElementsMessage.parse(text), "\(text)") { error in
                guard case .invalidFormat = error as? OMMParsingError else {
                    XCTFail("Expected invalidFormat for \(text), got \(error)")
                    return
                }
            }
        }
    }

    // MARK: - TLE Parity

    func testTwoLineElement_shouldExposeTheSameIdentificationFieldsAsOMM() throws {
        // Given/When
        let tle = try TwoLineElement(from: marioTLE)
        let omm = try mario(.xml, marioXML)

        // Then
        XCTAssertEqual(tle.catalogNumber, omm.catalogNumber)
        XCTAssertEqual(tle.classification, omm.classification)
        XCTAssertEqual(tle.ephemerisType, omm.ephemerisType)
        XCTAssertEqual(tle.elementSetNumber, omm.elementSetNumber)
        XCTAssertEqual(tle.bstarDragTerm, omm.bstarDragTerm, accuracy: 1e-15)
        XCTAssertEqual(tle.meanMotionSecondDerivative, omm.meanMotionSecondDerivative, accuracy: 1e-15)
    }
}
