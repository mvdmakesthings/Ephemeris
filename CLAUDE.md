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

**Protocol-Oriented Design**: The `Orbitable` protocol provides extensibility for different orbital element providers. The `Orbit` struct is the primary implementation.

**Immutable Value Types**: All core types (`TwoLineElement`, `Orbit`, `Observer`) are structs with value semantics for thread safety and clarity.

**Static Utility Functions**: Mathematical calculations are often implemented as static methods on types or in utility namespaces (e.g., `CoordinateTransforms`) for testability and reusability.

### Key Components and Responsibilities

**TwoLineElement** (`TwoLineElement.swift`)
- Parses and validates NORAD Two-Line Element format satellite data
- Implements fixed-width field extraction with checksum verification
- Handles 2-digit year interpretation (±50 year window)
- Throws comprehensive `TLEParsingError` with context

**Orbit** (`Orbit.swift` - 935 lines, largest file)
- Central hub for orbital mechanics calculations
- Converts TLE data to Keplerian orbital elements
- Key capabilities:
  - `calculatePosition(at:)` - Full ECI → ECEF → Geodetic pipeline
  - `topocentric(at:for:)` - Observer-relative coordinates (azimuth, elevation, range)
  - `predictPasses(for:from:to:)` - Satellite pass prediction with bisection/golden-section search
  - `groundTrack(from:to:stepSeconds:)` - Ground track visualization data
  - `skyTrack(for:from:to:stepSeconds:)` - Sky path visualization data
- Contains nested types: `Position`, `GroundTrackPoint`, `SkyTrackPoint`, `PassWindow`, `Topocentric`
- Uses Kepler's equation with iterative Newton-Raphson solver

**Observer** (`Observer.swift`)
- Represents a ground observer location (latitude, longitude, altitude)
- Simple value type used by `Orbit.topocentric()` and pass prediction

**CoordinateTransforms** (`CoordinateTransforms.swift`)
- Static utility namespace for coordinate system conversions
- Supports: ECI (Earth-Centered Inertial) ↔ ECEF (Earth-Centered Earth-Fixed) ↔ ENU (East-North-Up) ↔ Horizontal (Az/El)
- Implements Bennett formula for atmospheric refraction correction
- All methods are pure functions

**Utilities Directory** (`Sources/Ephemeris/Utilities/`)
- `Date.swift`: Julian Day and Greenwich Mean Sidereal Time (GMST) calculations
- `Double.swift`: Degree/radian conversions and angle utilities
- `PhysicalConstants.swift`: WGS-84 Earth parameters, gravitational constants (with sources documented)
- `StringProtocol+subscript.swift`: Safe string subscripting helpers
- `TypeAlias.swift`: Semantic type aliases (e.g., `Degrees`, `Radians`)

## Important Implementation Details

### Why Keplerian Mechanics (Not SGP4)?

This framework implements **two-body Keplerian mechanics** instead of SGP4/SDP4:
- **Educational focus**: Easier to understand and teach
- **Simplicity**: No atmospheric drag model complexity
- **Pure Swift**: No need to port C/C++ SGP4 code
- **Transparency**: Users see exactly what calculations are happening
- **Trade-off**: Less accurate for long-term predictions (best within 1-3 days of TLE epoch)

This is an intentional design decision documented in both the README and LLM.txt.

### Coordinate Systems and Transformations

The framework uses the WGS-84 geodetic standard and implements the following coordinate systems:
- **ECI (Earth-Centered Inertial)**: Fixed relative to stars, used for orbital calculations
- **ECEF (Earth-Centered Earth-Fixed)**: Rotates with Earth, used for ground-relative positions
- **ENU (East-North-Up)**: Local tangent plane at observer location
- **Horizontal (Az/El)**: Observer-centric spherical coordinates

Position calculation pipeline: Keplerian elements → ECI coordinates → ECEF coordinates → Geodetic (lat/lon/alt)

### Time Systems

- Julian Day calculations for astronomical time
- Greenwich Mean Sidereal Time (GMST) for Earth rotation
- TLE epoch interpretation handles 2-digit years with ±50 year window
- All date conversions are in `Date.swift` utilities

## Code Style and Conventions

### Naming Conventions

- **Orbital Elements**: Standard notation with full names
  - `semimajorAxis` (not `a`) - km
  - `eccentricity` (not `e`) - dimensionless
  - `inclination` (not `i`) - degrees
  - `rightAscensionOfAscendingNode` (not `RAAN` or `Ω`) - degrees
  - `argumentOfPerigee` (not `ω`) - degrees
