//
//  main.swift
//  EphemerisTests
//
//  Test runner for Spectre tests
//

import Spectre
@testable import Ephemeris

// Register all test suites
describe("DoubleExtension", doubleExtensionTests)
describe("Date", dateTests)
describe("PhysicalConstants", physicalConstantsTests)
describe("TwoLineElement", twoLineElementTests)
describe("OrbitalElements", orbitalElementsTests)
describe("OrbitalCalculation", orbitalCalculationTests)
describe("Observer", observerTests)
describe("GroundTrackSkyTrack", groundTrackSkyTrackTests)
