---
title: "Consider removing TwoLineElement coupling from Orbit struct"
labels: ["architecture", "refactoring", "technical-debt"]
---

## Description

The `Orbit` struct stores a `TwoLineElement` instance privately but only uses it during initialization. This creates unnecessary coupling between the two types and increases memory usage.

## Current Behavior

**Location:** `Orbit.swift`

```swift
public struct Orbit: Orbitable {
    private let tle: TwoLineElement  // Stored but not used after init
    
    public init(tle: TwoLineElement) {
        self.tle = tle
        // Extract orbital elements from TLE
        self.semimajorAxis = calculateSemimajorAxis(from: tle)
        self.eccentricity = tle.eccentricity
        // ... etc
    }
}
```

**Issues:**
- TLE is stored but never accessed after initialization
- Increases memory footprint unnecessarily
- Creates coupling between Orbit and TLE format
- Orbit should be format-agnostic

## Expected Behavior

The `Orbit` struct should only store computed orbital elements, not the source data format:

```swift
public struct Orbit: Orbitable {
    // No TLE stored - just orbital elements
    public let semimajorAxis: Double
    public let eccentricity: Double
    // ... other elements
    
    public init(tle: TwoLineElement) {
        // Extract elements but don't store TLE
        self.semimajorAxis = Self.calculateSemimajorAxis(from: tle)
        self.eccentricity = tle.eccentricity
        // ... etc
    }
}
```

## Architectural Benefits

### Better Separation of Concerns
- **TwoLineElement:** Parsing and data format representation
- **Orbit:** Orbital mechanics and calculations
- These concerns should be separated

### Reduced Memory Usage
- TLE data: ~200 bytes (strings, metadata)
- Orbital elements only: ~100 bytes (doubles)
- **Savings:** ~50% memory reduction per orbit

### Format Independence
Orbit could be initialized from:
- TLE format (current)
- OMNI format
- JSON/XML APIs
- Manual parameters
- Database records

Without coupling to any specific format.

## Alternative Approaches

### Option 1: Remove TLE Storage (Recommended)

```swift
public struct Orbit: Orbitable {
    // Only store computed elements
    public let semimajorAxis: Double
    public let eccentricity: Double
    // ...
    
    public init(tle: TwoLineElement) {
        self.semimajorAxis = Self.calculateSemimajorAxis(from: tle)
        // ... initialize from TLE
    }
    
    public init(semimajorAxis: Double, eccentricity: Double, ...) {
        self.semimajorAxis = semimajorAxis
        // ... direct initialization
    }
}
```

### Option 2: Make TLE Optional

```swift
public struct Orbit: Orbitable {
    public let tle: TwoLineElement?  // Optional for debugging/reference
    
    public init(tle: TwoLineElement) {
        self.tle = tle  // Store for reference
        // ...
    }
}
```

### Option 3: Create Separate Types

```swift
// Orbit with just elements
public struct Orbit: Orbitable {
    // Just orbital elements
}

// Orbit with source data
public struct ObservedOrbit {
    public let orbit: Orbit
    public let source: TwoLineElement
}
```

## Considerations

### Pros of Removing TLE
- ✅ Reduced memory usage
- ✅ Better separation of concerns
- ✅ Format independence
- ✅ Cleaner architecture

### Cons of Removing TLE
- ❌ Can't reference original TLE data
- ❌ Lose satellite name and catalog number
- ❌ Can't regenerate TLE from Orbit

### Recommendation
Remove TLE storage. If users need to keep TLE data, they can maintain the association themselves:

```swift
struct SatelliteData {
    let tle: TwoLineElement
    let orbit: Orbit
    
    init(tle: TwoLineElement) {
        self.tle = tle
        self.orbit = Orbit(tle: tle)
    }
}
```

## Proposed Solution

1. Remove `private let tle: TwoLineElement` from Orbit
2. Extract all needed data during initialization
3. Add convenience initializer with individual parameters
4. Update tests
5. Update demo app if needed
6. Document in migration guide

## Additional Context

- Affects: `Orbit.swift`
- Priority: **Low** - Architectural improvement, not a bug
- Related to: Clean architecture principles
- **Note:** This would be a breaking change if TLE is used elsewhere

## Acceptance Criteria

- [ ] TLE reference removed from Orbit struct (or made optional)
- [ ] Memory usage measured and reduced
- [ ] All tests still pass
- [ ] Demo app updated if necessary
- [ ] Alternative initializer added for direct element input
- [ ] Documentation explains architectural decision
- [ ] Migration guide for users who need TLE reference
