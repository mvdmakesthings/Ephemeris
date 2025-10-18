---
title: "Add basic smoke tests for demo application"
labels: ["testing", "demo-app", "enhancement"]
---

## Description

The `EphemerisDemo` iOS application has no automated tests. Adding basic smoke tests would help ensure the demo app continues to work as the library evolves.

## Current Behavior

**Location:** `EphemerisDemo` target

- No test target exists for the demo app
- No UI tests
- No integration tests
- Demo breakage only discovered manually

**Impact:**
- Demo app can break without detection
- Manual testing required for every change
- Poor example for users (shows no testing)
- CI doesn't verify demo functionality

## Expected Behavior

Add a test target with basic smoke tests:

### Smoke Tests to Add

1. **App Launch Test**
   ```swift
   func testAppLaunches() {
       let app = XCUIApplication()
       app.launch()
       XCTAssertTrue(app.exists)
   }
   ```

2. **TLE Loading Test**
   ```swift
   func testTLELoads() {
       // Verify TLE file exists and loads
       let bundle = Bundle.main
       let tleURL = bundle.url(forResource: "tle", withExtension: "txt")
       XCTAssertNotNil(tleURL)
       XCTAssertNoThrow(try String(contentsOf: tleURL!))
   }
   ```

3. **Orbit Calculation Test**
   ```swift
   func testOrbitCalculates() {
       // Verify basic orbit creation works
       let tleString = "ISS (ZARYA)\n1 25544U..."
       XCTAssertNoThrow(try TwoLineElement(from: tleString))
   }
   ```

4. **UI Elements Exist**
   ```swift
   func testUIElementsExist() {
       let app = XCUIApplication()
       app.launch()
       
       // Check key UI elements are present
       XCTAssertTrue(app.staticTexts["Satellite Name"].exists)
       XCTAssertTrue(app.staticTexts["Altitude"].exists)
   }
   ```

## Proposed Solution

### Step 1: Create Test Target

Using Xcode:
1. File → New → Target
2. Choose "iOS UI Testing Bundle"
3. Name: `EphemerisDemoUITests`
4. Add to EphemerisDemo scheme

### Step 2: Add Basic Tests

```swift
import XCTest

class EphemerisDemoUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testAppLaunchesSuccessfully() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.exists)
    }
    
    func testSatelliteDataDisplays() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for data to load
        let satelliteName = app.staticTexts.matching(identifier: "satelliteName").firstMatch
        XCTAssertTrue(satelliteName.waitForExistence(timeout: 5))
    }
    
    func testNoErrorMessagesOnLaunch() {
        let app = XCUIApplication()
        app.launch()
        
        // Verify no error alerts appear
        XCTAssertFalse(app.alerts.element.exists)
    }
}
```

### Step 3: Add Unit Tests (Optional)

```swift
import XCTest
@testable import EphemerisDemo

class DemoAppUnitTests: XCTestCase {
    
    func testTLEFileExists() {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "tle", withExtension: "txt")
        XCTAssertNotNil(url, "TLE data file should exist in bundle")
    }
    
    func testTLEFileValidFormat() throws {
        let bundle = Bundle(for: type(of: self))
        let url = try XCTUnwrap(bundle.url(forResource: "tle", withExtension: "txt"))
        let content = try String(contentsOf: url)
        
        let lines = content.components(separatedBy: .newlines)
        XCTAssertTrue(lines.count >= 3, "TLE should have at least 3 lines")
    }
}
```

### Step 4: Add to CI

Update `.github/workflows/ci.yml`:

```yaml
- name: Test Demo App
  run: |
    xcodebuild test \
      -project Ephemeris.xcodeproj \
      -scheme EphemerisDemo \
      -destination 'platform=iOS Simulator,name=iPhone 14' \
      -quiet
```

## Test Strategy

### Essential Tests (Do First)
- ✅ App launches without crashing
- ✅ TLE data loads successfully
- ✅ No error alerts on launch
- ✅ Key UI elements exist

### Nice-to-Have Tests (Do Later)
- Data updates correctly
- UI responds to interactions
- Different satellites can be selected
- Error handling works properly

## Benefits

1. **Catch Regressions:** Detect when demo breaks
2. **CI Integration:** Automated verification
3. **Documentation:** Tests show proper usage
4. **Confidence:** Safe to refactor library

## Additional Context

- Affects: `EphemerisDemo` target
- Priority: **Low** - Quality improvement
- Effort: **2-3 hours**
- Related to: Issue #15 (expand test coverage)

## References

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [UI Testing](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [iOS Testing Best Practices](https://developer.apple.com/videos/play/wwdc2019/413/)

## Acceptance Criteria

- [ ] Test target created for demo app
- [ ] Minimum 4 smoke tests added
- [ ] App launch test passes
- [ ] TLE loading test passes
- [ ] UI elements test passes
- [ ] Tests run in CI pipeline
- [ ] Tests run on simulator successfully
- [ ] README updated with testing instructions
