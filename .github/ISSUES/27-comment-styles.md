---
title: "Standardize documentation comment style"
labels: ["code-style", "documentation", "good-first-issue"]
---

## Description

The codebase uses inconsistent comment styles, mixing `//`, `///`, and `/* */`. Swift documentation should use `///` for public APIs to enable proper documentation generation.

## Current Behavior

**Mix of comment styles:**

```swift
// Regular comment
var privateProperty: Double

/// Documentation comment (correct for public API)
public var publicProperty: Double

/* Multi-line comment */
private func helperMethod() {}

/** JavaDoc-style comment */
public func publicMethod() {}
```

**Impact:**
- Inconsistent documentation style
- Some public APIs lack proper docs
- Documentation generators can't parse all styles
- Confusing for contributors

## Expected Behavior

Consistent Swift documentation style:

```swift
// MARK: - Section Name

/// Brief description of public API.
///
/// Detailed description can span multiple lines
/// and include examples.
///
/// - Parameter param: Description
/// - Returns: Description
/// - Throws: Description
public func publicMethod(param: String) throws -> String {
    // Implementation comments use //
    let result = param.uppercased()
    return result
}

// Private methods can use // comments
private func helperMethod() {
    // Internal implementation details
}
```

## Swift Documentation Standards

### Public APIs: Use `///`

```swift
/// Calculates the orbital period in seconds.
///
/// Uses Kepler's Third Law: T = 2π√(a³/μ)
/// where:
/// - a is the semi-major axis
/// - μ is the gravitational parameter
///
/// - Parameter semimajorAxis: Semi-major axis in kilometers
/// - Returns: Orbital period in seconds
/// - Throws: `OrbitError.invalidParameter` if semimajorAxis ≤ 0
///
/// Example:
/// ```swift
/// let period = try calculateOrbitalPeriod(semimajorAxis: 7000)
/// print("Period: \(period) seconds")
/// ```
public func calculateOrbitalPeriod(semimajorAxis: Double) throws -> Double {
    // Implementation
}
```

### Code Organization: Use `// MARK:`

```swift
// MARK: - Initialization

public init() { }

// MARK: - Public Methods

public func publicMethod() { }

// MARK: - Private Helpers

private func helperMethod() { }
```

### Implementation Comments: Use `//`

```swift
public func complexCalculation() -> Double {
    // Step 1: Calculate initial value
    let initial = calculateInitial()
    
    // Step 2: Apply correction factor
    let corrected = initial * correctionFactor
    
    // Step 3: Return result
    return corrected
}
```

### Multi-line Comments: Use `//` for Each Line

```swift
// This is a multi-line comment
// explaining a complex algorithm or
// mathematical formula in detail.
```

**Avoid** `/* */` unless disabling code temporarily.

## Current Issues to Fix

### Issue 1: Mixed Styles in Same File

```swift
// File: Orbit.swift
/* Some properties use this */
var property1: Double

/** Others use JavaDoc style */
var property2: Double

// And some use single-line
var property3: Double

/// Only some use proper Swift style
public var property4: Double
```

**Fix:** All public APIs should use `///`

### Issue 2: Missing Documentation

```swift
public var semimajorAxis: Double  // No documentation!
```

**Fix:**
```swift
/// The semi-major axis of the orbital ellipse in kilometers.
public var semimajorAxis: Double
```

### Issue 3: Wrong Comment Style for Public API

```swift
// Wrong: Using // for public API
public func calculate() -> Double
```

**Fix:**
```swift
/// Calculates the orbital parameter.
/// - Returns: The calculated value in appropriate units.
public func calculate() -> Double
```

## Proposed Solution

### Step 1: Define Standards

Create `STYLE_GUIDE.md` section:

```markdown
## Comment Style Guide

### Documentation Comments (`///`)

Use for all public APIs:
- Public structs/classes
- Public properties
- Public methods
- Public initializers
- Protocol requirements

### Section Markers (`// MARK:`)

Use to organize code:
- `// MARK: - Section Name` (with dash for top-level)
- `// MARK: Section Name` (without dash for subsections)

### Implementation Comments (`//`)

Use for:
- Implementation details
- Algorithm explanations
- TODOs and FIXMEs
- Private/internal code

### Avoid

- `/* */` multi-line comments (except for temporarily disabling code)
- `/** */` JavaDoc-style comments
- Missing documentation on public APIs
```

### Step 2: Automated Checking

Add to `.swiftlint.yml`:

```yaml
# Enforce documentation comments
missing_docs:
  severity: warning
  excluded:
    - private
    - internal
    - fileprivate

# Prefer /// over /** */
comment_spacing:
  severity: warning

# Enforce MARK: usage
mark:
  severity: warning
```

### Step 3: Bulk Conversion

Create script `scripts/fix-comments.sh`:

```bash
#!/bin/bash

# Convert /** */ to ///
find Ephemeris -name "*.swift" -exec sed -i '' '
    s|^[[:space:]]*\/\*\*|///|g;
    s|^[[:space:]]*\*\/||g;
    s|^[[:space:]]*\*|///|g;
' {} \;

# Run SwiftLint autocorrect
swiftlint autocorrect

echo "✓ Comments converted to standard style"
```

### Step 4: Manual Review

Review and fix:
1. Ensure all public APIs have `///` docs
2. Add missing documentation
3. Improve existing documentation
4. Verify examples compile

## Examples of Good Style

### Struct Documentation

```swift
/// Represents a satellite orbit using Keplerian elements.
///
/// This struct encapsulates the six classical orbital elements
/// and provides methods for calculating satellite positions.
///
/// Example:
/// ```swift
/// let tle = try TwoLineElement(from: tleString)
/// let orbit = try Orbit(tle: tle)
/// ```
public struct Orbit: Orbitable {
    // MARK: - Properties
    
    /// The semi-major axis in kilometers.
    public let semimajorAxis: Double
    
    // MARK: - Initialization
    
    /// Creates an orbit from a Two-Line Element.
    /// - Parameter tle: The TLE data
    /// - Throws: `OrbitError` if TLE is invalid
    public init(tle: TwoLineElement) throws {
        // Implementation
    }
    
    // MARK: - Public Methods
    
    /// Calculates satellite position at a given time.
    /// - Parameter date: The time for calculation
    /// - Returns: Position in kilometers (x, y, z)
    public func position(at date: Date) -> (x: Double, y: Double, z: Double) {
        // Implementation
    }
    
    // MARK: - Private Helpers
    
    // Calculate mean anomaly from time
    private func calculateMeanAnomaly() -> Double {
        // Implementation
    }
}
```

## Additional Context

- Priority: **Low** - Code style improvement
- Effort: **2-3 hours** (automated + manual review)
- Impact: **High** - Better documentation generation
- Related to: Issue #10 (API documentation), Issue #21 (docs website)

## Benefits

1. **Documentation Generation:** Jazzy can parse properly
2. **Xcode Quick Help:** Shows formatted documentation
3. **Consistency:** One style across codebase
4. **Professionalism:** Follows Swift conventions
5. **Maintainability:** Easier to document new code

## Acceptance Criteria

- [ ] STYLE_GUIDE.md updated with comment standards
- [ ] All public APIs use `///` comments
- [ ] No `/** */` JavaDoc-style comments remain
- [ ] MARK: comments added for code organization
- [ ] SwiftLint rules enforce documentation style
- [ ] Conversion script created
- [ ] All files reviewed and updated
- [ ] Documentation generates correctly with Jazzy
- [ ] Xcode Quick Help displays properly
