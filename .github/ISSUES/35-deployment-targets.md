---
title: "Document iOS/macOS deployment targets and compatibility"
labels: ["documentation", "good-first-issue", "compatibility"]
---

## Description

The repository does not clearly document which iOS and macOS versions are supported. This makes it difficult for users to know if the framework is compatible with their projects.

## Current Behavior

- No documented minimum iOS version
- No documented minimum macOS version
- No documented Swift version requirement
- Xcode project may have default targets
- No compatibility information in README

**Impact:**
- Users unsure if framework will work for their project
- May attempt to use with incompatible versions
- No guidance for contributors
- Unclear support policy

## Expected Behavior

Clear documentation of supported platforms and versions:

```markdown
## Requirements

- iOS 13.0+ / macOS 10.15+
- Xcode 14.0+
- Swift 5.7+

## Compatibility

| iOS | macOS | tvOS | watchOS | Swift |
|-----|-------|------|---------|-------|
| 13+ | 10.15+| 13+  | 6+      | 5.7+  |
```

## Information to Document

### 1. Minimum Deployment Targets

**iOS:**
- Minimum version: iOS 13.0 (recommended)
- Rationale: SwiftUI support, modern Swift features

**macOS:**
- Minimum version: macOS 10.15 Catalina (recommended)
- Rationale: Matches iOS 13 feature parity

**Other Platforms:**
- tvOS: iOS equivalent
- watchOS: iOS equivalent (if applicable)
- Catalyst: Document if supported

### 2. Swift Version

```swift
// Minimum Swift version
#if swift(<5.7)
#error("Ephemeris requires Swift 5.7 or later")
#endif
```

### 3. Xcode Version

- Minimum: Xcode 14.0
- Recommended: Latest stable

### 4. Feature Availability

Document features requiring newer versions:

```markdown
### Platform-Specific Features

**iOS 15.0+ / macOS 12.0+:**
- Async/await support (when implemented)

**iOS 13.0+:**
- All core orbital calculations
- TLE parsing
- Position determination
```

## Proposed Solution

### Step 1: Set Xcode Project Targets

In `Ephemeris.xcodeproj`:

1. Select target → General
2. Set Deployment Target:
   - iOS: 13.0
   - macOS: 10.15

### Step 2: Update README

Add Requirements section:

```markdown
# Ephemeris

Satellite tracking framework for iOS and macOS.

## Requirements

- **iOS:** 13.0 or later
- **macOS:** 10.15 (Catalina) or later
- **Xcode:** 14.0 or later
- **Swift:** 5.7 or later

## Installation

### Xcode Project

1. Drag `Ephemeris.xcodeproj` into your project
2. Add Ephemeris framework to your target
3. Import: `import Ephemeris`

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/mvdmakesthings/Ephemeris.git", from: "1.0.0")
]
```

## Platform Support

| Platform | Minimum Version | Status |
|----------|----------------|---------|
| iOS      | 13.0           | ✅ Supported |
| macOS    | 10.15          | ✅ Supported |
| tvOS     | 13.0           | ⚠️ Untested |
| watchOS  | 6.0            | ⚠️ Untested |
| Linux    | -              | ❌ Not supported |

## Feature Compatibility

All core features work on iOS 13.0+ and macOS 10.15+:
- ✅ TLE parsing
- ✅ Orbital calculations
- ✅ Position determination
- ✅ Date utilities
- ✅ Orbital elements

Future features may require newer versions:
- Async/await: iOS 15.0+, macOS 12.0+ (planned)
```

### Step 3: Add to Framework Info.plist

Document minimum versions in Info.plist metadata.

### Step 4: Add Swift Version Check

In a core file (e.g., `Ephemeris.swift`):

```swift
//
//  Ephemeris.swift
//  Ephemeris
//
//  Copyright © 2024 Michael VanDyke. All rights reserved.
//

import Foundation

// Require Swift 5.7 or later
#if swift(<5.7)
#error("Ephemeris requires Swift 5.7 or later")
#endif

/// Ephemeris framework version
public enum EphemerisVersion {
    /// Framework version string
    public static let version = "1.0.0"
    
    /// Minimum iOS version required
    public static let minimumIOSVersion = "13.0"
    
    /// Minimum macOS version required
    public static let minimumMacOSVersion = "10.15"
    
    /// Swift version used to build
    public static let swiftVersion = "5.7"
}
```

### Step 5: Document in Contributing Guide

Add to `CONTRIBUTING.md`:

```markdown
## Development Requirements

### System Requirements

- macOS Monterey (12.0) or later
- Xcode 14.0 or later
- Swift 5.7 or later

### Target Requirements

The framework supports:
- iOS 13.0+
- macOS 10.15+

When contributing:
1. Ensure code compiles for minimum versions
2. Don't use APIs newer than minimum target
3. Use availability checks for optional features:

```swift
if #available(iOS 15.0, macOS 12.0, *) {
    // Use newer API
} else {
    // Fallback for older versions
}
```
```

### Step 6: Add CI Matrix (Optional)

Test multiple versions in CI:

```yaml
# .github/workflows/ci.yml
strategy:
  matrix:
    xcode: ['14.0', '14.3', '15.0']
    destination:
      - 'platform=iOS Simulator,name=iPhone 13,OS=15.0'
      - 'platform=iOS Simulator,name=iPhone 14,OS=16.0'
      - 'platform=macOS'
```

## Decision Points

### Should We Support Older Versions?

**iOS 13.0 (2019):**
- ✅ Covers 95%+ of active devices
- ✅ Modern Swift features
- ✅ Not too restrictive

**iOS 12.0 or earlier:**
- ❌ Very old (2018)
- ❌ Limited Swift features
- ❌ Few users remaining

**Recommendation:** iOS 13.0+ is a good balance

### What About Linux?

The framework uses Foundation only, so Linux *could* be supported with Swift Package Manager. However:

- Different date handling
- No Xcode project structure
- Would need testing on Linux
- Limited use case for satellite tracking on Linux

**Recommendation:** Document as "not currently supported, contributions welcome"

## Testing Compatibility

```swift
#if os(iOS)
import UIKit

@available(iOS 13.0, *)
func testIOSFeature() {
    // iOS-specific test
}
#endif

#if os(macOS)
import AppKit

@available(macOS 10.15, *)
func testMacOSFeature() {
    // macOS-specific test
}
#endif
```

## Additional Context

- Priority: **Low** - Documentation improvement
- Effort: **30-60 minutes**
- Impact: **Medium** - Clarity for users
- Related to: Issue #22 (Contributing guide), Issue #34 (SPM support)

## Benefits

1. **Clarity:** Users know if framework will work
2. **Planning:** Users can plan upgrades
3. **Support:** Clear support boundaries
4. **Professional:** Shows mature project management
5. **Contributions:** Contributors know requirements

## Acceptance Criteria

- [ ] Xcode project deployment targets set
- [ ] README documents minimum versions
- [ ] README documents Swift/Xcode requirements
- [ ] Platform support matrix added
- [ ] Swift version check added to code
- [ ] CONTRIBUTING.md includes requirements
- [ ] Info.plist metadata updated
- [ ] CI tests verify minimum versions (optional)
- [ ] Feature availability documented
