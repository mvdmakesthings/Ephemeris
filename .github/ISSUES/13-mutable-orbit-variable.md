---
title: "Change var to let for immutable Orbit variable in demo app"
labels: ["code-quality", "good-first-issue", "demo-app"]
---

## Description

The demo app declares an `Orbit` variable using `var` but never mutates it. This should be declared with `let` to indicate immutability and follow Swift best practices.

## Current Behavior

**Location:** `ViewController.swift` (line 57)

```swift
var orbit = try! Orbit(tle: tle)  // Should be 'let', not 'var'
// orbit is never modified after this line
```

**Impact:**
- Misleading code - suggests value might change
- Violates Swift best practices
- Could hide potential bugs
- Sets poor example in demo code

## Expected Behavior

Use `let` for values that don't change:

```swift
let orbit = try! Orbit(tle: tle)  // Immutable - clearly shows intent
```

## Swift Best Practices

### Prefer `let` over `var`

From Swift API Design Guidelines:
> Prefer to write `let` declarations everywhere you can. Use `var` only when you know the value will change.

**Benefits of `let`:**
- **Clarity:** Makes code intention clear
- **Safety:** Prevents accidental mutation
- **Optimization:** Compiler can optimize better
- **Thread-safety:** Immutable values are inherently thread-safe

## How to Verify

Check if the variable is mutated anywhere:

```bash
# Search for assignments to orbit variable
grep "orbit =" ViewController.swift

# If only one assignment (the initialization), use 'let'
```

## Proposed Solution

Simple one-line change:

```swift
// Before
var orbit = try! Orbit(tle: tle)

// After
let orbit = try! Orbit(tle: tle)
```

## Good First Issue

This is an excellent first contribution:
- ✅ One-line change
- ✅ Clear solution
- ✅ Low risk
- ✅ Learn Swift best practices
- ✅ Quick PR turnaround

## Additional Context

- Affects: `EphemerisDemo/ViewController.swift`
- Priority: **Low** - Code quality improvement
- Related to: Swift best practices
- Time to fix: **< 5 minutes**

## Check for Similar Issues

While fixing this, check for other instances:

```bash
# Find all var declarations that might not need mutation
grep -n "var [a-z].*=" EphemerisDemo/**/*.swift
```

Review each to see if they should be `let` instead.

## Acceptance Criteria

- [ ] `orbit` variable changed from `var` to `let`
- [ ] Code compiles without errors
- [ ] Demo app still runs correctly
- [ ] Similar issues in demo app checked and fixed
