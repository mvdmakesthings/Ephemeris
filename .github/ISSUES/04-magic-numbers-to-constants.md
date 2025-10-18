---
title: "Replace magic numbers with named constants"
labels: ["refactoring", "maintainability"]
---

## Description

Multiple "magic numbers" appear throughout the codebase without explanation or named constants, reducing code maintainability and clarity.

## Affected Locations

### 1. Time Conversions
- `Orbit.swift` line 166: `86400` (seconds per day)
- `Date.swift` line 50: `86400.0` (seconds per day)
- `Date.swift` line 141: `36525.0` (days per Julian century)
- `ViewController.swift` line 35: `300` (5 minutes in seconds)
- `ViewController.swift` line 36: `(1 * 60 * 60)` (1 hour in seconds)

### 2. Physical Constants
- `Orbit.swift` line 134: `6370.0` (Earth radius in km - incorrect!)
- `Orbit.swift` line 165: `398613.52` (Earth's gravitational constant)

### 3. Date/Time Reference Points
- `Date.swift` line 84: `2440587.5` (Julian Day for Unix epoch)
- `Date.swift` line 140: `2451545.0` (Julian Day for J2000.0 epoch)

### 4. Mathematical Constants
- Various uses of `360.0` for full circle degrees
- `2.0 * .pi` for 2π

### 5. Accuracy/Iteration Limits
- `Orbit.swift` line 176: `accuracy: Double = 0.00001`
- `Orbit.swift` line 176: `maxIterations: Int = 500`

## Impact

- **Maintainability:** Hard to understand what numbers represent
- **Bugs:** Easy to use wrong value or forget conversions
- **Consistency:** Same values defined differently in different places
- **Testing:** Difficult to test with alternative values

## Proposed Solution

### 1. Expand PhysicalConstants.swift

```swift
public struct PhysicalConstants {
    
    public struct Earth {
        // Existing: µ, radius, radsPerDay
        
        /// Mean radius of Earth in kilometers (simplified sphere model)
        /// - Note: For precise calculations, use `radius` (WGS84 equatorial radius)
        public static let meanRadius: Double = 6371.0
    }
    
    public struct Time {
        /// Seconds in one solar day
        public static let secondsPerDay: Double = 86400.0
        
        /// Days in one Julian century
        public static let daysPerJulianCentury: Double = 36525.0
        
        /// Seconds in one hour
        public static let secondsPerHour: Double = 3600.0
        
        /// Seconds in one minute
        public static let secondsPerMinute: Double = 60.0
    }
    
    public struct Julian {
        /// Julian Day Number for Unix Epoch (Jan 1, 1970 00:00:00 UTC)
        public static let unixEpoch: Double = 2440587.5
        
        /// Julian Day Number for J2000.0 Epoch (Jan 1, 2000 12:00:00 TT)
        public static let j2000Epoch: Double = 2451545.0
    }
    
    public struct Calculation {
        /// Default convergence accuracy for iterative calculations
        public static let defaultAccuracy: Double = 0.00001
        
        /// Maximum iterations for convergence algorithms
        public static let maxIterations: Int = 500
    }
    
    public struct Angle {
        /// Degrees in a full circle
        public static let degreesPerCircle: Double = 360.0
        
        /// Radians in a full circle (2π)
        public static let radiansPerCircle: Double = 2.0 * .pi
    }
}
```

### 2. Update Usage Throughout Codebase

**Orbit.swift:**
```swift
// Line 134: Replace
let earthsRadius = PhysicalConstants.Earth.radius

// Line 152: Replace
let adjustedMeanAnomalyForJulianDate = meanAnomalyForJulianDate - PhysicalConstants.Angle.degreesPerCircle * fullRevolutions

// Line 166: Replace
let motionRadsPerSecond = meanMotion / PhysicalConstants.Time.secondsPerDay

// Line 176: Replace
static func calculateEccentricAnomaly(
    eccentricity: Double, 
    meanAnomaly: Degrees, 
    accuracy: Double = PhysicalConstants.Calculation.defaultAccuracy, 
    maxIterations: Int = PhysicalConstants.Calculation.maxIterations
) -> Degrees
```

**Date.swift:**
```swift
// Line 50: Replace
let dayFraction = totalSeconds / PhysicalConstants.Time.secondsPerDay

// Line 84, 91: Replace
return PhysicalConstants.Julian.unixEpoch + jan1SecondsSince1970 / PhysicalConstants.Time.secondsPerDay + epochDayFraction - 1.0

// Line 140: Replace
return (julianDay - PhysicalConstants.Julian.j2000Epoch) / PhysicalConstants.Time.daysPerJulianCentury
```

**ViewController.swift:**
```swift
// Line 35: Replace
let timeIntervalOffset: TimeInterval = 5 * PhysicalConstants.Time.secondsPerMinute

// Line 36: Replace
let timeIntervalMax: TimeInterval = PhysicalConstants.Time.secondsPerHour
```

## Benefits

- **Clarity:** Code is self-documenting
- **Maintainability:** Single source of truth for constants
- **Consistency:** Same value always used for same concept
- **Testability:** Easy to mock constants if needed
- **Documentation:** Constants can include units and references

## Related Issues

- Issue #2 (Inconsistent physical constants)
- Issue #29 (Incorrect Earth radius)

## Priority

**Medium** - Refactoring that improves code quality

## Acceptance Criteria

- [ ] PhysicalConstants.swift expanded with all commonly used constants
- [ ] All magic numbers replaced with named constants
- [ ] Constants include documentation with units and sources
- [ ] All tests still pass
- [ ] Code is more readable and maintainable

## Notes

This can be done incrementally:
1. Add constants to PhysicalConstants.swift
2. Replace usage file by file
3. Ensure tests pass after each change
