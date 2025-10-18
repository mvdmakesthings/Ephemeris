---
title: "Add warning/error when iterative convergence fails"
labels: ["robustness", "enhancement", "logging"]
---

## Description

The orbital calculations use iterative methods to converge on solutions (e.g., solving Kepler's equation for true anomaly). Currently, if convergence fails after reaching `maxIterations`, the code silently continues with potentially incorrect results.

## Current Behavior

**Location:** `Orbit.swift` - Iterative convergence loops

```swift
// Simplified example of convergence pattern
var value = initialGuess
for _ in 0..<maxIterations {
    let newValue = improveGuess(value)
    if abs(newValue - value) < tolerance {
        return newValue  // Converged successfully
    }
    value = newValue
}
// Falls through - convergence failed but no warning!
return value  // May be inaccurate
```

**Impact:**
- Silent calculation errors
- No feedback about accuracy
- Difficult to debug orbital calculations
- May produce subtly incorrect results

## Expected Behavior

Alert the user when convergence fails:

### Option 1: Throw Error (Breaking Change)

```swift
func solveKeplersEquation(...) throws -> Double {
    var value = initialGuess
    for _ in 0..<maxIterations {
        let newValue = improveGuess(value)
        if abs(newValue - value) < tolerance {
            return newValue
        }
        value = newValue
    }
    throw OrbitCalculationError.convergenceFailed(
        method: "Kepler's Equation",
        iterations: maxIterations,
        residual: abs(value - improveGuess(value))
    )
}
```

### Option 2: Log Warning (Non-Breaking)

```swift
func solveKeplersEquation(...) -> Double {
    var value = initialGuess
    for _ in 0..<maxIterations {
        let newValue = improveGuess(value)
        if abs(newValue - value) < tolerance {
            return newValue
        }
        value = newValue
    }
    
    // Log warning but continue
    print("Warning: Convergence failed for Kepler's equation after \(maxIterations) iterations")
    return value
}
```

### Option 3: Return Result with Status (Recommended)

```swift
struct ConvergenceResult<T> {
    let value: T
    let converged: Bool
    let iterations: Int
    let residual: Double
}

func solveKeplersEquation(...) -> ConvergenceResult<Double> {
    var value = initialGuess
    for iteration in 0..<maxIterations {
        let newValue = improveGuess(value)
        let residual = abs(newValue - value)
        if residual < tolerance {
            return ConvergenceResult(
                value: newValue,
                converged: true,
                iterations: iteration,
                residual: residual
            )
        }
        value = newValue
    }
    
    return ConvergenceResult(
        value: value,
        converged: false,
        iterations: maxIterations,
        residual: abs(value - improveGuess(value))
    )
}
```

## Convergence Scenarios

### Typical Cases
- **Fast convergence:** 2-5 iterations
- **Normal convergence:** 5-15 iterations
- **Slow convergence:** 15-50 iterations
- **Non-convergence:** > maxIterations

### When Convergence May Fail
1. **High eccentricity orbits** (e > 0.9)
2. **Poor initial guesses**
3. **Extreme orbital parameters**
4. **Numerical instability**

## Proposed Solution

### Phase 1: Add Warnings
1. Add logging when convergence fails
2. Include diagnostic information
3. Use conditional compilation for debug builds

```swift
#if DEBUG
if !converged {
    print("⚠️ Convergence warning: \(method) failed after \(maxIterations) iterations")
    print("   Residual: \(residual), Tolerance: \(tolerance)")
}
#endif
```

### Phase 2: Improve Diagnostics
1. Return convergence status with results
2. Add property to check if calculation is reliable
3. Expose iteration count for debugging

### Phase 3: Better Algorithms
1. Improve initial guesses
2. Use adaptive tolerances
3. Implement fallback methods

## Test Cases

```swift
func testHighEccentricityConvergence() {
    // Test with e = 0.95 (high eccentricity)
    let orbit = Orbit(semimajorAxis: 10000, eccentricity: 0.95, ...)
    let result = orbit.calculateTrueAnomaly()
    
    XCTAssertTrue(result.converged, "Should converge even with high eccentricity")
    XCTAssertLessThan(result.iterations, 50)
}

func testConvergenceFailureDetection() {
    // Create scenario that won't converge
    let pathologicalOrbit = Orbit(...)
    let result = orbit.calculatePosition()
    
    // Should detect and report non-convergence
    if !result.converged {
        XCTAssertGreaterThan(result.residual, tolerance)
    }
}
```

## Additional Context

- Affects: `Orbit.swift` - All iterative methods
- Priority: **Low** - Robustness improvement
- Related to: Issue #09 (input validation), Issue #31 (numerical errors)

## References

- [Kepler's Equation Convergence](https://en.wikipedia.org/wiki/Kepler%27s_equation)
- [Numerical Methods](https://en.wikipedia.org/wiki/Newton%27s_method)

## Acceptance Criteria

- [ ] Convergence status tracked for iterative methods
- [ ] Warning logged when convergence fails
- [ ] Diagnostic information included (iterations, residual)
- [ ] Tests added for convergence edge cases
- [ ] Documentation explains convergence behavior
- [ ] Option to query convergence status added (optional)
- [ ] Performance impact measured (should be minimal)
