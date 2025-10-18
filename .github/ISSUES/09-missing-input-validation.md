---
title: "Add comprehensive input validation for orbital parameters"
labels: ["enhancement", "robustness", "validation"]
---

## Description

The `Orbit` struct currently accepts orbital parameters without validating that they are physically meaningful. This can lead to incorrect calculations, NaN results, or crashes when invalid values are provided.

## Current Behavior

**Location:** `Orbit.swift`

No validation is performed on input parameters such as:
- Eccentricity (should be 0 ≤ e < 1 for elliptical orbits)
- Inclination (should be 0° to 180°)
- Semi-major axis (should be positive and > Earth radius)
- Angles (should be normalized to 0-360° or 0-2π)

**Impact:**
- Silent calculation errors with invalid inputs
- Potential NaN or Inf results
- No feedback to users about invalid data
- Difficult to debug issues

## Expected Behavior

The code should validate all orbital parameters and provide clear error messages:

```swift
public init(semimajorAxis: Double, eccentricity: Double, inclination: Degrees, ...) throws {
    // Validate eccentricity
    guard eccentricity >= 0 && eccentricity < 1 else {
        throw OrbitValidationError.invalidEccentricity(eccentricity)
    }
    
    // Validate semi-major axis
    guard semimajorAxis > PhysicalConstants.earthRadius else {
        throw OrbitValidationError.semimajorAxisBelowEarthRadius(semimajorAxis)
    }
    
    // Validate inclination
    guard (0...180).contains(inclination) else {
        throw OrbitValidationError.invalidInclination(inclination)
    }
    
    // ... additional validations
}
```

## Validation Rules

### Eccentricity
- **Valid range:** 0 ≤ e < 1 (elliptical orbits only)
- **Note:** e = 0 (circular), 0 < e < 1 (elliptical), e ≥ 1 (parabolic/hyperbolic - not supported)

### Semi-major Axis
- **Valid range:** a > Earth radius (6378.137 km)
- **Typical satellite range:** 6500 km to 42,164 km (LEO to GEO)

### Inclination
- **Valid range:** 0° to 180°
- **Common values:** 0° (equatorial), 90° (polar), 98° (sun-synchronous)

### Angles (RAAN, Argument of Perigee, Anomalies)
- **Valid range:** 0° to 360° (or equivalent in radians)
- **Normalization:** Should wrap around at 360°

## Proposed Solution

1. Define `OrbitValidationError` enum with specific cases
2. Make Orbit initializer throwing
3. Add validation for each parameter
4. Provide helpful error messages with valid ranges
5. Add documentation about valid parameter ranges
6. Add tests for boundary conditions and invalid inputs

## Test Cases to Add

```swift
func testInvalidEccentricity() {
    XCTAssertThrowsError(try Orbit(..., eccentricity: -0.1, ...))
    XCTAssertThrowsError(try Orbit(..., eccentricity: 1.5, ...))
}

func testInvalidSemimajorAxis() {
    XCTAssertThrowsError(try Orbit(..., semimajorAxis: 1000, ...)) // Below Earth radius
}

func testInvalidInclination() {
    XCTAssertThrowsError(try Orbit(..., inclination: -10, ...))
    XCTAssertThrowsError(try Orbit(..., inclination: 200, ...))
}
```

## Additional Context

- Affects: `Orbit.swift` initializer
- Related to: Issue #01 (TLE parsing error handling)
- Priority: **Medium** - Prevents calculation errors

## Acceptance Criteria

- [ ] OrbitValidationError enum defined
- [ ] All orbital parameters validated in initializer
- [ ] Initializer made throwing
- [ ] Helpful error messages for each validation failure
- [ ] Documentation added for valid parameter ranges
- [ ] Tests added for all validation cases
- [ ] Demo app updated to handle validation errors
- [ ] README updated with validation examples
