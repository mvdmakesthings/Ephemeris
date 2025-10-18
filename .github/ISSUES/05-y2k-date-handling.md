---
title: "Y2057 bug: 2-digit year parsing will fail in 2057"
labels: ["bug", "technical-debt", "future"]
---

## Description

The TLE parser uses a Y2K-style 2-digit year parsing that assumes all satellites were launched after 1957. This will fail starting in 2057, just 32 years from now.

## Current Implementation

**Location:** `TwoLineElement.swift` lines 76-79

```swift
let epochYearInt = Int(line1[18...19].string.trimmingCharacters(in: .whitespacesAndNewlines))!
// Satillites weren't lauched until 1957 (Sputnik 1) so this will work... until 2057 when we will need
// to figure out something else. 💩 Y2K for TwoLineElement standards!
self.epochYear = (epochYearInt < 57) ? 2000 + epochYearInt : 1900 + epochYearInt
```

## Problems

1. **Will Break in 2057:** TLEs created in 2057+ will be parsed as 1957+
2. **Ambiguity:** Years 57-99 are assumed to be 1957-1999
3. **Comment Notes Future Problem:** The code itself acknowledges this is a time bomb
4. **Typo:** "Satillites" should be "Satellites", "lauched" should be "launched"

## Impact

- **Timeline:** Will fail starting January 1, 2057
- **Severity:** Complete failure to parse modern TLE data after 2057
- **Scope:** Affects all TLE parsing
- **Legacy Data:** Historical TLEs from 1957-1999 would be interpreted correctly

## Root Cause

The TLE format specification uses 2-digit years, requiring interpretation logic. The NORAD standard doesn't specify how to handle the century ambiguity.

## Proposed Solutions

### Option 1: Expand Window (Short-term fix)

```swift
// Assume years 00-56 are 2000-2056, years 57-99 are 2057-2099
self.epochYear = (epochYearInt < 57) ? 2000 + epochYearInt : 2000 + epochYearInt

// Or more conservative: assume recent years
let currentYear = Calendar.current.component(.year, from: Date())
let currentCentury = (currentYear / 100) * 100
self.epochYear = currentCentury + epochYearInt

// If epochYear is more than 50 years in the future, assume previous century
if self.epochYear > currentYear + 50 {
    self.epochYear -= 100
}
```

### Option 2: Add Configuration (Recommended)

```swift
/// Configuration for TLE parsing
public struct TLEConfiguration {
    /// Reference year for 2-digit year parsing.
    /// Years within ±50 years of this reference are interpreted accordingly.
    public static var referenceYear: Int = 2000
    
    /// Window size for year interpretation (default: ±50 years)
    public static var yearWindow: Int = 50
}

// In init:
let currentCentury = (TLEConfiguration.referenceYear / 100) * 100
self.epochYear = currentCentury + epochYearInt

// Adjust if outside window
if abs(self.epochYear - TLEConfiguration.referenceYear) > TLEConfiguration.yearWindow {
    self.epochYear += (self.epochYear < TLEConfiguration.referenceYear) ? 100 : -100
}
```

### Option 3: Use Current Date Context (Most Robust)

```swift
/// Parse 2-digit year relative to current date
/// Assumes epoch is within ±50 years of current year
private static func parse2DigitYear(_ twoDigitYear: Int) -> Int {
    let now = Date()
    let calendar = Calendar.current
    let currentYear = calendar.component(.year, from: now)
    
    let century = (currentYear / 100) * 100
    var year = century + twoDigitYear
    
    // If resulting year is more than 50 years in the future,
    // assume it's from the previous century
    if year > currentYear + 50 {
        year -= 100
    }
    // If resulting year is more than 50 years in the past,
    // assume it's from the next century
    else if year < currentYear - 50 {
        year += 100
    }
    
    return year
}

self.epochYear = Self.parse2DigitYear(epochYearInt)
```

## Recommendation

Implement **Option 3** as it:
- Works for historical data (1957-present)
- Works for future data (up to ~2070 assuming regular updates)
- Automatically adjusts with current date
- No configuration needed
- Clear semantics (±50 year window)

## Testing

Add tests for edge cases:
```swift
func testTLEYearParsing() {
    // Test current century
    // Test previous century (57-99 range)
    // Test boundary conditions (06, 56, 57)
    // Test with mocked current date in 2057
}
```

## Long-term Consideration

This is fundamentally a limitation of the TLE format. Consider:
- Documenting this limitation in README
- Adding warning for very old or very new TLEs
- Contributing to TLE format standards discussion

## Related Issues

- None directly, but related to Issue #1 (error handling)

## Priority

**Medium** - Won't be a problem for 32 years, but should be fixed properly

## Acceptance Criteria

- [ ] Year parsing handles 2057+ correctly
- [ ] Historical data (1957-1999) still parses correctly
- [ ] Implementation uses current date context or configuration
- [ ] Tests added for edge cases and future dates
- [ ] Documentation updated explaining the approach
- [ ] Typos in comments fixed
