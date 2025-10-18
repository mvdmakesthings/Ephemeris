---
title: "Establish consistent naming conventions across codebase"
labels: ["code-style", "refactoring", "maintainability"]
---

## Description

The codebase has inconsistent naming conventions, mixing abbreviations with full names. This reduces code readability and makes the API harder to understand.

## Current Behavior

**Examples of inconsistency:**

```swift
// Abbreviations
let GST: Double  // Greenwich Sidereal Time
let GMST: Double  // Greenwich Mean Sidereal Time

// Full names
var greenwichSiderealTime: Double
var greenwichMeanSiderealTime: Double

// Mixed in same file
func calculateGST() -> Double
func calculateGreenwichSiderealTime() -> Double
```

**Impact:**
- Confusing for users (which name to use?)
- Difficult to search codebase
- Inconsistent documentation
- Harder to maintain

## Expected Behavior

Consistent naming convention throughout:

### Option 1: Prefer Full Names (Recommended)

```swift
// Clear and self-documenting
var greenwichSiderealTime: Double
var greenwichMeanSiderealTime: Double
var julianDate: Double
var trueAnomaly: Degrees
```

**Pros:**
- Self-documenting code
- Better for newcomers
- Clearer in autocomplete
- More searchable

**Cons:**
- Longer names
- More verbose

### Option 2: Prefer Abbreviations

```swift
// Concise but requires domain knowledge
var GST: Double  // Greenwich Sidereal Time
var GMST: Double  // Greenwich Mean Sidereal Time
var JD: Double  // Julian Date
var TA: Degrees  // True Anomaly
```

**Pros:**
- Shorter code
- Matches academic papers
- Familiar to domain experts

**Cons:**
- Requires documentation
- Harder for beginners
- Not self-documenting

### Option 3: Mixed Approach

```swift
// Abbreviations for well-known terms
var tle: TwoLineElement  // TLE is universal
var raan: Degrees  // Right Ascension of Ascending Node

// Full names for less common terms
var greenwichSiderealTime: Double
var argumentOfPerigee: Degrees
```

## Analysis of Current Issues

### Issue 1: Time Variables

```swift
// Found in Date extensions
var GST: Double
var greenwichSiderealTime: Double
// Which should be used?
```

**Recommendation:** Use `greenwichSiderealTime` (full name)

### Issue 2: Orbital Elements

```swift
// Protocol uses full names
protocol Orbitable {
    var rightAscensionOfAscendingNode: Degrees { get }
}

// But some code uses abbreviations
let RAAN = orbit.rightAscensionOfAscendingNode
```

**Recommendation:** Stick with full names in protocol, allow local abbreviations

### Issue 3: Constants

```swift
// PhysicalConstants.swift
static let mu: Double  // Gravitational parameter
static let gravitationalParameter: Double
```

**Recommendation:** Choose one and use consistently

## Proposed Solution

### Naming Guidelines

Create `STYLE_GUIDE.md` section on naming:

```markdown
## Naming Conventions

### Variables and Properties

**Prefer full, descriptive names:**
- ✅ `greenwichSiderealTime`
- ❌ `GST`

**Exception: Universal abbreviations:**
- ✅ `tle` (Two-Line Element)
- ✅ `url`, `id`, `uuid`

### Academic Terms

For orbital mechanics terms, use full names in public API:

| Term | Use | Avoid |
|------|-----|-------|
| Right Ascension of Ascending Node | `rightAscensionOfAscendingNode` | `RAAN` |
| Greenwich Sidereal Time | `greenwichSiderealTime` | `GST` |
| Julian Date | `julianDate` | `JD` |
| True Anomaly | `trueAnomaly` | `TA` |

**Internal/private:** Abbreviations OK if documented
```

### Refactoring Plan

#### Phase 1: Audit (1-2 hours)

```bash
# Find all abbreviations
grep -r "var [A-Z][A-Z]" Ephemeris/
grep -r "let [A-Z][A-Z]" Ephemeris/

# Create inventory of inconsistencies
```

#### Phase 2: Categorize (1 hour)

Categorize each abbreviation:
1. **Keep:** Universal terms (TLE, URL)
2. **Expand:** Domain-specific terms (GST → greenwichSiderealTime)
3. **Deprecate:** Provide both, mark old as deprecated

#### Phase 3: Refactor (4-6 hours)

For each name to change:

```swift
// Before
var GST: Double

// After (with deprecation period)
@available(*, deprecated, renamed: "greenwichSiderealTime")
var GST: Double { greenwichSiderealTime }

var greenwichSiderealTime: Double
```

#### Phase 4: Update Documentation (2 hours)

- Update all documentation
- Update README examples
- Update code comments
- Add to CHANGELOG

## Examples of Good Naming

### From Apple Frameworks

```swift
// Apple uses full names
var contentInsetAdjustmentBehavior  // Not: CIAB
var safeAreaLayoutGuide  // Not: SALG
var interfaceOrientation  // Not: IO
```

### From Successful Libraries

```swift
// Alamofire
var httpHeaders: HTTPHeaders  // Not: headers
var httpMethod: HTTPMethod  // Not: method

// SwiftUI
var horizontalSizeClass  // Not: HSC
var verticalSizeClass  // Not: VSC
```

## Migration Strategy

### For Breaking Changes

Use deprecation warnings:

```swift
extension Orbit {
    @available(*, deprecated, message: "Use 'rightAscensionOfAscendingNode' instead")
    var RAAN: Degrees {
        rightAscensionOfAscendingNode
    }
    
    var rightAscensionOfAscendingNode: Degrees
}
```

### For Non-Breaking Changes

Internal refactoring without API changes:

```swift
// Private properties can be renamed freely
private var gmst: Double  // Internal abbreviation OK

// Public API uses full name
public var greenwichMeanSiderealTime: Double {
    gmst
}
```

## Additional Context

- Priority: **Low** - Code quality improvement
- Effort: **8-10 hours** (full refactoring)
- Impact: **Moderate** - Better readability
- Breaking change: **Potentially** (use deprecation)

## Benefits

1. **Readability:** Code is self-documenting
2. **Discoverability:** Easier to find in autocomplete
3. **Maintainability:** Clear what each variable represents
4. **Professionalism:** Consistent with Apple's guidelines
5. **Onboarding:** Easier for new contributors

## Acceptance Criteria

- [ ] STYLE_GUIDE.md created with naming conventions
- [ ] Naming audit completed
- [ ] Inconsistencies documented
- [ ] Refactoring plan approved
- [ ] Public API names made consistent
- [ ] Deprecated names marked appropriately
- [ ] Documentation updated
- [ ] Migration guide provided
- [ ] All tests updated
- [ ] README examples updated
