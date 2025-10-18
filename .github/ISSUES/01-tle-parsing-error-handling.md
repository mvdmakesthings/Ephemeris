---
title: "Add proper error handling for TLE parsing"
labels: ["bug", "high-priority", "enhancement"]
---

## Description

The TLE (Two-Line Element) parser currently uses force unwrapping (`!`) extensively and includes a `fatalError()` call, which will crash the application if invalid TLE data is provided. This is inappropriate behavior for a library framework.

## Current Behavior

**Location:** `TwoLineElement.swift` - `init(from:)` method

```swift
guard lines.count == 3 else { fatalError("Not properly formatted TLE data") }
// ... followed by multiple force unwraps like:
self.catalogNumber = Int(catalogNumberString)!
self.inclination = Degrees(inclinationString)!
```

**Impact:**
- Application crashes when receiving malformed TLE data
- No graceful error recovery
- Poor user experience
- Makes testing error conditions difficult

## Expected Behavior

The initializer should be throwing and provide informative errors:

```swift
enum TLEParsingError: Error {
    case invalidFormat(String)
    case invalidNumber(field: String, value: String)
    case missingLine(lineNumber: Int)
}

public init(from tle: String) throws {
    let lines = tle.components(separatedBy: "\n")
    guard lines.count == 3 else { 
        throw TLEParsingError.missingLine(lineNumber: lines.count) 
    }
    // ... proper error handling for each field
}
```

## Steps to Reproduce

```swift
// This will crash the app
let invalidTLE = "Invalid TLE String"
let tle = TwoLineElement(from: invalidTLE) // Fatal error!
```

## Proposed Solution

1. Replace `fatalError()` with throwing initializer
2. Replace all force unwraps with proper error handling
3. Add comprehensive TLE validation
4. Provide descriptive error messages
5. Add tests for invalid TLE formats

## Additional Context

- Affects: `TwoLineElement.swift` (lines 55-105)
- Related to Issue #30 (bounds checking)
- Priority: **High** - This is a crash bug

## Acceptance Criteria

- [ ] Initializer throws appropriate errors instead of crashing
- [ ] All force unwraps removed
- [ ] Descriptive error messages for each failure case
- [ ] Tests added for invalid TLE formats
- [ ] Documentation updated with error handling examples
