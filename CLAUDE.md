# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ephemeris is a Swift framework for satellite tracking and orbital mechanics calculations. It provides tools to parse Two-Line Element (TLE) data and calculate orbital positions for Earth-orbiting satellites. The framework is dual-purpose: both a practical Swift library for iOS/macOS developers and an educational tool for learning orbital mechanics.

**Key Philosophy**: Pure Swift implementation from first principles using peer-reviewed academic papers. Code is optimized for readability and learning, not maximum performance.

## Development Commands

### Building and Testing

```bash
# Build the framework
swift build

# Run tests (uses XCTest)
swift test

# Build in release mode
swift build -c release

# Run SwiftLint
swiftlint lint

# Run SwiftLint with strict mode (as in CI)
swiftlint lint --strict
```

### Important Testing Notes

- This project uses **XCTest** (Apple's standard testing framework)
- Tests run via `swift test` (standard SPM command)
- Tests are defined as a `.testTarget` in Package.swift
- Test structure uses descriptive test method names following the pattern: `test[Feature]_[Scenario]_[ExpectedBehavior]`
- Tests use Given-When-Then comments for clarity
- Assertions use `XCTAssert*` methods (e.g., `XCTAssertEqual`, `XCTAssertTrue`)

## Architecture Overview

### Core Design Patterns

**Propagator protocol**: `SGP4` and `KeplerianOrbit` conform to `Propagator`, which only requires `stateVector(at:)`. Position, look angles, pass prediction, ground tracks and sky tracks are written once as `extension Propagator` methods, so every propagator gets them.

**Immutable value types**: All public types are structs or enums with `let` properties, and are `Sendable` (plus `Hashable` and `Codable` where it makes sense). This keeps whole-catalog propagation safe under Swift concurrency.

**Caseless enums as namespaces**: `CoordinateTransforms` and `PhysicalConstants` are `enum`s with static members.

### Directory Structure

```
Sources/Ephemeris/
├── Coordinates/
│   ├── CoordinateTransforms.swift   # Geodetic ↔ ECEF, ECI → ECEF, ECEF → ENU → az/el, refraction
│   ├── GeodeticPosition.swift       # WGS-84 latitude, longitude, altitude
│   └── Vector3D.swift
├── Observation/
│   ├── Observer.swift               # Ground station location
│   └── Topocentric.swift            # Look angles + Propagator.topocentric
├── Parsing/
│   └── TwoLineElement.swift         # TLE parser (byte/column based)
├── Propagation/
│   ├── Propagator.swift             # Protocol, StateVector, calculatePosition
│   ├── KeplerianOrbit.swift         # Two-body propagator (teaching)
│   ├── KeplerianOrbit+KeplersEquation.swift
│   ├── GravityModel.swift           # WGS-72 / WGS-84 constants for SGP4
│   ├── SGP4.swift                   # Public SGP4 type and the sgp4 propagation step
│   ├── SGP4+Initialization.swift    # sgp4init, initl, reference epoch conversion
│   ├── SGP4+DeepSpace.swift         # dscom, dpper (lunar-solar periodics)
│   └── SGP4+Resonance.swift         # dsinit, dspace (12h/24h resonance)
├── Time/
│   └── Date+AstronomicalTime.swift  # Julian date, GMST
├── Tracking/
│   ├── GroundTrack.swift            # GroundTrackPoint + Propagator.groundTrack
│   ├── SkyTrack.swift               # SkyTrackPoint + Propagator.skyTrack
│   └── PassPrediction.swift         # PassWindow + Propagator.predictPasses
└── Utilities/
    ├── PhysicalConstants.swift      # WGS-84 constants with sources
    ├── TypeAliases.swift            # Degrees, Radians, JulianDate
    └── Double+Angles.swift          # inRadians(), inDegrees()
```

## Important Implementation Details

### Propagators: SGP4 and Two-Body

- **`SGP4`** (`Propagation/SGP4*.swift`): A port of Vallado's `sgp4unit.cpp`. It is the correct model for TLE data and the default for real tracking.
  - Internal variable names deliberately match the reference so code can be checked line by line. Do not rename them.
  - Keep operation order identical to the reference. `SGP4VerificationTests` compares against `tcppver.out` at a 1 mm tolerance, and the current max error is 0.12 mm.
  - The TLE epoch is converted with the reference `days2mdhms` + `jday` arithmetic on purpose (see `referenceJulianDate`).
  - The deep-space integrator restarts from epoch on every call instead of caching state, so `SGP4` stays a pure, `Sendable` value type.
  - Output frame is TEME. Rotating by GMST gives Earth-fixed coordinates.
  - SGP4 velocity agrees with the derivative of its position to about 2 cm/s; this is a property of the model, not a bug.
- **`KeplerianOrbit`**: Two-body Keplerian motion, kept for teaching. It ignores J2 and drag, so it is not suitable for tracking.

### Coordinate Systems and Transformations

- **ECI / TEME**: Inertial, where propagators produce positions
- **ECEF**: Rotates with the Earth (ECI rotated by −GMST about z)
- **Geodetic**: WGS-84 latitude, longitude, height above the ellipsoid (never geocentric)
- **ENU**: Local tangent plane at the observer, giving azimuth/elevation/range

Pipeline: state vector (TEME/ECI) → ECEF via GMST → geodetic, or → ENU → look angles.

### Time Systems

- `Date.julianDate` is computed from the Unix timestamp (no calendar lookup)
- GMST uses the IAU-82 polynomial; the instance property measures time in seconds from J2000 for sub-microsecond precision
- UTC is used in place of UT1 (up to 0.9 s, about 0.4 km at the equator)
- TLE 2-digit years use the NORAD 1957 pivot

## Code Style and Conventions

### Naming Conventions

- **Orbital elements**: full names (`semimajorAxis`, `eccentricity`, `inclination`, `rightAscensionOfAscendingNode`, `argumentOfPerigee`, `meanAnomaly`), except inside the SGP4 port
- **Units in names**: public properties carry a unit suffix when the unit is not obvious: `latitudeDeg`, `altitudeKm`, `altitudeMeters`, `rangeKm`, `rangeRateKmPerSec`
- **Type aliases**: `Degrees`, `Radians`, `JulianDate` document units but are plain `Double`s

### File Organization

- Use `// MARK: -` comments to organize code sections
- A result type and the `Propagator` extension that produces it live in the same file
- Keep files under 600 lines (SwiftLint); split by responsibility with `Type+Topic.swift`

### Documentation and Comment Standards

This library is also a teaching tool, so comments explain the physics and math, not just the code:
- All public APIs have doc comments with units, an example where useful, and a reference
- Algorithms show the governing equations in a code block and cite the source (Vallado, Meeus, Spacetrack Report #3)
- Inside non-trivial functions, comment each step with what it computes and why (for example, why GMST is computed from seconds, why a convergence check needs `abs`)
- Physical constants include units and sources
- Tests state where expected values come from (worked examples, independent formulas, or other libraries)

## Testing Guidelines

### XCTest Structure

```swift
import XCTest
@testable import Ephemeris

final class MyFeatureTests: XCTestCase {

    // MARK: - Specific Feature Tests

    func testFeature_withScenario_shouldHaveExpectedBehavior() throws {
        // Given
        let input = setupInput()

        // When
        let result = calculateSomething(input)

        // Then
        XCTAssertEqual(result, expectedValue)
    }
}
```

### Test Naming Convention

Follow the pattern: `test[Feature]_[Scenario]_[ExpectedBehavior]`

### Test Data and References

- Shared TLEs live in `MockTLEs.swift` (ISS, NOAA, synthetic equatorial/polar/GEO); `MockTLEs.fixChecksum(for:)` repairs checksums for hand-built lines
- Prefer independent references over self-consistency: published worked examples (Vallado), the SGP4 verification set in `Resources/`, python-sgp4, and Skyfield
- When a test reveals a mismatch, find the cause before loosening a tolerance, and explain the tolerance in a comment
- Use `accuracy:` for floating-point comparisons and compare angles modulo 360°

## Common Patterns and Idioms

### Error Handling

- `TLEParsingError` for malformed TLE text, with the field name and offending value
- `SGP4Error` for propagation failures (decay, invalid elements), with the reference error codes
- Programmer errors (for example a negative step size, or e ≥ 1 for `KeplerianOrbit`) use `precondition`

### Iterative Solvers

Newton-Raphson (Kepler's equation), fixed-point iteration (ECEF → geodetic), bisection and golden-section search (pass events):
- Always cap the iteration count
- Compare the magnitude of the step to the tolerance
- Document the tolerance and why it is sufficient

## Platform and Dependencies

- **Swift**: 6.0 tools
- **Platforms**: iOS 16+, macOS 13+, watchOS 9+, tvOS 16+, visionOS 1+
- **Dependencies**: None (Foundation only; XCTest for tests)

## CI/CD

The GitHub Actions workflow (`.github/workflows/swift.yml`) runs:
1. Build check with `swift build -v`
2. Test execution with `swift test`
3. SwiftLint with strict mode: `swiftlint lint --strict`

All PRs must pass CI checks.

## Known Limitations and Design Choices

- **SGP4 accuracy**: About 1 km at TLE epoch, growing roughly 1-3 km per day in LEO. TLE age is the main error source.
- **UT1 and polar motion** are not applied (about 100 m and a few meters respectively)
- **Refraction** is an optical model; radio refraction near the horizon is somewhat larger
- **Target use case**: Hobbyist tracking and antenna pointing, not mission-critical operations

## Documentation Structure

The `docs/` directory follows a "theory-first" approach: math foundations first, Swift implementation second.

- `getting-started.md` - Quick-start tutorial
- `orbital-elements.md` - Keplerian elements theory + Swift code
- `observer-geometry.md` - Coordinate transformations + pass prediction
- `visualization.md` - SwiftUI and MapKit integration
- `inertial-frames.md`, `earth-fixed-frames.md`, `observer-frames.md`, `coordinate-transformations.md` - Frame math
- `time-systems.md` - Julian Day, GMST, and time conversions

## References and Resources

The README lists the academic papers and references used. Always cite them when changing calculation methods.

For AI tools: See `LLM.txt` for additional context about the project's purpose, architecture, and design goals.
