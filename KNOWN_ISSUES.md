# Known Issues

This document tracks known issues in the Ephemeris project that require attention.

## Test Compilation Errors

The test suite currently has compilation errors that prevent tests from running. These are **pre-existing issues** from before the SPM migration and need to be fixed:

### 1. DateTests.swift - Optional Unwrapping Issues

**Location:** `EphemerisTests/DateTests.swift`

**Issue:** Multiple test methods are trying to pass an optional `JulianDay?` to `XCTAssertEqual` which expects a non-optional `Double`.

**Affected Tests:**
- `testJulianDayFromDateJ2000()`
- `testJulianDayFromDateUnixEpoch()`
- `testJulianDayHistoricalDate()`
- `testJulianDayFutureDate()`

**Example Error:**
```
error: cannot convert value of type 'JulianDay?' (aka 'Optional<Double>') to expected argument type 'Double'
XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
               ^~~~~~~~~
```

**Suggested Fix:**
Unwrap the optional properly or update the test to handle the optional return value:
```swift
// Option 1: Force unwrap (if we know it should never be nil)
XCTAssertEqual(julianDay!, knownJulianDay, accuracy: 0.000001)

// Option 2: Guard unwrap (better error messaging)
guard let julianDay = Date.julianDay(from: date) else {
    XCTFail("Failed to calculate Julian Day")
    return
}
XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
```

### 2. OrbitalCalculationTests.swift - Missing try Keyword

**Location:** `EphemerisTests/OrbitalCalculationTests.swift`

**Issue:** Test calls a throwing function without using `try` keyword.

**Affected Test:**
- `testOrbitConformsToOrbitable()`

**Example Error:**
```
error: call can throw but is not marked with 'try'
let tle = MockTLEs.ISSSample()
          ^~~~~~~~~~~~~~~~~~~
```

**Suggested Fix:**
Add the `try` keyword to the throwing function call:
```swift
func testOrbitConformsToOrbitable() throws {
    // Test that Orbit struct properly conforms to Orbitable protocol
    let tle = try MockTLEs.ISSSample()  // Add 'try' here
    let orbit = Orbit(from: tle)
    // ... rest of test
}
```

## Workaround

The GitHub Actions workflow currently has `continue-on-error: true` for the test step to allow CI to pass while these issues are being addressed. Once the tests are fixed, this should be removed to ensure test failures block CI.

## Resolution Plan

1. Fix the optional unwrapping in DateTests.swift
2. Add try keyword in OrbitalCalculationTests.swift
3. Verify all tests pass
4. Remove `continue-on-error: true` from the workflow
5. Delete this document once all issues are resolved

## Related Issues

- See `.github/ISSUES/15-expand-test-coverage.md` for test coverage improvements
- See `.github/ISSUES/14-empty-test-file.md` for empty test file cleanup

---

**Last Updated:** 2025-10-19  
**Status:** Open - Needs fixing
