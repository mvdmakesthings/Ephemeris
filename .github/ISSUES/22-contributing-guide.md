---
title: "Add CONTRIBUTING.md with contribution guidelines"
labels: ["documentation", "good-first-issue", "community"]
---

## Description

The repository lacks a `CONTRIBUTING.md` file that explains how contributors should submit pull requests, report bugs, and follow coding standards. This makes it harder for new contributors to get involved.

## Current Behavior

- No contribution guidelines
- Unclear how to submit PRs
- No coding standards documented
- No issue templates
- Inconsistent contribution quality

**Impact:**
- Higher barrier to entry for contributors
- Inconsistent PR quality
- More back-and-forth in PR reviews
- Maintainer time spent explaining process

## Expected Behavior

A comprehensive `CONTRIBUTING.md` that covers:

1. **How to Get Started**
2. **Code of Conduct**
3. **How to Report Bugs**
4. **How to Suggest Features**
5. **Development Setup**
6. **Coding Standards**
7. **Testing Requirements**
8. **Pull Request Process**
9. **Documentation Standards**

## Proposed Content

Create `CONTRIBUTING.md`:

```markdown
# Contributing to Ephemeris

Thank you for your interest in contributing to Ephemeris! This document provides guidelines for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

Be respectful, inclusive, and professional. We're all here to build better software and learn from each other.

## Getting Started

1. **Fork the repository**
2. **Clone your fork**: `git clone https://github.com/YOUR_USERNAME/Ephemeris.git`
3. **Open in Xcode**: `open Ephemeris.xcodeproj`
4. **Run tests**: `⌘U` or `xcodebuild test`

## How to Contribute

### Reporting Bugs

Use the GitHub issue tracker:

1. Check if the bug already exists
2. Create a new issue with:
   - Clear title
   - Description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Xcode and Swift version
   - Example code (if applicable)

### Suggesting Features

1. Check if feature already requested
2. Create an issue describing:
   - The problem you're trying to solve
   - Your proposed solution
   - Alternative approaches considered
   - Impact on existing functionality

### Submitting Pull Requests

1. Create a branch: `git checkout -b feature/your-feature-name`
2. Make your changes
3. Add tests for new functionality
4. Ensure all tests pass
5. Run SwiftLint: `swiftlint`
6. Commit with clear message
7. Push and create PR

## Development Setup

### Prerequisites

- Xcode 14.0+
- Swift 5.7+
- SwiftLint (for code style)

### Install SwiftLint

```bash
brew install swiftlint
```

### Build and Test

```bash
# Build
xcodebuild -project Ephemeris.xcodeproj -scheme Ephemeris build

# Test
xcodebuild test -project Ephemeris.xcodeproj -scheme Ephemeris \
  -destination 'platform=iOS Simulator,name=iPhone 14'

# Lint
swiftlint
```

## Coding Standards

### Swift Style

Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/):

- Use `lowerCamelCase` for variables and functions
- Use `UpperCamelCase` for types
- Prefer `let` over `var`
- Use meaningful names
- Add documentation comments for public APIs

### Orbital Mechanics

- Include units in variable names or documentation
- Reference academic sources for algorithms
- Add comments explaining mathematical formulas
- Use standard notation (a, e, i, Ω, ω, ν)

### Documentation

```swift
/// Brief description of the function.
///
/// Detailed explanation of what the function does,
/// including mathematical background if relevant.
///
/// - Parameters:
///   - paramName: Description with units
/// - Returns: Description with units
/// - Throws: Error conditions
///
/// Example:
/// ```swift
/// let result = calculateOrbitalPeriod(semimajorAxis: 7000)
/// ```
func calculateOrbitalPeriod(semimajorAxis: Double) -> Double {
    // Implementation
}
```

### File Headers

All Swift files should include:

```swift
//
//  FileName.swift
//  Ephemeris
//
//  Created by Your Name on Date.
//  Copyright © 2024 Michael VanDyke. All rights reserved.
//
```

## Testing

### Test Requirements

- All new features must have tests
- Bug fixes should include regression tests
- Aim for >80% code coverage
- Tests should be fast and deterministic

### Test Structure

```swift
import XCTest
@testable import Ephemeris

class YourFeatureTests: XCTestCase {
    
    func testYourFeature() {
        // Given
        let input = ...
        
        // When
        let result = ...
        
        // Then
        XCTAssertEqual(result, expected)
    }
}
```

### Test Naming

- Prefix with `test`
- Use descriptive names: `testHighEccentricityOrbitCalculation`
- Test one thing per test

## Pull Request Process

### Before Submitting

- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] SwiftLint violations fixed
- [ ] Documentation added/updated
- [ ] CHANGELOG.md updated (if applicable)

### PR Description

Include:

```markdown
## Summary
Brief description of changes

## Related Issue
Fixes #123

## Changes Made
- Change 1
- Change 2

## Testing
How you tested the changes

## Screenshots
If applicable
```

### Review Process

1. Maintainer reviews PR
2. Address feedback
3. Maintainer approves and merges
4. Branch deleted

## Questions?

Open a discussion on GitHub or comment on relevant issues.

Thank you for contributing! 🚀
```

## Additional Files to Create

### Issue Templates

Create `.github/ISSUE_TEMPLATE/`:

1. **bug_report.md**
2. **feature_request.md**
3. **question.md**

### Pull Request Template

Create `.github/pull_request_template.md`:

```markdown
## Description
Brief description of changes

## Related Issue
Fixes #(issue number)

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] SwiftLint passes
- [ ] All tests pass
```

## Additional Context

- Priority: **Low** - Community enhancement
- Effort: **2-3 hours**
- Impact: **High** - Improves contributor experience
- Related to: Building open-source community

## References

- [GitHub's Contributing Guide](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors)
- [Contributor Covenant](https://www.contributor-covenant.org/)

## Acceptance Criteria

- [ ] CONTRIBUTING.md created with comprehensive guidelines
- [ ] Bug report issue template added
- [ ] Feature request issue template added
- [ ] Pull request template added
- [ ] README updated to link to CONTRIBUTING.md
- [ ] Code of conduct reference included
- [ ] Development setup instructions clear
- [ ] Coding standards documented
- [ ] Testing requirements explained
- [ ] PR process outlined
