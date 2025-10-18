---
title: "Add input sanitization for TLE parsing"
labels: ["security", "validation", "enhancement"]
---

## Description

The TLE parser currently accepts string input without sanitization or validation, which could potentially be exploited with malicious input. While this is primarily a scientific library, proper input sanitization is a security best practice.

## Current Behavior

**Location:** `TwoLineElement.swift`

```swift
public init(from tle: String) {
    let lines = tle.components(separatedBy: "\n")
    // No sanitization or validation of input content
    // Direct string subscripting without safety checks
}
```

**Potential Risks:**
- Extremely long strings could cause performance issues
- Malformed Unicode could cause crashes
- Special characters not handled properly
- No length validation before parsing

## Expected Behavior

Implement input sanitization before parsing:

```swift
public init(from tle: String) throws {
    // 1. Check length (TLE should be ~140-200 characters)
    guard tle.count < 500 else {
        throw TLEParsingError.inputTooLong(tle.count)
    }
    
    // 2. Validate character set (ASCII printable)
    let allowedCharSet = CharacterSet.alphanumerics
        .union(.whitespaces)
        .union(CharacterSet(charactersIn: ".-+"))
    
    guard tle.unicodeScalars.allSatisfy({ allowedCharSet.contains($0) }) else {
        throw TLEParsingError.invalidCharacters
    }
    
    // 3. Normalize whitespace
    let normalizedTLE = tle.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // 4. Proceed with parsing
    let lines = normalizedTLE.components(separatedBy: .newlines)
    // ... rest of parsing
}
```

## Security Considerations

### Maximum Input Length
TLE format is fixed at 3 lines of ~69 characters each:
- Line 0: Satellite name (~24 chars)
- Line 1: TLE data line 1 (69 chars)
- Line 2: TLE data line 2 (69 chars)
- **Maximum reasonable length:** 500 characters (with safety margin)

### Allowed Characters
TLE format uses only:
- Alphanumeric: `0-9`, `A-Z`, `a-z`
- Punctuation: `.`, `-`, `+`, ` ` (space)
- Whitespace: newlines, spaces

### Attack Vectors to Prevent
1. **Resource exhaustion:** Extremely long strings
2. **Unicode exploits:** Invalid UTF-8 sequences
3. **Format string attacks:** Special characters
4. **Injection attacks:** Embedded control characters

## Proposed Solution

1. Add maximum length validation (500 chars)
2. Validate character set (ASCII printable only)
3. Normalize whitespace and newlines
4. Sanitize input before processing
5. Add tests for malicious inputs
6. Document security considerations

## Test Cases

```swift
func testInputTooLong() {
    let longString = String(repeating: "X", count: 10000)
    XCTAssertThrowsError(try TwoLineElement(from: longString))
}

func testInvalidCharacters() {
    let maliciousInput = "ISS\n1 \0\0\0\n2"
    XCTAssertThrowsError(try TwoLineElement(from: maliciousInput))
}

func testUnicodeExploits() {
    let unicodeAttack = "ISS\n1 😀💀\n2"
    XCTAssertThrowsError(try TwoLineElement(from: unicodeAttack))
}

func testExcessiveWhitespace() {
    let whitespaceAttack = "\n\n\n\n\n" + validTLE + "\n\n\n\n"
    XCTAssertNoThrow(try TwoLineElement(from: whitespaceAttack)) // Should sanitize
}
```

## Additional Context

- Affects: `TwoLineElement.swift`
- Related to: Issue #01 (TLE error handling), Issue #30 (bounds checking)
- Priority: **Medium** - Security enhancement
- **Note:** This is not a critical vulnerability since the library processes scientific data, but it's a best practice

## References

- OWASP Input Validation: https://owasp.org/www-project-proactive-controls/v3/en/c5-validate-inputs
- Swift String Security: https://developer.apple.com/documentation/swift/string

## Acceptance Criteria

- [ ] Maximum input length validation implemented
- [ ] Character set validation added
- [ ] Whitespace normalization implemented
- [ ] Input sanitization occurs before parsing
- [ ] Tests added for malicious inputs
- [ ] Security considerations documented
- [ ] Performance impact measured and acceptable
