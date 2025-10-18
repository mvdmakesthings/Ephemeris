---
title: "Remove or populate empty MathTests.swift file"
labels: ["testing", "cleanup", "good-first-issue"]
---

## Description

The `MathTests.swift` file exists in the test target but contains no actual tests. This creates confusion and inflates test file counts without adding value.

## Current Behavior

**Location:** `EphemerisTests/MathTests.swift`

```swift
import XCTest
@testable import Ephemeris

class MathTests: XCTestCase {
    // Empty - no tests
}
```

**Impact:**
- Misleading test coverage metrics
- Confusion about what should be tested
- File clutter without purpose
- May correspond to empty `Math.swift` (Issue #08)

## Expected Behavior

Either:

### Option 1: Remove the File (Recommended)

If there's no `Math` module or functionality to test, delete the file:

```bash
git rm EphemerisTests/MathTests.swift
```

### Option 2: Add Tests

If mathematical utilities exist, add proper tests:

```swift
import XCTest
@testable import Ephemeris

class MathTests: XCTestCase {
    
    func testAngleConversion() {
        let degrees: Degrees = 180.0
        let radians = degrees.toRadians()
        XCTAssertEqual(radians, .pi, accuracy: 0.0001)
    }
    
    func testAngleNormalization() {
        let angle: Degrees = 450.0
        let normalized = angle.normalized()
        XCTAssertEqual(normalized, 90.0, accuracy: 0.0001)
    }
    
    // ... more tests
}
```

## Analysis

**Related to Issue #08:** There's an empty `Math.swift` file in `Ephemeris/Utilities/`

If `Math.swift` is removed (Issue #08), then `MathTests.swift` should also be removed for consistency.

## Proposed Solution

### Step 1: Check for Math Utilities

```bash
# Look for Math-related code
find Ephemeris -name "Math.swift" -exec cat {} \;

# Check if Math utilities exist elsewhere
grep -r "extension.*Math" Ephemeris/
```

### Step 2: Decision Tree

```
Does Math.swift have code?
├─ No → Remove MathTests.swift (Option 1)
└─ Yes → Add tests for that code (Option 2)

Are there math utilities elsewhere?
├─ No → Remove MathTests.swift (Option 1)
└─ Yes → Add tests for those (Option 2)
```

### Step 3: Take Action

**If removing:**
```bash
git rm EphemerisTests/MathTests.swift
git commit -m "Remove empty MathTests.swift file"
```

**If adding tests:**
1. Identify mathematical functions to test
2. Write comprehensive unit tests
3. Aim for >90% coverage

## Test Examples to Consider

If keeping the file, consider testing:

```swift
// Angle conversions
func testDegreesToRadians()
func testRadiansToDegrees()

// Angle normalization
func testNormalizeTo360()
func testNormalizeTo2Pi()

// Trigonometric utilities
func testSineDegrees()
func testCosineDegrees()

// Vector operations (if any)
func testDotProduct()
func testCrossProduct()
func testVectorNormalization()
```

## Good First Issue

This is perfect for new contributors:
- ✅ Clear options (remove or add tests)
- ✅ Low risk change
- ✅ Learn test infrastructure
- ✅ Quick turnaround

## Additional Context

- Affects: `EphemerisTests/MathTests.swift`
- Related to: Issue #08 (Remove unused Math.swift)
- Priority: **Low** - Cleanup task
- Time to fix: **5-15 minutes** (remove) or **1-2 hours** (add tests)

## Acceptance Criteria

### If Removing (Option 1):
- [ ] MathTests.swift deleted
- [ ] Xcode project updated (file reference removed)
- [ ] Tests still run successfully
- [ ] No broken test references

### If Adding Tests (Option 2):
- [ ] Minimum 5 test methods added
- [ ] Tests cover existing Math utilities
- [ ] All tests pass
- [ ] Code coverage improved
- [ ] Tests follow existing patterns
