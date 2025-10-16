# Ephemeris - Copilot Instructions

## Project Overview
Ephemeris is a Swift framework for satellite tracking using orbital mechanics and Two-Line Element (TLE) data format. The framework provides calculations for orbital elements, satellite positions, and related astrodynamics computations.

## Technology Stack
- Language: Swift
- Platform: iOS/macOS (Xcode project)
- Testing: XCTest framework
- Project Structure: Xcode project (.xcodeproj)

## Code Style and Conventions

### Swift Code Style
- Use Swift naming conventions:
  - Types (classes, structs, enums): `UpperCamelCase`
  - Functions and variables: `lowerCamelCase`
  - Constants: Use `let` for immutable values
- Use `public` visibility for framework APIs
- Include MARK comments to organize code sections (e.g., `// MARK: - Section Name`)
- Follow Apple's Swift API Design Guidelines

### Documentation
- Add inline documentation for public APIs
- Include references to academic sources and formulas when implementing mathematical algorithms
- Document physical constants with their units (e.g., km, degrees)
- Reference external resources (papers, NASA docs) when implementing complex orbital mechanics

### Code Organization
- Group related properties using MARK comments:
  - `// MARK: - Size of Orbit`
  - `// MARK: - Shape of Orbit`
  - `// MARK: - Orientation of Orbit`
  - `// MARK: - Position of Craft`
- Keep utility functions in the `Utilities` folder
- Separate concerns: core orbital mechanics in `Orbit.swift`, data parsing in `TwoLineElement.swift`

## Testing Guidelines

### Test Framework
- Use XCTest for all unit tests
- Test files should be in the `EphemerisTests` folder
- Use `@testable import Ephemeris` to access internal APIs
- Test class names should end with `Tests` (e.g., `OrbitalCalculationTests`)

### Test Structure
- Use `setUp()` / `setUpWithError()` for test initialization
- Use `tearDown()` / `tearDownWithError()` for cleanup
- Test function names should start with `test` (e.g., `testCalculateSemimajorAxis`)
- Include comments with known values and sources (e.g., "GOES 16 Satellite")
- Use `XCTAssertEqual` for comparing computed values
- Round floating-point values for comparison (e.g., `.round(to: 5)`)

### Test Data
- Use real satellite data for validation (e.g., GOES 16, ISS)
- Include references to numerical examples from academic sources
- Mock TLE data should be in `MockTLEs.swift`

## Building and Testing

### Xcode Project
- Build the project using Xcode or `xcodebuild`
- Run tests using Xcode Test Navigator or `xcodebuild test`
- The project contains:
  - `Ephemeris`: Main framework target
  - `EphemerisDemo`: Demo iOS application
  - `EphemerisTests`: Unit test target

### Dependencies
- No external dependencies (uses Foundation framework only)
- No package managers required (CocoaPods, SPM, Carthage)

## Domain-Specific Guidelines

### Orbital Mechanics
- Use standard orbital element notation:
  - `a`: Semi-major axis (km)
  - `e`: Eccentricity (0-1)
  - `i`: Inclination (degrees)
  - `Ω` (Omega): Right Ascension of Ascending Node (degrees)
  - `ω` (omega): Argument of Perigee (degrees)
  - `M`: Mean Anomaly
  - `ν` or `θ`: True Anomaly (degrees)
- Include units in variable names or documentation
- Use type aliases for clarity (e.g., `typealias Degrees = Double`)

### Physical Constants
- Store physical constants in `PhysicalConstants.swift`
- Document the source and units for each constant
- Use SI units where applicable, convert as needed

### TLE Data
- Follow NORAD Two-Line Element format specifications
- Validate TLE data format and checksums
- Handle epoch time conversions properly

## File Header Convention
All Swift files should include a standard header:
```swift
//
//  FileName.swift
//  Ephemeris
//
//  Created by [Author] on [Date].
//  Copyright © [Year] Michael VanDyke. All rights reserved.
//
```

## Git and Version Control
- Follow the existing `.gitignore` patterns
- Ignore Xcode user data (`xcuserdata/`)
- Ignore build artifacts (`build/`, `DerivedData/`)
- Don't commit `.DS_Store` files

## Additional Resources
The project README contains links to academic papers and resources used for implementing orbital mechanics algorithms. Reference these when making changes to calculation methods.
