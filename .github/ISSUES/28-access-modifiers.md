---
title: "Add explicit access modifiers to all declarations"
labels: ["code-quality", "good-first-issue", "api-design"]
---

## Description

Some properties and methods in the codebase lack explicit access modifiers (`public`, `internal`, `private`, `fileprivate`). While Swift defaults to `internal`, being explicit improves code clarity and intentionality.

## Current Behavior

**Location:** `TwoLineElement.swift` and other files

```swift
// No access modifier - defaults to internal
let catalogNumber: Int

// Some are explicitly public
public let eccentricity: Double

// Mixed approach in same struct
struct TwoLineElement {
    let implicitInternal: String  // No modifier
    public let explicitPublic: String  // Explicit
    private let explicitPrivate: String  // Explicit
}
```

**Impact:**
- Unclear API surface
- Difficult to know what's public vs internal
- Can't easily see intended visibility
- May accidentally expose internal details

## Expected Behavior

All declarations should have explicit access modifiers:

```swift
public struct TwoLineElement {
    // Public properties (part of API)
    public let catalogNumber: Int
    public let eccentricity: Double
    
    // Internal properties (for framework use)
    internal let checksum: Int
    
    // Private properties (implementation details)
    private let rawLine1: String
    private let rawLine2: String
}
```

## Swift Access Control Levels

### `public`
- Accessible from other modules
- Use for framework's public API

```swift
public struct Orbit {
    public let semimajorAxis: Double
    public func position(at: Date) -> (x: Double, y: Double, z: Double)
}
```

### `internal` (default)
- Accessible within the module
- Use for framework internal helpers

```swift
internal struct TLEParser {
    internal func parseField(_ field: String) -> Double?
}
```

### `fileprivate`
- Accessible within the same file
- Use for file-scoped helpers

```swift
fileprivate extension String {
    func extractField(_ range: Range<Int>) -> String
}
```

### `private`
- Accessible only within the declaration
- Use for implementation details

```swift
public class Orbit {
    private var cachedPosition: (x: Double, y: Double, z: Double)?
    private func invalidateCache()
}
```

## Current Issues

### Issue 1: Mixed Modifiers in TwoLineElement

```swift
public struct TwoLineElement {
    let catalogNumber: Int  // Should be public or private?
    public let eccentricity: Double  // Explicitly public
    let classification: String  // Should be public or private?
}
```

**Decision needed:** Which properties should be public?

### Issue 2: No Modifiers on Extensions

```swift
extension Double {
    func toRadians() -> Double  // Should be internal or public?
}
```

### Issue 3: Helper Functions Visibility Unclear

```swift
// Utilities/Helpers.swift
func calculateChecksum(_ line: String) -> Int  // Should be internal or private?
```

## Proposed Solution

### Step 1: Audit All Declarations

```bash
# Find declarations without access modifiers
grep -r "^\s*var " Ephemeris/ | grep -v "private\|internal\|public\|fileprivate"
grep -r "^\s*let " Ephemeris/ | grep -v "private\|internal\|public\|fileprivate"
grep -r "^\s*func " Ephemeris/ | grep -v "private\|internal\|public\|fileprivate"
grep -r "^\s*struct " Ephemeris/ | grep -v "private\|internal\|public\|fileprivate"
grep -r "^\s*class " Ephemeris/ | grep -v "private\|internal\|public\|fileprivate"
```

### Step 2: Define Guidelines

Create `STYLE_GUIDE.md` section:

```markdown
## Access Control Guidelines

### General Rules

1. **Always use explicit access modifiers**
2. **Default to most restrictive** (private → fileprivate → internal → public)
3. **Public:** Only what users need
4. **Internal:** Framework helpers
5. **Private:** Implementation details

### Framework Public API

Make public:
- ✅ Core types (Orbit, TwoLineElement)
- ✅ Protocol requirements
- ✅ Public initializers
- ✅ User-facing methods
- ✅ Essential properties

Keep internal/private:
- ❌ Helper functions
- ❌ Implementation details
- ❌ Cached values
- ❌ Temporary calculations
```

