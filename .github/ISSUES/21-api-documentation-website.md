---
title: "Set up automated API documentation generation with Jazzy"
labels: ["documentation", "ci-cd", "enhancement"]
---

## Description

The Ephemeris framework lacks a generated API documentation website. Users must read the source code to understand the API. Setting up automated documentation generation would significantly improve usability.

## Current Behavior

- No hosted API documentation
- Users must read Swift files directly
- No searchable API reference
- Difficult for new users to discover functionality

**Impact:**
- High barrier to entry for new users
- Reduced adoption
- Repeated questions about API usage
- Poor discoverability of features

## Expected Behavior

Automated API documentation similar to:
- Apple's documentation: https://developer.apple.com/documentation/
- Third-party example: https://realm.github.io/SwiftLint/

## Proposed Solution

Use [Jazzy](https://github.com/realm/jazzy) to generate documentation:

### Step 1: Install Jazzy

```bash
gem install jazzy
# or
brew install jazzy
```

### Step 2: Create Configuration

Create `.jazzy.yaml`:

```yaml
module: Ephemeris
author: Michael VanDyke
author_url: https://github.com/mvdmakesthings
github_url: https://github.com/mvdmakesthings/Ephemeris
github_file_prefix: https://github.com/mvdmakesthings/Ephemeris/tree/master
root_url: https://mvdmakesthings.github.io/Ephemeris/

# Use Xcode project
xcodebuild_arguments:
  - -project
  - Ephemeris.xcodeproj
  - -scheme
  - Ephemeris

# Output
output: docs
clean: true

# Theme
theme: fullwidth

# Documentation coverage
min_acl: public
skip_undocumented: false
hide_documentation_coverage: false

# Custom categories
custom_categories:
  - name: Core Types
    children:
      - Orbit
      - Orbitable
      - TwoLineElement
      
  - name: Physical Constants
    children:
      - PhysicalConstants
      
  - name: Utilities
    children:
      - Date+julian
      - Double+angles
      - StringProtocol+subscript

# Exclude internal/private
exclude:
  - "*/Internal/*"
```

### Step 3: Add Generation Script

Create `scripts/generate-docs.sh`:

```bash
#!/bin/bash
set -e

echo "Generating API documentation with Jazzy..."

# Generate docs
jazzy \
  --clean \
  --module Ephemeris \
  --output docs \
  --theme fullwidth \
  --min-acl public

echo "✓ Documentation generated in docs/"
echo "  Open docs/index.html in browser"
```

### Step 4: Add to CI/CD

Update `.github/workflows/ci.yml`:

```yaml
- name: Generate Documentation
  run: |
    gem install jazzy
    ./scripts/generate-docs.sh
    
- name: Deploy to GitHub Pages
  if: github.ref == 'refs/heads/master'
  uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./docs
```

### Step 5: Enable GitHub Pages

In repository settings:
1. Go to Settings → Pages
2. Source: Deploy from a branch
3. Branch: `gh-pages`
4. Path: `/` (root)

## Documentation Structure

Generated site will include:

```
docs/
├── index.html              # Landing page
├── Classes/
│   ├── Orbit.html         # Orbit documentation
│   └── TwoLineElement.html
├── Protocols/
│   └── Orbitable.html
├── Extensions/
│   ├── Date.html
│   └── Double.html
├── Structs/
│   └── PhysicalConstants.html
└── search.json            # Search index
```

## Example Documentation

With proper Swift doc comments, Jazzy generates:

```swift
/// Represents a satellite orbit with Keplerian elements.
///
/// The `Orbit` struct encapsulates the six classical orbital elements
/// and provides methods to calculate satellite positions over time.
///
/// Example usage:
/// ```swift
/// let tle = try TwoLineElement(from: tleString)
/// let orbit = try Orbit(tle: tle)
/// let position = orbit.position(at: Date())
/// ```
///
/// - Important: All angles are in degrees unless specified otherwise.
/// - SeeAlso: `TwoLineElement`, `Orbitable`
public struct Orbit: Orbitable {
    /// The semi-major axis in kilometers.
    ///
    /// Valid range: Greater than Earth's radius (6378.137 km)
    public let semimajorAxis: Double
}
```

Jazzy output includes:
- Method signatures
- Parameter descriptions
- Return values
- Examples
- Cross-references
- Search functionality

## Benefits

1. **Discoverability:** Users can browse and search the API
2. **Examples:** Code examples are formatted and highlighted
3. **Navigation:** Easy to explore related types
4. **Versioning:** Document each release version
5. **Professional:** Polished presentation

## Alternative Tools

- **DocC** (Apple's tool): Xcode 13+, integrated with Xcode
- **SourceDocs**: Alternative to Jazzy
- **SwiftDoc**: Another documentation generator

**Recommendation:** Jazzy is the most mature and widely used.

## Additional Context

- Priority: **Low** - Nice-to-have enhancement
- Effort: **4-6 hours** initial setup
- Maintenance: **Automated** via CI
- Prerequisite: Issue #10 (add API documentation comments)

## References

- [Jazzy](https://github.com/realm/jazzy)
- [DocC](https://developer.apple.com/documentation/docc)
- [NSHipster: Swift Documentation](https://nshipster.com/swift-documentation/)

## Acceptance Criteria

- [ ] Jazzy installed and configured
- [ ] `.jazzy.yaml` configuration file created
- [ ] Documentation generation script added
- [ ] CI workflow generates documentation
- [ ] Documentation deployed to GitHub Pages
- [ ] Hosted documentation accessible at github.io
- [ ] README updated with documentation link
- [ ] Documentation covers all public APIs
- [ ] Search functionality works
- [ ] Examples render correctly
