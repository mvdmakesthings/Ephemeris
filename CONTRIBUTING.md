# Contributing to Ephemeris

Thank you for your interest in contributing to Ephemeris! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## Getting Started

### Prerequisites

- Xcode 11.0 or later
- Swift 5.0 or later
- macOS for development
- Git

### Finding Issues to Work On

1. Check the [Issues](https://github.com/mvdmakesthings/Ephemeris/issues) page
2. Look for issues labeled `good-first-issue` for beginner-friendly tasks
3. Check for issues labeled `help-wanted` for areas needing contribution
4. Comment on an issue to indicate you're working on it

## Development Setup

### Clone the Repository

```bash
git clone https://github.com/mvdmakesthings/Ephemeris.git
cd Ephemeris
```

### Using Xcode

1. Open `Ephemeris.xcodeproj` in Xcode
2. Select the Ephemeris scheme
3. Build the project (⌘+B)
4. Run tests (⌘+U)

### Using Swift Package Manager

```bash
# Build the package
swift build

# Run tests (note: some tests may have compilation issues - this is a known issue)
swift test
```

### Install SwiftLint

```bash
brew install swiftlint
```

## Making Changes

### Branching Strategy

1. Fork the repository (for external contributors)
2. Create a feature branch from `master`:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-number-description
   ```

### Branch Naming Conventions

- Feature branches: `feature/descriptive-name`
- Bug fixes: `fix/issue-number-description`
- Documentation: `docs/what-you-are-documenting`
- Refactoring: `refactor/what-you-are-refactoring`

## Coding Standards

### Swift Style Guide

This project follows Swift best practices and conventions:

- Use descriptive variable and function names
- Follow Swift naming conventions (camelCase for variables/functions, UpperCamelCase for types)
- Add documentation comments for public APIs
- Use `MARK:` comments to organize code sections
- Keep functions focused and concise

### SwiftLint

All code must pass SwiftLint checks:

```bash
# Run SwiftLint
swiftlint lint

# Auto-fix some issues
swiftlint lint --fix
```

Configuration is in `.swiftlint.yml`.

### Physical Constants and Mathematical Formulas

When implementing orbital mechanics calculations:

- Include references to academic sources or standards
- Document units clearly (km, degrees, radians, etc.)
- Use descriptive variable names that match standard notation where possible
- Add inline comments explaining complex formulas

Example:
```swift
/// Calculate semi-major axis from mean motion
/// - Parameter meanMotion: Revolutions per day
/// - Returns: Semi-major axis in kilometers
/// - Note: Based on Kepler's Third Law: a³ = (μ/n²)
public static func calculateSemimajorAxis(meanMotion: Double) -> Double {
    // Implementation with clear units and references
}
```

## Testing

### Writing Tests

- Add unit tests for all new functionality
- Test edge cases and error conditions
- Use descriptive test names: `testCalculateSemimajorAxisWithValidInput()`
- Include known values and references in test comments

### Running Tests

#### Xcode
```bash
# Command line
xcodebuild test \
  -project Ephemeris.xcodeproj \
  -scheme Ephemeris \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Or use Xcode UI (⌘+U)
```

#### Swift Package Manager
```bash
swift test
```

### Test Coverage

Aim for high test coverage on critical orbital mechanics calculations.

## Documentation

### Code Documentation

- Add documentation comments (`///`) for all public APIs
- Include parameter descriptions, return values, and usage examples
- Reference academic papers or standards where applicable

Example:
```swift
/// Two-Line Element Format is a data format encoding orbital elements
/// of an Earth-orbiting object for a given point in time (epoch).
///
/// - Link: https://en.wikipedia.org/wiki/Two-line_element_set
public struct TwoLineElement {
    // ...
}
```

### README Updates

Update the README.md if your changes:
- Add new features
- Change the API
- Modify installation instructions
- Add new dependencies

## Submitting Changes

### Commit Messages

Write clear, descriptive commit messages:

```
Add calculation for eccentric anomaly

- Implement Newton-Raphson iteration method
- Add convergence tolerance parameter
- Include unit tests with known values
- Reference Vallado algorithm
```

### Pull Request Process

1. Update documentation as needed
2. Run SwiftLint and fix any violations
3. Ensure all tests pass
4. Push your branch to your fork
5. Open a Pull Request against the `master` branch
6. Fill out the PR template completely
7. Link related issues (e.g., "Fixes #123")
8. Wait for review and address feedback

### PR Guidelines

- Keep PRs focused on a single feature or fix
- Include tests for new functionality
- Update documentation
- Respond to review comments promptly
- Keep commits clean and well-organized

## Release Process

### Semantic Versioning

Ephemeris follows [Semantic Versioning](https://semver.org/):

- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features, backward compatible
- **Patch** (0.0.1): Bug fixes, backward compatible

### Creating Releases

(For maintainers)

1. Update version numbers
2. Update CHANGELOG.md
3. Create and push a tag:
   ```bash
   git tag -a v1.0.0 -m "Version 1.0.0"
   git push origin v1.0.0
   ```
4. Create a GitHub Release with release notes

## Questions?

- Open an issue for discussion
- Check existing documentation
- Review closed issues and PRs for similar topics

## License

By contributing to Ephemeris, you agree that your contributions will be licensed under the Apache License 2.0.

---

Thank you for contributing to Ephemeris! 🛰️
