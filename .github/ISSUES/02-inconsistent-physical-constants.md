---
title: "Consolidate inconsistent physical constants"
labels: ["bug", "high-priority"]
---

## Description

Earth's physical constants are defined inconsistently across the codebase, leading to potential calculation errors and maintenance issues.

## Current Issues

### 1. Gravitational Constant Inconsistency

**Location:** `Orbit.swift` line 165
```swift
let earthsGravitationalConstant = 398613.52 // km (WRONG UNITS!)
```

**Location:** `PhysicalConstants.swift` line 23
```swift
public static let µ: Double = 3.986004418 * pow(10, 14) / 1000 // km³/s²
```

The value in `Orbit.swift` has incorrect unit annotation and differs from the standard WGS84 value.

### 2. Earth Radius Inconsistency

**Location:** `Orbit.swift` line 134
```swift
let earthsRadius = 6370.0 //km
```

**Location:** `PhysicalConstants.swift` line 27
```swift
public static let radius: Double = 6378137.0 / 1000 // 6378.137 km (WGS84)
```

The value in `Orbit.swift` is 8.137 km less than the WGS84 standard, which could result in position calculation errors of ~8 km.

### 3. Seconds Per Day Magic Number

**Location:** `Orbit.swift` line 166
```swift
let motionRadsPerSecond = meanMotion / 86400
```

**Location:** `Date.swift` line 50
```swift
let totalSeconds = ... / 86400.0
```

The constant `86400` (seconds per day) appears multiple times without being defined as a named constant.

## Impact

- **Calculation Accuracy:** Position calculations may be off by several kilometers
- **Maintainability:** Changes require updating multiple locations
- **Confusion:** Different values for same physical quantities
- **Standards Compliance:** Not following WGS84 standard consistently

## Proposed Solution

### 1. Add missing constants to PhysicalConstants.swift

```swift
public struct PhysicalConstants {
    public struct Earth {
        // Existing constants...
        
        /// Seconds in one solar day
        public static let secondsPerDay: Double = 86400.0
    }
    
    public struct Time {
        /// Seconds in one day
        public static let secondsPerDay: Double = 86400.0
    }
}
```

### 2. Update Orbit.swift to use PhysicalConstants

```swift
// Replace line 134:
let earthsRadius = PhysicalConstants.Earth.radius

// Replace line 165:
let earthsGravitationalConstant = PhysicalConstants.Earth.µ

// Replace line 166:
let motionRadsPerSecond = meanMotion / PhysicalConstants.Time.secondsPerDay
```

### 3. Update Date.swift to use PhysicalConstants

Replace all hardcoded `86400.0` with `PhysicalConstants.Time.secondsPerDay`

## Testing

Before and after changes, verify orbital calculations produce expected results:
- Test with GOES 16 satellite (known semimajor axis)
- Test position calculations for ISS
- Ensure accuracy improvements (closer to WGS84 standard)

## Related Issues

- Issue #4 (Magic numbers throughout code)
- Issue #29 (Incorrect Earth radius)

## Priority

**High** - Affects calculation accuracy

## Acceptance Criteria

- [ ] All physical constants moved to PhysicalConstants.swift
- [ ] All usages updated to reference single source of truth
- [ ] WGS84 standard values used consistently
- [ ] Tests verify calculation accuracy unchanged or improved
- [ ] Documentation updated with references to standards
