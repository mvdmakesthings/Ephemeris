---
title: "Add guard clause to prevent potential division by zero"
labels: ["bug", "robustness", "edge-cases"]
---

## Description

There is a potential division by zero in the orbital calculations that could result in NaN values or crashes. Specifically, the calculation `acos(zFinal / sqrt(...))` could divide by zero when the denominator is zero or very close to zero.

## Current Behavior

**Location:** `Orbit.swift` (line 135)

```swift
// Potential division by zero when sqrt result is 0
let result = acos(zFinal / sqrt(xFinal * xFinal + yFinal * yFinal + zFinal * zFinal))
```

**Risk Scenarios:**
- When `xFinal`, `yFinal`, and `zFinal` are all zero or near-zero
- Edge cases in orbital calculations
- Extreme orbital parameters

**Impact:**
- Results in NaN (Not a Number)
- Subsequent calculations become invalid
- Silent failure - difficult to debug
- May crash on certain Swift runtime configurations

## Expected Behavior

Add defensive programming with guard clauses:

```swift
let radiusSquared = xFinal * xFinal + yFinal * yFinal + zFinal * zFinal

// Guard against zero or near-zero radius
guard radiusSquared > 1e-10 else {
    throw OrbitCalculationError.degeneratePosition
}

let radius = sqrt(radiusSquared)
let cosValue = zFinal / radius

// Guard against acos domain errors (should be -1 to 1)
let clampedCosValue = max(-1.0, min(1.0, cosValue))
let result = acos(clampedCosValue)
```

## Mathematical Context

The calculation is computing:
```
latitude = acos(z / sqrt(x² + y² + z²))
```

This can fail when:
1. **Division by zero:** radius = sqrt(x² + y² + z²) = 0
2. **Domain error:** acos requires input in range [-1, 1]

## Proposed Solution

1. Check if radius squared is above threshold (e.g., 1e-10)
2. Throw descriptive error if radius is too small
3. Clamp acos input to valid range [-1, 1] (handles floating-point rounding)
4. Add tests for edge cases
5. Document mathematical assumptions

### Implementation

```swift
enum OrbitCalculationError: Error {
    case degeneratePosition
    case invalidRadius(Double)
    case numericalInstability
}

func calculateLatitude(x: Double, y: Double, z: Double) throws -> Double {
    let radiusSquared = x * x + y * y + z * z
    
    // Threshold for numerical stability (1cm)
    let minRadiusSquared = 1e-10
    
    guard radiusSquared > minRadiusSquared else {
        throw OrbitCalculationError.degeneratePosition
    }
    
    let radius = sqrt(radiusSquared)
    
    // Guard against radius below Earth surface
    if radius < PhysicalConstants.earthRadius {
        throw OrbitCalculationError.invalidRadius(radius)
    }
    
    // Clamp to valid acos domain to handle floating point errors
    let cosValue = z / radius
    let clampedCosValue = max(-1.0, min(1.0, cosValue))
    
    return acos(clampedCosValue)
}
```

## Test Cases

```swift
func testZeroPosition() {
    // Should throw error for position at origin
    XCTAssertThrowsError(try calculatePosition(x: 0, y: 0, z: 0))
}

func testNearZeroPosition() {
    // Should throw error for near-zero position
    XCTAssertThrowsError(try calculatePosition(x: 1e-15, y: 1e-15, z: 1e-15))
}

func testAcosDomainClamping() {
    // Test that floating point errors don't cause acos domain errors
    // When cosValue is slightly > 1.0 due to rounding
    let result = try calculateLatitude(x: 0, y: 0, z: 7000.0001)
    XCTAssertNotNaN(result)
}

func testValidPositions() {
    // Normal positions should work
    let lat = try calculateLatitude(x: 6500, y: 0, z: 1000)
    XCTAssertFalse(lat.isNaN)
}
```

## Additional Context

- Affects: `Orbit.swift` position calculation methods
- Related to: Issue #09 (input validation)
- Priority: **Medium** - Edge case bug
- **Impact:** Prevents NaN results and crashes in edge cases

## Numerical Stability Considerations

- Use appropriate epsilon values (1e-10 for km-scale calculations)
- Always clamp acos/asin inputs to valid domain
- Check for NaN/Inf after calculations
- Consider using Swift's `Numeric` protocols for better type safety

## Acceptance Criteria

- [ ] Guard clause added for zero/near-zero radius
- [ ] Acos input clamped to [-1, 1] range
- [ ] Descriptive errors thrown for invalid conditions
- [ ] Tests added for edge cases (zero, near-zero, extreme values)
- [ ] Tests verify NaN never produced
- [ ] Documentation updated with mathematical assumptions
- [ ] Similar issues checked in other calculation methods
