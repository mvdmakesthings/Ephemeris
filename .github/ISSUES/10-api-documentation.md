---
title: "Add comprehensive Swift documentation comments to public APIs"
labels: ["documentation", "enhancement", "good-first-issue"]
---

## Description

Many public methods and properties in the Ephemeris framework lack comprehensive Swift documentation comments (`///`). This makes it difficult for users to understand how to use the API correctly without reading the source code.

## Current Behavior

**Example:** Many properties lack documentation

```swift
// Orbit.swift
public struct Orbit {
    public let semimajorAxis: Double  // No documentation
    public let eccentricity: Double   // No documentation
    public let inclination: Degrees   // No documentation
    // ...
}
```

**Impact:**
- Users don't know what units are used (km, degrees, radians)
- Parameter ranges are unclear
- Physical meaning not explained
- No Xcode quick help available
- Difficult for new contributors

## Expected Behavior

All public APIs should have comprehensive documentation:

```swift
/// The semi-major axis of the orbital ellipse in kilometers.
///
/// This represents half of the longest diameter of the orbital ellipse.
/// For Earth satellites, typical values range from:
/// - LEO (Low Earth Orbit): 6,500 - 8,000 km
/// - MEO (Medium Earth Orbit): 20,000 - 30,000 km  
/// - GEO (Geostationary Orbit): ~42,164 km
///
/// - Note: Must be greater than Earth's radius (6,378.137 km)
public let semimajorAxis: Double

/// The eccentricity of the orbital ellipse (dimensionless).
///
/// Describes the shape of the orbit:
/// - `e = 0`: Perfect circle
/// - `0 < e < 1`: Ellipse (supported)
/// - `e = 1`: Parabola (not supported)
/// - `e > 1`: Hyperbola (not supported)
///
/// For Earth satellites, typical values are 0.0001 to 0.7.
///
/// - Note: Must be in range [0, 1)
public let eccentricity: Double

/// The inclination of the orbital plane in degrees.
///
/// Measured from the equatorial plane:
/// - `0°`: Equatorial orbit
/// - `90°`: Polar orbit
/// - `98°`: Sun-synchronous orbit (typical)
///
/// - Note: Valid range is 0° to 180°
public let inclination: Degrees
```

## Documentation Standards

### Required Elements

1. **Summary line:** Brief description (one line)
2. **Description:** Detailed explanation
3. **Physical meaning:** What does this represent?
4. **Units:** Always specify (km, degrees, radians, seconds, etc.)
5. **Valid ranges:** What values are acceptable?
6. **Typical values:** Examples for context
7. **Related properties:** Cross-references
8. **Notes/Warnings:** Special considerations

### Swift Documentation Syntax

```swift
/// Summary line
///
/// Detailed description
/// can span multiple lines.
///
/// - Parameters:
///   - paramName: Description with units
///   - anotherParam: Description
///
/// - Returns: Description of return value with units
///
/// - Throws: Description of error conditions
///
/// - Note: Special considerations
/// - Warning: Important warnings
/// - Important: Critical information
///
/// - SeeAlso: `RelatedClass`, `relatedMethod()`
///
/// Example usage:
/// ```swift
/// let orbit = Orbit(...)
/// ```
```

## Files Requiring Documentation

1. **Orbit.swift** - All properties and methods
2. **Orbitable.swift** - Protocol requirements
3. **TwoLineElement.swift** - Properties and initializer
4. **PhysicalConstants.swift** - All constants with units
5. **Date+julian.swift** - Extension methods
6. **Utilities/** - All extension methods

## Proposed Approach

### Phase 1: Core Types
- Document `Orbit` struct (all 20+ properties)
- Document `TwoLineElement` struct
- Document `Orbitable` protocol

### Phase 2: Extensions
- Document `Double` extensions (angle conversions)
- Document `Date` extensions (Julian date)
- Document utility extensions

### Phase 3: Constants
- Document all physical constants with references
- Add units to all constant names or documentation

## Good First Issue

This is excellent for new contributors:
- Clear task with examples
- Learn about orbital mechanics
- No complex code changes
- Can be done incrementally
- Low risk of breaking changes

**Suggested approach for contributors:**
1. Pick one file to start with
2. Document 5-10 properties/methods
3. Submit PR for review
4. Iterate based on feedback

## References

- [Swift Documentation](https://swift.org/documentation/api-design-guidelines/#document-your-code)
- [NSHipster Documentation](https://nshipsster.com/swift-documentation/)
- [Orbital Elements](https://en.wikipedia.org/wiki/Orbital_elements)

## Acceptance Criteria

- [ ] All public structs documented
- [ ] All public properties documented with units
- [ ] All public methods documented
- [ ] All protocol requirements documented
- [ ] All parameters include units where applicable
- [ ] All return values documented
- [ ] Examples added for complex APIs
- [ ] Physical meaning explained for orbital elements
- [ ] Cross-references added between related APIs
- [ ] Xcode quick help shows useful information
