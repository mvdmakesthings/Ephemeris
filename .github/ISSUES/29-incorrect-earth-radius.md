---
title: "Fix incorrect Earth radius value"
labels: ["bug", "high-priority", "correctness"]
---

## Description

The code currently uses an incorrect Earth radius value of 6370 km, while the WGS84 standard specifies 6378.137 km. This discrepancy causes position calculation errors of approximately 8 kilometers.

## Current Behavior

**Location:** `Orbit.swift` (line 134)

```swift
let earthRadius = 6370.0 // Incorrect value
```

**Impact:**
- Position calculations are inaccurate by ~8 km
- Violates WGS84 geodetic standard
- Inconsistent with PhysicalConstants.swift which has the correct value
- Affects all altitude and position computations

## Expected Behavior

The code should use the WGS84 standard Earth radius from PhysicalConstants:

```swift
let earthRadius = PhysicalConstants.earthRadius // 6378.137 km (WGS84)
```

## Related Issues

This is related to Issue #02 (Inconsistent Physical Constants), as it's another instance of inconsistent physical constant usage.

## Steps to Reproduce

1. Calculate satellite position using current code
2. Compare with reference implementation using WGS84 standard
3. Observe ~8 km discrepancy in calculated positions

## Proposed Solution

1. Remove hardcoded `6370.0` value from Orbit.swift
2. Use `PhysicalConstants.earthRadius` instead
3. Verify `PhysicalConstants.earthRadius` is set to `6378.137` (WGS84 equatorial radius)
4. Update tests to use correct Earth radius
5. Add validation tests comparing against known satellite positions

## Additional Context

**WGS84 Standard Values:**
- Equatorial radius: 6378.137 km
- Polar radius: 6356.752 km
- Mean radius: 6371.0 km

The code should consistently use the equatorial radius (6378.137 km) for all calculations unless specifically computing polar or mean radius.

**References:**
- WGS84: https://en.wikipedia.org/wiki/World_Geodetic_System
- NIST: https://www.nist.gov/pml/special-publication-811

## Acceptance Criteria

- [ ] Hardcoded 6370.0 value removed from Orbit.swift
- [ ] Code uses PhysicalConstants.earthRadius consistently
- [ ] PhysicalConstants.earthRadius verified to be 6378.137 km
- [ ] Tests updated with correct Earth radius value
- [ ] Position calculations tested against reference data
- [ ] Documentation updated to reflect WGS84 standard usage
