---
title: "Align Orbit struct with Orbitable protocol - fix trueAnomaly optionality"
labels: ["bug", "type-safety", "protocol"]
---

## Description

The `Orbitable` protocol defines `trueAnomaly` as non-optional, but the `Orbit` struct implements it as an optional property. This creates a type inconsistency.

## Current Behavior

**Location:** `Orbitable.swift` and `Orbit.swift`

```swift
// Orbitable.swift - Protocol definition
protocol Orbitable {
    var trueAnomaly: Degrees { get }  // Non-optional
    // ... other properties
}

// Orbit.swift - Implementation
struct Orbit: Orbitable {
    var trueAnomaly: Degrees?  // Optional - doesn't match protocol!
    // ... other properties
}
```

**Impact:**
- Type safety violation
- Compiler allows inconsistent implementation
- May cause runtime issues when protocol is used polymorphically
- Confusing for library users

## Expected Behavior

The implementation should match the protocol definition. There are two approaches:

### Option 1: Make trueAnomaly Non-Optional (Recommended)

```swift
struct Orbit: Orbitable {
    var trueAnomaly: Degrees {
        // Calculate from mean anomaly if not set
        return calculatedTrueAnomaly ?? 0.0
    }
    
    private var calculatedTrueAnomaly: Degrees?
}
```

### Option 2: Make Protocol Optional

```swift
protocol Orbitable {
    var trueAnomaly: Degrees? { get }  // Make optional
}
```

## Analysis

**Why is trueAnomaly optional in Orbit?**
- True anomaly is calculated iteratively from mean anomaly
- Calculation might fail to converge
- However, protocol consumers expect a value

**Recommendation:** Option 1 is better because:
- True anomaly is a fundamental orbital element
- If calculation fails, returning 0 or throwing error is clearer than nil
- Maintains protocol contract

## Proposed Solution

1. Keep protocol definition as non-optional
2. Modify Orbit to always provide a value
3. Add computed property that never returns nil
4. Store calculated value internally as optional
5. Handle calculation failures appropriately (return fallback or throw)

### Implementation

```swift
struct Orbit: Orbitable {
    // Public non-optional property matching protocol
    public var trueAnomaly: Degrees {
        get {
            if let calculated = _trueAnomaly {
                return calculated
            }
            // Fallback: calculate from mean anomaly
            return calculateTrueAnomaly()
        }
    }
    
    // Private storage
    private var _trueAnomaly: Degrees?
    
    private func calculateTrueAnomaly() -> Degrees {
        // Implement calculation from mean anomaly
        // Return meaningful fallback if calculation fails
        return meanAnomaly // Simplified fallback
    }
}
```

## Additional Context

- Affects: `Orbit.swift`, `Orbitable.swift`
- Priority: **Low** - Type safety issue but not causing runtime errors
- Related to: Protocol-oriented programming best practices

## Acceptance Criteria

- [ ] Orbit conforms to Orbitable protocol correctly
- [ ] trueAnomaly is non-optional in both protocol and implementation
- [ ] Calculated property always returns a valid value
- [ ] Tests added for edge cases (convergence failures)
- [ ] Documentation explains calculation and fallback behavior
- [ ] No breaking changes to public API