### Step 3: Categorize Each Declaration

For TwoLineElement, decide visibility:

```swift
public struct TwoLineElement {
    // Public - part of API (users need these)
    public let name: String
    public let catalogNumber: Int
    public let eccentricity: Double
    public let inclination: Degrees
    public let rightAscensionOfAscendingNode: Degrees
    public let argumentOfPerigee: Degrees
    public let meanAnomaly: Degrees
    
    // Internal - used by Orbit but not needed by users
    internal let meanMotion: Double
    internal let epochYear: Int
    internal let epochDay: Double
    
    // Private - implementation details
    private let line1Checksum: Int
    private let line2Checksum: Int
    private let rawData: String
}
```

### Step 4: Apply Modifiers

Use this order of preference:
1. Start with `private`
2. If needed elsewhere in struct → keep `private`
3. If needed in file → `fileprivate`
4. If needed in framework → `internal`
5. If needed by users → `public`

### Step 5: Add SwiftLint Rule

Update `.swiftlint.yml`:

```yaml
explicit_acl:
  severity: warning

explicit_top_level_acl:
  severity: error
```

## Examples of Good Access Control

### Framework Type

```swift
/// Public API for orbital calculations
public struct Orbit: Orbitable {
    // MARK: - Public Properties
    
    /// Orbital elements (public - users need these)
    public let semimajorAxis: Double
    public let eccentricity: Double
    
    // MARK: - Internal Properties
    
    /// Cache for calculations (internal - framework only)
    internal var calculationCache: [String: Double] = [:]
    
    // MARK: - Private Properties
    
    /// Internal state (private - implementation detail)
    private var lastCalculationDate: Date?
    
    // MARK: - Public Methods
    
    /// Calculate position (public API)
    public func position(at date: Date) -> (x: Double, y: Double, z: Double) {
        calculatePosition(date)
    }
    
    // MARK: - Internal Helpers
    
    /// Helper for position calculation (internal)
    internal func calculateMeanAnomaly(at date: Date) -> Double {
        // Implementation
    }
    
    // MARK: - Private Helpers
    
    /// Clear cache (private)
    private func invalidateCache() {
        calculationCache.removeAll()
    }
}
```

### Utility Extension

```swift
// Public utilities users might need
public extension Double {
    /// Convert degrees to radians
    public func toRadians() -> Radians {
        self * .pi / 180.0
    }
}

// Internal utilities for framework only
internal extension String {
    /// Extract TLE field (internal helper)
    internal func extractTLEField(_ range: Range<Int>) -> String? {
        // Implementation
    }
}
```

## Migration Strategy

### Non-Breaking Approach

1. Add modifiers to internal/private things first
2. For existing public items, keep them public
3. Document in CHANGELOG as "clarification, not breaking change"

### If Breaking Changes Needed

1. Mark old API as deprecated
2. Introduce new API with correct visibility
3. Provide migration guide
4. Remove in next major version

## Additional Context

- Priority: **Low** - Code quality improvement
- Effort: **2-3 hours** (audit + apply)
- Impact: **Medium** - Clearer API boundaries
- Breaking change: **Potentially** (if removing unintended public API)

## Benefits

1. **Clarity:** Obvious what's public API vs internal
2. **Encapsulation:** Better information hiding
3. **Maintainability:** Can change private things freely
4. **Documentation:** Clear API surface
5. **Intentionality:** Explicit design decisions

## Acceptance Criteria

- [ ] All declarations have explicit access modifiers
- [ ] Public API clearly defined
- [ ] Internal helpers marked internal
- [ ] Private implementation details marked private
- [ ] STYLE_GUIDE.md updated with guidelines
- [ ] SwiftLint rules enforce explicit modifiers
- [ ] API documentation reflects actual visibility
- [ ] Tests still pass
- [ ] No unintended breaking changes
- [ ] Migration guide provided if breaking changes exist
