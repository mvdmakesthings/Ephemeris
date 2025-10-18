---
title: "Add Swift Package Manager support"
labels: ["enhancement", "distribution"]
---

## Description

The Ephemeris framework currently only supports Xcode projects. Adding Swift Package Manager (SPM) support would make it easier for developers to integrate the library into their projects.

## Current State

- ✅ Xcode project (`.xcodeproj`)
- ❌ No `Package.swift`
- ❌ Not listed on Swift Package Index
- ❌ Cannot be used with SPM-based projects

## Benefits of SPM Support

1. **Easier Integration:** Simple one-line dependency declaration
2. **Version Management:** Semantic versioning and dependency resolution
3. **Cross-Platform:** Potential for macOS, Linux support
4. **Modern Standard:** SPM is Apple's recommended package manager
5. **Discoverability:** Can be listed on Swift Package Index
6. **CI/CD:** Better integration with automated workflows

## Proposed Implementation

### 1. Create Package.swift

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Ephemeris",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Ephemeris",
            targets: ["Ephemeris"]
        )
    ],
    dependencies: [
        // No external dependencies currently
    ],
    targets: [
        .target(
            name: "Ephemeris",
            dependencies: [],
            path: "Ephemeris",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "EphemerisTests",
            dependencies: ["Ephemeris"],
            path: "EphemerisTests",
            exclude: ["Info.plist"]
        )
    ]
)
```

### 2. Update Project Structure

Standard SPM structure (optional, can keep current structure):
```
Ephemeris/
├── Package.swift
├── Sources/
│   └── Ephemeris/
│       ├── Orbit.swift
│       ├── Orbitable.swift
│       ├── TwoLineElement.swift
│       └── Utilities/
│           └── ...
├── Tests/
│   └── EphemerisTests/
│       └── ...
├── README.md
└── LICENSE.md
```

Or keep current structure and point SPM to existing paths (recommended for backward compatibility).

### 3. Update CI/CD

Add SPM build and test to GitHub Actions:

```yaml
# .github/workflows/spm.yml
name: Swift Package

on: [push, pull_request]

jobs:
  test:
    name: Test SPM
    strategy:
      matrix:
        os: [macos-latest]
        swift: ["5.5", "5.9"]
    runs-on: ${{ matrix.os }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Select Swift version
      run: |
        sudo xcode-select -s /Applications/Xcode_${{ matrix.swift }}.app/Contents/Developer
        swift --version
    
    - name: Build
      run: swift build
    
    - name: Test
      run: swift test
```

### 4. Update Documentation

**README.md:**
```markdown
## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mvdmakesthings/Ephemeris.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Packages...
2. Enter: `https://github.com/mvdmakesthings/Ephemeris.git`
3. Select version and click "Add Package"

### Xcode Project

Alternatively, you can add the Xcode project as a submodule or framework.
```

### 5. Version Tagging

Create semantic version tags:
```bash
git tag -a v1.0.0 -m "Initial SPM release"
git push origin v1.0.0
```

## Testing SPM Support

Test that the package works:

```bash
# Clone to a test directory
git clone https://github.com/mvdmakesthings/Ephemeris.git test-spm
cd test-spm

# Build with SPM
swift build

# Run tests
swift test

# Test in a sample project
mkdir TestProject && cd TestProject
swift package init --type executable
# Add Ephemeris as dependency
swift build
```

## Migration Path

1. ✅ Create `Package.swift` (maintains backward compatibility)
2. ✅ Verify Xcode project still works
3. ✅ Update CI to test both Xcode and SPM builds
4. ✅ Update documentation
5. ✅ Create release tag
6. ✅ Submit to Swift Package Index (optional)

## Considerations

### Keep Both?

**Yes, recommend keeping both:**
- Xcode project for demo app and development
- SPM for library distribution
- Many projects successfully maintain both

### Breaking Changes?

**No breaking changes:**
- Existing Xcode users unaffected
- SPM is additive functionality
- Same source files used

### Demo App?

**Keep separate:**
- Demo app remains Xcode-only
- SPM package only includes framework
- Can add example project in `Examples/` directory

## Related Issues

- Issue #35 (Document deployment targets)

## Priority

**Medium** - High value for users, moderate implementation effort

## Acceptance Criteria

- [ ] Package.swift created and tested
- [ ] Swift build works
- [ ] Swift test works  
- [ ] Xcode project still works (backward compatibility)
- [ ] CI tests both Xcode and SPM builds
- [ ] README updated with SPM installation instructions
- [ ] Version tag created for release
- [ ] Verified on different platforms (macOS, iOS simulator)
- [ ] Consider submitting to Swift Package Index

## Resources

- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Swift Package Index](https://swiftpackageindex.com)
- [Creating a Swift Package](https://developer.apple.com/documentation/xcode/creating_a_standalone_swift_package_with_xcode)