- **Type Aliases**: Used for semantic clarity (`typealias Degrees = Double`)
- **Units**: Always documented in comments or variable names

### File Organization

- Use `// MARK: -` comments to organize code sections
- Group related properties by domain (e.g., `// MARK: - Size of Orbit`)
- Static helper methods at the bottom of type definitions
- Nested types at the end of parent type definition

### Documentation Standards

- All public APIs must have inline documentation
- Mathematical algorithms should reference academic sources
- Physical constants must include units and sources
- Complex calculations should include intermediate comments explaining the math

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

Examples:
- `testTLEParsing_withValidISS_shouldExtractCorrectOrbitalElements()`
- `testPassPrediction_forLowEarthOrbit_shouldFindVisiblePasses()`
- `testGroundTrack_forEquatorialOrbit_shouldStayNearEquator()`

### Test Data

- Use real satellite data for validation (ISS, GOES-16, GPS satellites)
- Mock TLE data lives in `MockTLEs.swift`
- Use accuracy parameter for floating-point comparisons: `XCTAssertEqual(value, expected, accuracy: 0.00001)`
- Include comments with known values and their sources

### Test Organization

- XCTest automatically discovers test classes (no registration needed)
- Use `// MARK: -` comments to organize tests into logical sections
- Keep Given-When-Then structure in test bodies for clarity
- Use helper methods for common setup (private methods in test class)

## Common Patterns and Idioms

### Error Handling

```swift
// TLE Parsing - throw descriptive errors
guard !tleString.isEmpty else {
    throw TLEParsingError.invalidFormat("TLE string is empty")
}

// Orbital calculations - throw for impossible cases
guard eccentricity < 1.0 else {
    throw CalculationError.reachedSingularity
}
```

### Iterative Solvers

The framework uses iterative methods (Newton-Raphson) for solving Kepler's equation:
- Always include max iteration limits
- Check for convergence with appropriate tolerance
- Throw errors if convergence fails

### Coordinate Transformations

All coordinate transformations preserve intermediate results for debugging and transparency. The pattern is:
1. Calculate transformation matrices
2. Apply transformations
3. Convert to target coordinate system
4. Return result in user-friendly units

## Platform and Dependencies

- **Swift**: 6.0 tools
- **Platforms**: iOS 16+, macOS 13+, watchOS 9+, tvOS 16+, visionOS 1+
- **Dependencies**: None (XCTest is built into Swift)
- **External Frameworks**: None (only Foundation)

## CI/CD

The GitHub Actions workflow (`.github/workflows/swift.yml`) runs:
1. Build check with `swift build -v`
2. Test execution with `swift test`
3. SwiftLint with strict mode: `swiftlint lint --strict`

All PRs must pass CI checks.

## Known Limitations and Design Choices

### Accuracy Considerations

- **Best accuracy**: Within 1-3 days of TLE epoch
- **Recommendation**: Update TLEs every 1-3 days for LEO satellites
- **No modeling**: Atmospheric drag, solar radiation pressure, or gravitational perturbations not included
- **Target use case**: Hobbyist/educational satellite tracking, not mission-critical applications

### Future Enhancements

The architecture review document (`architecture-review.md`) identifies potential improvements:
- Standardizing to `Sources/` and `Tests/` directory structure
- Potentially migrating to XCTest for better tooling integration
- Splitting `Orbit.swift` into smaller focused files
- Adding platform support for watchOS, tvOS, and visionOS

## Documentation Structure

The `docs/` directory follows a "theory-first" approach:
- **Math foundations** with diagrams first
- **Swift implementation** second
- Targets both learners and practitioners

Key docs:
- `getting-started.md` - Quick-start tutorial
- `orbital-elements.md` - Keplerian elements theory + Swift code
- `observer-geometry.md` - Coordinate transformations + pass prediction
- `visualization.md` - SwiftUI and MapKit integration
- `coordinate-systems.md` - Mathematical foundations
- `time-systems.md` - Julian Day, GMST, and time conversions

## References and Resources

The README contains comprehensive references to academic papers and NASA documentation used for implementing orbital mechanics algorithms. Always reference these when making changes to calculation methods.

For AI tools: See `LLM.txt` for additional context about the project's purpose, architecture, and design goals.
