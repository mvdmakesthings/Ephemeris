# Contributing to Ephemeris

Thank you for your interest in contributing to Ephemeris! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Commit Guidelines](#commit-guidelines)
- [Reporting Issues](#reporting-issues)

## Getting Started

Ephemeris is a Swift framework for satellite tracking and orbital mechanics calculations. Before contributing, please:

1. Read the [README.md](README.md) to understand the project's purpose and capabilities
2. Review the [architecture review document](architecture-review.md) for architectural insights
3. Familiarize yourself with the [documentation](docs/) to understand orbital mechanics concepts
4. Read [CLAUDE.md](CLAUDE.md) for project-specific development guidance

## Development Setup

### Prerequisites

- macOS with Xcode 15.0+ or Swift 6.0+ command-line tools
- Git
- SwiftLint (optional but recommended)

### Installation

1. **Fork the repository**
   ```bash
   # Fork via GitHub UI, then:
   git clone https://github.com/YOUR_USERNAME/Ephemeris.git
   cd Ephemeris
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

3. **Build the framework**
   ```bash
   swift build
   ```

4. **Run tests**
   ```bash
   swift test
   ```

5. **Open in Xcode (optional)**
   ```bash
   open Package.swift
   ```

## Code Style

Ephemeris follows strict code style guidelines to maintain consistency and readability.

### Swift API Design Guidelines

Follow Apple's [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/):

- Use clear, descriptive names
- Prefer clarity over brevity
- Use grammatical articles (a, an, the) where they improve clarity
- Name functions and methods according to their side effects

### SwiftLint

The project uses SwiftLint for automated style enforcement. Our CI runs SwiftLint in strict mode.

```bash
# Install SwiftLint (if not already installed)
brew install swiftlint

# Run SwiftLint locally
swiftlint lint

# Run in strict mode (as CI does)
swiftlint lint --strict
```

**All pull requests must pass SwiftLint strict mode without warnings.**

### Project-Specific Conventions

1. **Naming Conventions**
   - Spell out orbital element names: `semimajorAxis` (not `a`)
   - Use full names: `TwoLineElement` (not `TLE` as a type name)
   - Document units in comments or variable names

2. **File Organization**
   - Use `// MARK: -` comments to organize code sections
   - Group related properties by domain (e.g., `// MARK: - Size of Orbit`)
   - Place static helper methods at the bottom of type definitions
   - Nested types go at the end of parent type definition

3. **Type Aliases**
   - Use semantic type aliases for clarity: `typealias Degrees = Double`
   - Document what the alias represents

4. **Error Handling**
   - Use descriptive error messages
   - Include context in error cases
   - Throw errors for invalid inputs, not for normal control flow

## Testing

All new features and bug fixes must include tests.

### Testing Framework

Ephemeris uses **XCTest** (Apple's standard testing framework).

### Test Naming Convention

Follow the pattern: `test[Feature]_[Scenario]_[ExpectedBehavior]`

```swift
func testTLEParsing_withValidISS_shouldExtractCorrectOrbitalElements()
func testTLEParsing_withInvalidChecksum_shouldThrowError()
func testOrbitCalculation_atEpoch_shouldReturnExpectedPosition()
```

### Test Structure

Use Given-When-Then structure for clarity:

```swift
func testFeature_withCondition_shouldBehave() throws {
    // Given
    let input = setupTestInput()

    // When
    let result = performOperation(input)

    // Then
    XCTAssertEqual(result, expectedValue)
}
```

### Running Tests

```bash
# Run all tests
swift test

# Run tests in Xcode
# Press Cmd+U or use the Test Navigator
```

### Test Coverage

- Aim for high test coverage on core functionality
- All public APIs should have tests
- Edge cases and error paths should be tested
- Complex algorithms should have validation tests with known values

### Generating Code Coverage Reports

Ephemeris includes tooling to generate code coverage reports for local development and CI.

**Run coverage locally:**
```bash
./scripts/coverage.sh
```

This will:
1. Run all tests with code coverage enabled
2. Generate an HTML coverage report in the `coverage/` directory
3. Print a coverage summary to the console

**View the coverage report:**
```bash
open coverage/index.html
```

The coverage report shows line-by-line coverage for all source files, making it easy to identify untested code paths.

**Coverage in CI:**
- GitHub Actions automatically generates coverage reports for all pull requests
- Coverage summaries appear in the workflow output
- Full HTML reports are available as downloadable artifacts (retained for 30 days)

**Coverage Expectations:**
- Core orbital mechanics: Aim for >90% coverage
- TLE parsing and validation: Aim for >85% coverage
- Coordinate transformations: Aim for >90% coverage
- Utility functions: Aim for >80% coverage
- Error handling paths should be tested

## Documentation

### Inline Documentation

All public APIs must have inline documentation:

```swift
/// Calculates the position of a satellite at a specific time.
///
/// This method uses Keplerian orbital mechanics to compute the satellite's
/// geocentric position (latitude, longitude, altitude) at the given date.
///
/// - Parameter date: The time at which to calculate the position
/// - Returns: The satellite's geodetic position
/// - Throws: `CalculationError.reachedSingularity` if the orbit has eccentricity >= 1.0
public func calculatePosition(at date: Date) throws -> Position {
    // Implementation
}
```

### Documentation Standards

- Explain **why**, not just **what**
- Reference academic sources for algorithms
- Include units for physical constants
- Add examples for complex APIs
- Update relevant docs/ files when adding features

### Mathematical Documentation

When implementing orbital mechanics algorithms:
- Reference the academic paper or source
- Include key equations as comments
- Explain any simplifications or assumptions
- Add validation tests with known values

## Pull Request Process

### Before Submitting

1. **Ensure all tests pass**
   ```bash
   swift test
   ```

2. **Run SwiftLint in strict mode**
   ```bash
   swiftlint lint --strict
   ```

3. **Update documentation**
   - Add/update inline documentation for any public APIs
   - Update relevant docs/ files
   - Update README.md if adding major features

4. **Add CHANGELOG entry** (if applicable)
   - Add to [Unreleased] section in CHANGELOG.md
   - Follow Keep a Changelog format

### Submitting

1. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request**
   - Use a clear, descriptive title
   - Reference any related issues
   - Describe what changed and why
   - Include test results if relevant
   - Add screenshots/examples for UI-related changes

3. **PR Description Template**
   ```markdown
   ## Description
   Brief description of what this PR does

   ## Changes
   - List of changes made

   ## Testing
   - How was this tested?
   - What edge cases were considered?

   ## Checklist
   - [ ] Tests pass (`swift test`)
   - [ ] SwiftLint strict mode passes
   - [ ] Documentation updated
   - [ ] CHANGELOG.md updated (if applicable)
   ```

### Review Process

- Maintainers will review your PR
- Address any feedback or requested changes
- Once approved, your PR will be merged

## Commit Guidelines

### Commit Messages

Write clear, descriptive commit messages:

```bash
# Good
git commit -m "Add atmospheric refraction correction to topocentric calculations"
git commit -m "Fix TLE checksum validation for edge case with trailing spaces"

# Too vague
git commit -m "Fix bug"
git commit -m "Update code"
```

### Commit Message Format

```
Short summary (50 characters or less)

Longer explanation if needed (wrap at 72 characters).
Explain the problem that this commit is solving and why
this approach was chosen.

- Bullet points are fine
- Reference issues: Fixes #123
```

## Reporting Issues

### Bug Reports

When reporting bugs, please include:

1. **Environment**
   - OS version
   - Swift version
   - Xcode version (if applicable)
   - Ephemeris version or commit

2. **Description**
   - What you expected to happen
   - What actually happened
   - Steps to reproduce

3. **Code Example**
   - Minimal reproducible example
   - Include TLE data if relevant
   - Include full error messages

4. **Additional Context**
   - Screenshots (if applicable)
   - Relevant log output

### Feature Requests

When requesting features:

1. Describe the use case
2. Explain why it would be valuable
3. Suggest an implementation approach (optional)
4. Consider if it fits the project's scope (educational satellite tracking)

## Project Scope

Ephemeris is focused on:

✅ **In Scope:**
- Keplerian orbital mechanics
- TLE parsing and validation
- Position calculations (ECI, ECEF, Geodetic)
- Observer-relative calculations
- Pass prediction
- Coordinate transformations
- Educational documentation

❌ **Out of Scope:**
- SGP4/SDP4 propagation (intentionally simplified for education)
- Real-time satellite databases
- Network API integrations
- UI components (framework is presentation-agnostic)
- Mission planning beyond basic pass prediction

## Code of Conduct

### Our Standards

- Be respectful and constructive
- Welcome newcomers and help them learn
- Focus on what is best for the project
- Show empathy towards other contributors

### Unacceptable Behavior

- Harassment or discriminatory comments
- Personal attacks
- Unconstructive criticism
- Publishing others' private information

## Questions?

If you have questions about contributing:

1. Check existing issues and pull requests
2. Review the documentation
3. Open a new issue with your question

## License

By contributing to Ephemeris, you agree that your contributions will be licensed under the Apache License 2.0.

---

Thank you for contributing to Ephemeris!
