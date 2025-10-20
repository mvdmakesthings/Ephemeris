# CI/CD Configuration

This repository uses GitHub Actions for continuous integration and deployment.

## Workflows

### CI Workflow (`.github/workflows/swift.yml`)

The CI workflow runs on:
- Push to `master` branch
- Pull requests targeting `master` branch

#### Jobs

**1. Build and Test**
- Runs on: macOS latest
- Steps:
  - Checks out the code
  - Sets up Xcode (for Swift toolchain)
  - Displays Swift version
  - Builds the Ephemeris package using Swift Package Manager
  - Runs all tests with Swift Package Manager

**2. Lint**
- Runs on: macOS latest
- Steps:
  - Checks out the code
  - Installs SwiftLint via Homebrew
  - Runs SwiftLint to check code quality

## Local Development

### Running Tests Locally

The Ephemeris test suite uses [Spectre](https://github.com/kylef/Spectre), a BDD-style testing framework for Swift. Tests are run as an executable rather than with the standard XCTest framework.

To run the tests locally:

```bash
# Build the package
swift build

# Run tests using the executable
swift run EphemerisTests
```

The test suite is pure Swift and does not require Xcode or the Xcode toolkit. It can be run on any system with Swift installed (including Linux).

### Test Suite Structure

All tests are located in the `EphemerisTests` directory and use Spectre's `describe`/`context`/`it` and `expect` syntax:

- **DoubleExtensionTests.swift**: Tests for Double extension methods (rounding, angle conversions)
- **DateTests.swift**: Tests for Date extensions (Julian Day, sidereal time)
- **PhysicalConstantsTests.swift**: Tests for physical constants validation
- **TwoLineElementTests.swift**: Tests for TLE parsing
- **OrbitalElementsTests.swift**: Tests for orbital element calculations
- **OrbitalCalculationTests.swift**: Tests for orbital calculations
- **MockTLEs.swift**: Mock TLE data for testing
- **main.swift**: Test runner that registers all test suites

### Running SwiftLint Locally

First, install SwiftLint:

```bash
brew install swiftlint
```

Then run it:

```bash
swiftlint lint
```

To auto-fix some issues:

```bash
swiftlint lint --fix
```

## SwiftLint Configuration

The `.swiftlint.yml` file contains the linting rules for this project. Key configurations:

- **Line length**: Warning at 120 chars, error at 150 chars
- **File length**: Warning at 500 lines, error at 1000 lines
- **Function body length**: Warning at 60 lines, error at 100 lines
- **Excluded paths**: Pods, .build, DerivedData, fastlane, documentation

## Build Status

Once the workflow has run, you can add badges to your README.md:

```markdown
![CI](https://github.com/mvdmakesthings/Ephemeris/workflows/CI/badge.svg)
```

## Troubleshooting

### Workflow Failures

If the workflow fails:

1. Check the Actions tab in GitHub to see detailed logs
2. Look for specific error messages in the build/test/lint steps
3. Run the failing commands locally to reproduce the issue

### SwiftLint Issues

If SwiftLint reports violations:

1. Review the SwiftLint output to see what rules are violated
2. Fix the issues manually or run `swiftlint lint --fix` for auto-fixable issues
3. If a rule doesn't fit your project, you can disable it in `.swiftlint.yml`
