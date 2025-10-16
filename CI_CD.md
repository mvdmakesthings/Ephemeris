# CI/CD Configuration

This repository uses GitHub Actions for continuous integration and deployment.

## Workflows

### CI Workflow (`.github/workflows/ci.yml`)

The CI workflow runs on:
- Push to `master` branch
- Pull requests targeting `master` branch

#### Jobs

**1. Build and Test**
- Runs on: macOS latest
- Steps:
  - Checks out the code
  - Sets up Xcode (latest stable version)
  - Builds the Ephemeris framework
  - Runs all tests with code coverage enabled
  - Generates coverage report (JSON format)
  - Uploads coverage to Codecov (optional, requires setup)

**2. Lint**
- Runs on: macOS latest
- Steps:
  - Checks out the code
  - Installs SwiftLint via Homebrew
  - Runs SwiftLint to check code quality

## Local Development

### Running Tests Locally

To run the tests locally with coverage:

```bash
xcodebuild test \
  -scheme Ephemeris \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 14,OS=latest' \
  -enableCodeCoverage YES
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

## Code Coverage

Code coverage is tracked through:
1. Xcode's built-in coverage tools (`xccov`)
2. Optional integration with [Codecov](https://codecov.io)

### Setting Up Codecov (Optional)

To enable Codecov integration:

1. Sign up for [Codecov](https://codecov.io) and connect your repository
2. Add the `CODECOV_TOKEN` secret to your repository:
   - Go to repository Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `CODECOV_TOKEN`
   - Value: Your Codecov token
3. The CI workflow will automatically upload coverage reports

## Build Status

Once the workflow has run, you can add badges to your README.md:

```markdown
![CI](https://github.com/mvdmakesthings/Ephemeris/workflows/CI/badge.svg)
[![codecov](https://codecov.io/gh/mvdmakesthings/Ephemeris/branch/master/graph/badge.svg)](https://codecov.io/gh/mvdmakesthings/Ephemeris)
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

### Coverage Upload Issues

If coverage upload fails:

- This is set to `continue-on-error: true`, so it won't fail the build
- Verify that `CODECOV_TOKEN` is set correctly in repository secrets
- Check the Codecov dashboard for any error messages
