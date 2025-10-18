---
title: "Replace force try (try!) with proper error handling in demo app"
labels: ["bug", "error-handling", "demo-app"]
---

## Description

The demo app uses `try!` (force try) in multiple locations, which will crash the app if any errors occur. This provides a poor user experience and doesn't demonstrate proper error handling patterns.

## Current Behavior

**Location:** `ViewController.swift` (lines 38, 41, 58)

```swift
let tleData = try! String(contentsOf: tleURL, encoding: .utf8)  // Line 38
let tle = TwoLineElement(from: tleString)  // Would crash with try!
let orbit = try! Orbit(tle: tle)  // Line 58
```

**Impact:**
- App crashes on network errors, file errors, or invalid TLE data
- No error messages shown to users
- Poor demonstration of library usage
- Makes debugging difficult

## Expected Behavior

Implement proper error handling with user-friendly error messages:

```swift
do {
    let tleData = try String(contentsOf: tleURL, encoding: .utf8)
    let tle = try TwoLineElement(from: tleData)
    let orbit = try Orbit(tle: tle)
    // Update UI with orbit data
} catch let error as TLEParsingError {
    showError("Invalid satellite data: \(error.localizedDescription)")
} catch {
    showError("Failed to load satellite data: \(error.localizedDescription)")
}
```

## Steps to Reproduce

1. Run the demo app
2. Provide invalid TLE data
3. App crashes instead of showing error message

## Proposed Solution

1. Replace all `try!` with proper `do-catch` blocks
2. Add error alert dialogs for user feedback
3. Implement graceful degradation (show cached data if available)
4. Add retry mechanism for network failures
5. Log errors for debugging

### Example Implementation

```swift
private func loadSatelliteData() {
    guard let tleURL = Bundle.main.url(forResource: "tle", withExtension: "txt") else {
        showError("TLE data file not found")
        return
    }
    
    do {
        let tleData = try String(contentsOf: tleURL, encoding: .utf8)
        let tle = try TwoLineElement(from: tleData)
        let orbit = try Orbit(tle: tle)
        updateUI(with: orbit)
    } catch let error as TLEParsingError {
        showTLEError(error)
    } catch let error as OrbitValidationError {
        showOrbitError(error)
    } catch {
        showGenericError(error)
    }
}

private func showError(_ message: String) {
    let alert = UIAlertController(
        title: "Error",
        message: message,
        preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
}
```

## Additional Context

- Affects: `EphemerisDemo/ViewController.swift`
- Related to: Issue #01 (TLE parsing error handling)
- Priority: **Medium** - Demo app quality issue

## Acceptance Criteria

- [ ] All `try!` statements removed from demo app
- [ ] Proper `do-catch` error handling implemented
- [ ] User-friendly error alerts shown
- [ ] Different error types handled appropriately
- [ ] Error messages are helpful and actionable
- [ ] App gracefully handles all error conditions
- [ ] Error handling demonstrates library best practices
