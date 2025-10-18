---
title: "Document performance characteristics of custom string subscripting"
labels: ["performance", "documentation", "enhancement"]
---

## Description

The custom string subscripting extension may have O(n) complexity due to how Swift String indexing works. This should be documented, and performance characteristics should be verified.

## Current Behavior

**Location:** `StringProtocol+subscript.swift`

```swift
extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
    
    subscript(range: Range<Int>) -> SubSequence {
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return self[start..<end]
    }
}
```

**Potential Issues:**
- `index(_:offsetBy:)` is O(n) for String
- Repeated subscripting in loops compounds performance
- Users may not expect O(n) behavior

## Performance Analysis

### Swift String Indexing

Swift Strings use Unicode-aware indexing, not integer offsets:
- **Array subscripting:** O(1)
- **String subscripting:** O(n) where n is the offset

### Impact in TLE Parsing

```swift
// TwoLineElement.swift - Multiple subscript operations
let catalogNumber = line1[2..<7]        // O(n)
let classification = line1[7]           // O(n)
let intlDesignatorYear = line1[9..<11]  // O(n)
// ... many more
```

**Cumulative cost:** O(n * m) where m is number of subscript operations

### Benchmark Example

```swift
// Naive approach (current)
func parseTLE(_ line: String) {
    let field1 = line[2..<7]    // Traverse 2 chars
    let field2 = line[9..<11]   // Traverse 9 chars  
    let field3 = line[23..<32]  // Traverse 23 chars
    // Total: 34 character traversals
}

// Optimized approach
func parseTLEOptimized(_ line: String) {
    var index = line.startIndex
    index = line.index(index, offsetBy: 2)
    let field1Start = index
    index = line.index(index, offsetBy: 5)
    let field1 = line[field1Start..<index]
    // Reuse index - only traverse each character once
    // Total: ~32 character traversals (one pass)
}
```

## Expected Behavior

### Option 1: Document Current Behavior (Minimum)

Add documentation to the extension:

```swift
/// Provides integer-based subscripting for String types.
///
/// - Performance: O(n) where n is the offset, due to Unicode-aware indexing.
///   For TLE parsing (multiple adjacent fields), consider caching String.Index
///   values or using a single forward pass instead of multiple subscript operations.
///
/// - Note: Standard Swift String indexing is intentionally O(n) to handle
///   variable-width Unicode characters correctly. This extension provides
///   convenient integer subscripting at the cost of performance.
extension StringProtocol {
    // ...
}
```

### Option 2: Add Performance-Conscious Alternative

```swift
extension StringProtocol {
    /// Integer subscripting (convenient but O(n))
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
    
    /// Efficient multi-field extraction for formats like TLE
    /// - Returns: Dictionary of field names to substring values
    func extractFields(_ ranges: [String: Range<Int>]) -> [String: SubSequence] {
        var result: [String: SubSequence] = [:]
        var indices: [(String, String.Index, String.Index)] = []
        
        // Pre-compute all indices in one pass
        // ... implementation
        
        return result
    }
}
```

### Option 3: Optimize TLE Parser (Recommended)

Refactor TLE parsing to use single-pass extraction:

```swift
func parseLine1(_ line: String) -> Line1Data {
    var index = line.startIndex
    
    // Helper to advance and extract
    func extract(_ count: Int) -> Substring {
        let start = index
        index = line.index(index, offsetBy: count)
        return line[start..<index]
    }
    
    index = line.index(index, offsetBy: 2)  // Skip line number
    let catalogNumber = extract(5)
    let classification = extract(1)
    let intlDesignatorYear = extract(2)
    // ... continue in order
    
    return Line1Data(catalogNumber: catalogNumber, ...)
}
```

## Proposed Solution

1. **Document** current performance characteristics
2. **Measure** actual performance impact with benchmarks
3. **Decide** if optimization is needed based on measurements
4. **Optimize** TLE parser if performance is a concern
5. **Add** tests for performance regression

## Benchmarking

Add performance test:

```swift
func testTLEParsingPerformance() {
    let tleString = """
    ISS (ZARYA)
    1 25544U 98067A   21365.00000000  .00002182  00000-0  41420-4 0  9990
    2 25544  51.6461 303.6672 0003029  34.8481  83.5048 15.48919393314184
    """
    
    measure {
        for _ in 0..<1000 {
            _ = TwoLineElement(from: tleString)
        }
    }
}
```

## Additional Context

- Affects: `StringProtocol+subscript.swift`, `TwoLineElement.swift`
- Priority: **Low** - Performance consideration
- Impact: TLE files are typically small (< 1KB each)
- Related to: Swift String performance characteristics

## Acceptance Criteria

- [ ] Performance characteristics documented
- [ ] Benchmark test added
- [ ] Performance measured (baseline established)
- [ ] Decision made: optimize or document
- [ ] If optimizing: TLE parser refactored for efficiency
- [ ] If documenting: Clear warnings added about O(n) behavior
- [ ] Performance test added to prevent regressions
