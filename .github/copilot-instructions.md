# Ephemeris - Copilot Instructions

## Project Overview
Ephemeris is a Swift framework for satellite tracking using orbital mechanics and Two-Line Element (TLE) data format. The framework provides calculations for orbital elements, satellite positions, and related astrodynamics computations.

## Current Project Status
The project has undergone a comprehensive code review identifying 35 issues (see `.github/ISSUES/CODE_REVIEW_SUMMARY.md`). Key priorities include:
- **Critical issues**: Error handling, input validation, and bounds checking
- **Testing improvements**: Expanding coverage and edge cases
- **Documentation**: API docs and usage examples
- **Distribution**: Swift Package Manager support is now available

## Technology Stack
- Language: Swift 6.0+
- Platforms: iOS 16+, macOS 13+
- Testing: Spectre (BDD-style testing framework)
- Package Manager: Swift Package Manager (SPM)
- Project Structure: SPM package with Xcode project compatibility

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
- Use **Spectre** for all unit tests (BDD-style testing)
- Test files should be in the `EphemerisTests` folder
- Use `@testable import Ephemeris` to access internal APIs
- Import Spectre: `import Spectre`
- Test files define closure-based test suites, not classes

### Test Structure (Spectre BDD-style)
Tests use a nested BDD structure with `describe`, `context`, and `it`:

```swift
import Spectre
@testable import Ephemeris

let myTests: ((ContextType) -> Void) = {
    $0.describe("Feature Name") {
        
        $0.context("specific scenario") {
            $0.it("does something specific") {
                let result = calculateSomething()
                try expect(result == expectedValue)
            }
        }
        
        $0.it("handles basic case") {
            // Test code here
            try expect(condition)
        }
    }
}
```

- Use `describe` for grouping related tests (top-level feature)
- Use `context` for specific scenarios or conditions (optional, for organization)
- Use `it` for individual test cases
- Use `try expect(condition)` for assertions (replaces XCTAssert)
- Include comments with known values and sources (e.g., "GOES 16 Satellite")
- Round floating-point values for comparison (e.g., `.round(to: 5)`)

### Test Registration
Register test suites in `main.swift`:

```swift
describe("FeatureName", myTests)
```

### Test Data
- Use real satellite data for validation (e.g., GOES 16, ISS)
- Include references to numerical examples from academic sources
- Mock TLE data should be in `MockTLEs.swift`

## Building and Testing

### Swift Package Manager (Recommended)
The project uses Swift Package Manager as the primary build system:

```bash
# Build the framework
swift build

# Run tests
swift run EphemerisTests

# Build in release mode
swift build -c release
```

### Xcode
You can also open and build the project in Xcode:

1. Open `Package.swift` in Xcode (File → Open)
2. Build: `⌘B`
3. Run tests: `⌘U` or `swift run EphemerisTests` in terminal

The project contains:
- `Ephemeris`: Main framework target (library)
- `EphemerisTests`: Test executable target using Spectre

### Dependencies
- **Spectre** (v0.10.1+): BDD-style testing framework
  - Repository: https://github.com/kylef/Spectre.git
  - Used for all unit tests
- **Foundation**: Apple's foundational framework (system dependency)

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

## Error Handling Best Practices

### Current State (Post-Review)
The codebase is transitioning to robust error handling. When making changes:

1. **TLE Parsing**: Use throwing initializers for invalid input
   - See issue #01 in `.github/ISSUES/01-tle-parsing-error-handling.md`
   - Validate all required fields before parsing
   - Throw descriptive errors for malformed data

2. **Input Validation**: Always validate inputs
   - See issue #09 in `.github/ISSUES/09-missing-input-validation.md`
   - Check bounds, ranges, and preconditions
   - Use guard statements with descriptive errors

3. **Bounds Checking**: Prevent crashes from string subscripting
   - See issue #30 in `.github/ISSUES/30-bounds-checking-tle-parsing.md`
   - Always check string lengths before subscripting
   - Use safe subscripting helpers where available

4. **Division by Zero**: Check for zero divisors
   - See issue #31 in `.github/ISSUES/31-division-by-zero.md`
   - Validate denominators before division operations
   - Handle edge cases in iterative calculations

### Error Handling Pattern
```swift
public init(from tleString: String) throws {
    // Validate input
    guard !tleString.isEmpty else {
        throw TLEError.emptyInput
    }
    
    // Check bounds before accessing
    guard tleString.count >= requiredLength else {
        throw TLEError.invalidFormat
    }
    
    // Parse with validation
    // ...
}
```

## Platform Requirements

### Minimum Versions
- **Swift**: 6.0 or later
- **iOS**: 16.0+
- **macOS**: 13.0+

These requirements are specified in `Package.swift`:
```swift
platforms: [
    .iOS(.v16),
    .macOS(.v13)
]
```

## Code Review Issues

The project has undergone a comprehensive code review. All identified issues are documented in `.github/ISSUES/`:

### Critical Priority (🔴)
- #01: TLE parsing error handling
- #02: Inconsistent physical constants
- #30: Bounds checking in TLE parsing
- Additional critical issues in CODE_REVIEW_SUMMARY.md

### Medium Priority (🟡)
- #03: Remove debug print statements
- #15: Expand test coverage
- #23: SwiftLint enforcement
- Additional medium issues in CODE_REVIEW_SUMMARY.md

### Low Priority (🟢)
- #07: Fix typo "perpandicular" → "perpendicular"
- #08: Remove unused Math.swift file
- #20: Add README code examples
- Additional low priority issues in CODE_REVIEW_SUMMARY.md

**Total**: 35 issues documented across 9 categories

When making changes, consider addressing related issues from the code review. See:
- `.github/ISSUES/CODE_REVIEW_SUMMARY.md` - Complete list with descriptions
- `.github/ISSUES/ROADMAP.md` - Phased implementation plan
- Individual issue files in `.github/ISSUES/` - Detailed acceptance criteria

## Git and Version Control
- Follow the existing `.gitignore` patterns
- Ignore Xcode user data (`xcuserdata/`)
- Ignore build artifacts (`build/`, `DerivedData/`, `.build/`)
- Ignore SPM artifacts (`Package.resolved` is tracked, but `.build/` is not)
- Don't commit `.DS_Store` files

## Additional Resources
The project README contains links to academic papers and resources used for implementing orbital mechanics algorithms. Reference these when making changes to calculation methods.

### Documentation Files
- `README.md` - Project overview, usage examples, and references
- `CODE_REVIEW_COMPLETE.md` - Summary of completed code review
- `.github/ISSUES/CODE_REVIEW_SUMMARY.md` - Detailed list of all 35 issues
- `.github/ISSUES/ROADMAP.md` - Implementation roadmap to v1.0
- `docs/Introduction-to-Orbital-Elements.md` - Guide to orbital mechanics concepts
