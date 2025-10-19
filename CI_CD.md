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

To run the tests locally with Swift Package Manager:

```bash
# Build the package
swift build

# Run tests
swift test
```

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
