# Changelog

All notable changes to Ephemeris will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet

## [1.0.0] - 2020-04-26

First stable release of Ephemeris, a Swift framework for satellite tracking and orbital mechanics.

### Added
- **TLE Parsing and Validation**
  - NORAD Two-Line Element (TLE) format parser
  - Checksum validation
  - Comprehensive error handling with detailed error messages
  - Support for 2-digit year interpretation with ±50 year window

- **Keplerian Orbital Mechanics**
  - Conversion from TLE to Keplerian orbital elements
  - Semi-major axis, eccentricity, inclination calculations
  - Right Ascension of Ascending Node (RAAN)
  - Argument of perigee
  - Mean anomaly and true anomaly
  - Iterative Kepler's equation solver using Newton-Raphson method

- **Position Calculations**
  - ECI (Earth-Centered Inertial) coordinate calculations
  - ECEF (Earth-Centered Earth-Fixed) transformations
  - Geodetic position (latitude, longitude, altitude)
  - Time-based position propagation

- **Observer-Relative Tracking**
  - Topocentric coordinate calculations (azimuth, elevation, range)
  - Range rate calculations (approaching/receding satellites)
  - ENU (East-North-Up) local coordinate system
  - Atmospheric refraction correction for low-elevation observations

- **Pass Prediction**
  - Satellite pass prediction for ground observers
  - Acquisition of Signal (AOS) time and azimuth
  - Maximum elevation time and position
  - Loss of Signal (LOS) time and azimuth
  - Pass duration calculation
  - Configurable minimum elevation threshold
  - Bisection and golden-section search algorithms

- **Coordinate System Transformations**
  - ECI ↔ ECEF transformations
  - ECEF ↔ Geodetic transformations
  - ENU ↔ Horizontal (Az/El) transformations
  - WGS-84 geodetic standard implementation

- **Time Systems**
  - Julian Day calculations
  - Greenwich Mean Sidereal Time (GMST)
  - J2000 epoch support
  - TLE epoch conversion

- **Visualization Support**
  - Ground track generation
  - Sky track visualization data
  - SwiftUI and MapKit integration examples

- **Utilities and Extensions**
  - Degree/radian conversions
  - Angle normalization utilities
  - Physical constants (WGS-84 Earth parameters, gravitational constants)
  - Vector mathematics (3D vectors, dot products, magnitudes)

- **Documentation**
  - Comprehensive README with examples
  - Detailed orbital mechanics guides
  - API reference documentation
  - Mathematical foundations documentation
  - Academic paper references

- **Testing**
  - Initial test suite using Spectre BDD framework
  - Unit tests for TLE parsing
  - Orbital calculation validation tests
  - Coordinate transformation tests

- **Platform Support**
  - iOS 13.0+
  - macOS 10.15+
  - Swift 5.0+

### Changed (2025 Modernization)
- **Migrated to XCTest** from Spectre BDD framework (October 2025)
  - Converted all 122 tests to XCTest format
  - Adopted standard `swift test` command
  - Improved IDE integration and tooling support
  - Used descriptive test naming: `test[Feature]_[Scenario]_[ExpectedBehavior]`

- **Adopted Standard SPM Structure** (October 2025)
  - Moved source files from `Ephemeris/` to `Sources/Ephemeris/`
  - Moved test files from `EphemerisTests/` to `Tests/EphemerisTests/`
  - Removed custom path parameters from Package.swift

- **Removed Distribution Blockers** (October 2025)
  - Removed unsafe compiler flags
  - Eliminated external test dependency (Spectre)
  - Changed from `.executableTarget` to `.testTarget` for tests
  - Package now distributable via Swift Package Manager

- **Expanded Platform Support** (October 2025)
  - Added watchOS 9.0+ support
  - Added tvOS 16.0+ support
  - Added visionOS 1.0+ support
  - Updated minimum versions: iOS 16.0+, macOS 13.0+
  - Adopted "current minus two" platform support policy

- **Updated Build Tools** (October 2025)
  - Upgraded to Swift 6.0 tools
  - Maintained Swift 5 language compatibility
  - Updated GitHub Actions CI workflow

- **Enhanced Documentation** (October 2025)
  - Added CLAUDE.md for AI tool integration
  - Added architecture review document
  - Enhanced coordinate system diagrams
  - Improved time systems documentation
  - Added LLM.txt for AI-assisted development

### Fixed
- TLE checksum validation edge cases
- Coordinate transformation precision issues
- Julian date calculation accuracy

### Known Limitations
- Uses simplified two-body Keplerian mechanics (not SGP4/SDP4)
- Best accuracy within 1-3 days of TLE epoch
- Does not model atmospheric drag
- Does not model solar radiation pressure
- Does not include gravitational perturbations
- Designed for educational and hobbyist satellite tracking

### Technical Details
- **Architecture**: Protocol-oriented design with `Orbitable` protocol
- **Type System**: Immutable value types (structs) for thread safety
- **Error Handling**: Comprehensive error types with context
- **Dependencies**: None (pure Swift, Foundation only)
- **License**: Apache License 2.0

[Unreleased]: https://github.com/mvdmakesthings/Ephemeris/compare/1.0.0...HEAD
[1.0.0]: https://github.com/mvdmakesthings/Ephemeris/releases/tag/1.0.0
