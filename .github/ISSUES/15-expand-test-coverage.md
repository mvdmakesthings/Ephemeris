---
title: "Expand test coverage for edge cases and error conditions"
labels: ["testing", "quality"]
---

## Description

The current test suite has good coverage for happy path scenarios but lacks tests for edge cases, error conditions, and boundary values. This leaves potential bugs undetected.

## Current Coverage Gaps

### 1. TLE Parsing Error Cases
**File:** No tests in `TwoLineElementTests.swift`

Missing tests for:
- Malformed TLE strings (wrong number of lines)
- Invalid numbers in TLE fields
- Out-of-range values (e.g., inclination > 180°)
- Empty or null strings
- Special characters in TLE data
- Truncated lines
- Incorrect checksums

### 2. Orbital Calculation Edge Cases
**File:** `OrbitalCalculationTests.swift` has minimal tests

Missing tests for:
- Eccentricity at boundaries (0, 1, >1)
- Very high and very low orbits
- Convergence failure in eccentric anomaly calculation
- Division by zero scenarios
- NaN/Infinity handling
- Extreme inclinations (0°, 90°, 180°)

### 3. Date Conversion Edge Cases
**File:** `DateTests.swift` has good coverage but could expand

Could add:
- Leap year handling
- Leap seconds (if supported)
- Very old dates (pre-1970)
- Very future dates (>2100)
- DST transitions (though should be UTC)
- Epoch day fractions at boundaries

### 4. Position Calculation Accuracy
**File:** No comprehensive position tests

Missing:
- Known satellite position validation
- Ground truth comparison
- Accuracy over time
- Multiple orbit types (LEO, GEO, HEO)

### 5. Empty Test File
**File:** `MathTests.swift` is completely empty

Either:
- Remove the file (see Issue #8)
- Or add tests if Math utilities are implemented

## Proposed Test Additions

### TLE Parsing Errors

```swift
func testTLEParsingWithInsufficientLines() {
    let tleString = """
        ISS (ZARYA)
        1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
        """
    
    XCTAssertThrowsError(try TwoLineElement(from: tleString))
}

func testTLEParsingWithInvalidNumber() {
    let tleString = """
        ISS (ZARYA)
        1 XXXXX 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
        2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
        """
    
    XCTAssertThrowsError(try TwoLineElement(from: tleString))
}

func testTLEParsingWithOutOfRangeInclination() {
    let tleString = """
        INVALID
        1 12345U 00055A   20116.52380576 -.00000007  00000-0  19116-4 0  9998
        2 12345  200.0000 186.8634 0009660 233.4374 126.5910 14.13250159306768
        """
    
    // Should either throw or handle gracefully
    // Depends on validation implementation
}
```

### Orbital Calculation Edge Cases

```swift
func testCalculateTrueAnomalyWithEccentricityOne() {
    let eccentricity = 1.0 // Parabolic orbit
    
    XCTAssertThrowsError(try Orbit.calculateTrueAnomaly(
        eccentricity: eccentricity, 
        eccentricAnomaly: 30.0
    )) { error in
        XCTAssertEqual(error as? CalculationError, .reachedSingularity)
    }
}

func testCalculateEccentricAnomalyConvergence() {
    // Test with very high eccentricity
    let anomaly = Orbit.calculateEccentricAnomaly(
        eccentricity: 0.99,
        meanAnomaly: 180.0,
        accuracy: 0.00001,
        maxIterations: 500
    )
    
    XCTAssertFalse(anomaly.isNaN)
    XCTAssertFalse(anomaly.isInfinite)
}

func testCalculateEccentricAnomalyMaxIterations() {
    // Test that it doesn't hang with insufficient iterations
    let anomaly = Orbit.calculateEccentricAnomaly(
        eccentricity: 0.95,
        meanAnomaly: 180.0,
        accuracy: 0.000000001, // Very tight accuracy
        maxIterations: 5 // Very few iterations
    )
    
    // Should complete, but may not reach desired accuracy
    XCTAssertFalse(anomaly.isNaN)
}

func testCircularOrbit() {
    // Test with zero eccentricity (circular orbit)
    let anomaly = Orbit.calculateEccentricAnomaly(
        eccentricity: 0.0,
        meanAnomaly: 45.0
    )
    
    XCTAssertEqual(anomaly, 45.0, accuracy: 0.001)
}
```

### Position Calculation Validation

```swift
func testPositionCalculationForKnownSatellite() {
    // Use known position data for validation
    // Example: ISS position at specific time
    let tleString = """
        ISS (ZARYA)
        1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
        2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
        """
    
    let tle = TwoLineElement(from: tleString)
    let orbit = Orbit(from: tle)
    
    // Calculate position at epoch
    let epochDate = Date(timeIntervalSince1970: ...) // Convert epoch to Date
    let position = try orbit.calculatePosition(at: epochDate)
    
    // Validate against known position (from reference implementation)
    XCTAssertEqual(position.x, expectedLat, accuracy: 0.1) // Within 0.1 degrees
    XCTAssertEqual(position.y, expectedLon, accuracy: 0.1)
    XCTAssertEqual(position.z, expectedAlt, accuracy: 1.0) // Within 1 km
}

func testPositionCalculationConsistency() {
    // Test that same time gives same result
    let tle = MockTLEs.ISSSample()
    let orbit = Orbit(from: tle)
    let date = Date()
    
    let position1 = try orbit.calculatePosition(at: date)
    let position2 = try orbit.calculatePosition(at: date)
    
    XCTAssertEqual(position1.x, position2.x)
    XCTAssertEqual(position1.y, position2.y)
    XCTAssertEqual(position1.z, position2.z)
}
```

### Double Extension Tests

```swift
func testRadianDegreesConversion() {
    let degrees = 180.0
    let radians = degrees.inRadians()
    XCTAssertEqual(radians, .pi, accuracy: 0.000001)
    
    let backToDegrees = radians.inDegrees()
    XCTAssertEqual(backToDegrees, 180.0, accuracy: 0.000001)
}

func testRoundingEdgeCases() {
    XCTAssertEqual(0.0.round(to: 2), 0.0)
    XCTAssertEqual((-1.234).round(to: 2), -1.23)
    XCTAssertEqual(1.999.round(to: 2), 2.0)
}
```

## Testing Strategy

### Levels of Testing

1. **Unit Tests** (current focus)
   - Individual function testing
   - Edge cases and boundaries
   - Error conditions

2. **Integration Tests** (future)
   - Full TLE → Position workflow
   - Multiple calculations in sequence

3. **Property-Based Tests** (future consideration)
   - Use Swift Testing or similar
   - Generate random valid inputs
   - Verify invariants

### Test Data Sources

- Real satellite TLEs from Celestrak
- Known position data from:
  - NASA HORIZONS system
  - PyEphem or Skyfield (Python)
  - Other validated satellite tracking software

## Related Issues

- Issue #1 (TLE error handling - enables error testing)
- Issue #14 (Empty MathTests.swift)

## Priority

**Medium** - Important for quality but not blocking

## Acceptance Criteria

- [ ] Tests added for TLE parsing error cases
- [ ] Tests added for orbital calculation edge cases
- [ ] Tests added for boundary conditions
- [ ] Tests added for error handling
- [ ] Position calculation validated against known data
- [ ] Code coverage increased by at least 10%
- [ ] All new tests pass
- [ ] Existing tests still pass

## Notes

- Add tests incrementally as issues are fixed
- Issue #1 (error handling) enables many error tests
- Consider using XCTest's `XCTAssertThrowsError` for error validation
- Mock data in `MockTLEs.swift` can be expanded
