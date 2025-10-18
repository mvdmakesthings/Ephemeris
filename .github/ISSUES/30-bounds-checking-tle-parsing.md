---
title: "Add bounds checking for TLE string parsing"
labels: ["bug", "high-priority", "security"]
---

## Description

The TLE parser uses string subscripting without validating string lengths, which can cause crashes when processing malformed TLE data.

## Current Implementation

**Location:** `TwoLineElement.swift` throughout init method

```swift
// Lines 65-104: Multiple instances of unsafe subscripting
self.name = line0[0...24].string
self.catalogNumber = Int(line1[2...6].string.trimmingCharacters(in: .whitespacesAndNewlines))!
self.internationalDesignator = line1[9...16].string.trimmingCharacters(in: .whitespacesAndNewlines)
// ... and many more
```

## Problem

The custom string subscripting extension (from `StringProtocol+subscript.swift`) will crash if:
- Line is shorter than expected position
- Position is out of bounds
- String encoding issues

Example crash scenarios:
```swift
// Short TLE line
"ISS" // Only 3 characters, trying to access [0...24] will crash

// Truncated line 1
"1 25544U" // Only 8 characters, trying to access [18...31] will crash
```

## Impact

- **Security:** Malformed TLE data can crash the application
- **Robustness:** No validation of TLE format before parsing
- **User Experience:** Crashes instead of error messages
- **Testing:** Hard to test error conditions

## Related Implementation

The `StringProtocol+subscript.swift` extension provides a `safe` subscript:
```swift
subscript(safe offset: Int) -> Element? {
    guard !isEmpty, let i = index(startIndex, offsetBy: offset, limitedBy: index(before: endIndex)) 
    else { return nil }
    return self[i]
}
```

But this is only available for `BidirectionalCollection`, not for range subscripting.

## Proposed Solution

### Option 1: Add Safe Range Subscripting Extension

```swift
extension StringProtocol {
    /// Safely subscript with a closed range, returning nil if out of bounds
    subscript(safe range: ClosedRange<Int>) -> SubSequence? {
        guard range.lowerBound >= 0,
              range.upperBound < count,
              let lowerIndex = index(startIndex, offsetBy: range.lowerBound, limitedBy: endIndex),
              let upperIndex = index(startIndex, offsetBy: range.upperBound + 1, limitedBy: endIndex)
        else { return nil }
        return self[lowerIndex..<upperIndex]
    }
}
```

### Option 2: Validate TLE Format Before Parsing

```swift
public init(from tle: String) throws {
    let lines = tle.components(separatedBy: "\n")
    guard lines.count == 3 else { 
        throw TLEParsingError.invalidFormat("Expected 3 lines, got \(lines.count)") 
    }
    
    let line0 = lines[0]
    let line1 = lines[1]
    let line2 = lines[2]
    
    // Validate line lengths
    guard line0.count >= 24 else {
        throw TLEParsingError.invalidFormat("Line 0 too short (expected >= 24, got \(line0.count))")
    }
    guard line1.count >= 69 else {
        throw TLEParsingError.invalidFormat("Line 1 too short (expected 69, got \(line1.count))")
    }
    guard line2.count >= 69 else {
        throw TLEParsingError.invalidFormat("Line 2 too short (expected 69, got \(line2.count))")
    }
    
    // Now safe to use subscripting
    self.name = line0[0...24].string.trimmingCharacters(in: .whitespacesAndNewlines)
    // ...
}
```

### Option 3: Combine Both (Recommended)

1. Add safe range subscripting to `StringProtocol+subscript.swift`
2. Use safe subscripting in TLE parser
3. Validate format and provide meaningful errors

```swift
public init(from tle: String) throws {
    let lines = tle.components(separatedBy: "\n")
    guard lines.count == 3 else { 
        throw TLEParsingError.invalidFormat("Expected 3 lines, got \(lines.count)") 
    }
    
    let line0 = lines[0]
    let line1 = lines[1]
    let line2 = lines[2]
    
    // Safe subscripting with proper error messages
    guard let nameSubstring = line0[safe: 0...24] else {
        throw TLEParsingError.invalidFormat("Line 0 too short for name field")
    }
    self.name = nameSubstring.string.trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard let catalogSubstring = line1[safe: 2...6] else {
        throw TLEParsingError.invalidFormat("Line 1 too short for catalog number")
    }
    guard let catalogNumber = Int(catalogSubstring.string.trimmingCharacters(in: .whitespacesAndNewlines)) else {
        throw TLEParsingError.invalidNumber(field: "catalogNumber", value: catalogSubstring.string)
    }
    self.catalogNumber = catalogNumber
    
    // ... continue for all fields
}
```

## Testing

Add tests for various malformed TLE formats:

```swift
func testTLEParsingWithShortLines() throws {
    let shortTLE = """
        ISS
        Short
        Lines
        """
    
    XCTAssertThrowsError(try TwoLineElement(from: shortTLE)) { error in
        guard case TLEParsingError.invalidFormat = error else {
            XCTFail("Expected invalidFormat error")
            return
        }
    }
}

func testTLEParsingWithInvalidNumbers() throws {
    let invalidTLE = """
        ISS (ZARYA)              
        1 XXXXX 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
        2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
        """
    
    XCTAssertThrowsError(try TwoLineElement(from: invalidTLE)) { error in
        guard case TLEParsingError.invalidNumber = error else {
            XCTFail("Expected invalidNumber error")
            return
        }
    }
}
```

## Related Issues

- Issue #1 (TLE parsing error handling)
- Issue #17 (Input sanitization)

## Priority

**High** - Security and stability issue

## Acceptance Criteria

- [ ] Safe range subscripting added to StringProtocol extension
- [ ] TLE parser validates input before parsing
- [ ] All unsafe subscripts replaced with safe versions
- [ ] Descriptive errors for out-of-bounds access
- [ ] Tests added for malformed TLE data
- [ ] No force unwraps remain in TLE parser
- [ ] Documentation updated with TLE format requirements
