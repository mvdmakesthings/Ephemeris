---
title: "Add comprehensive code examples to README"
labels: ["documentation", "good-first-issue"]
---

## Description

The README currently lacks code examples showing how to use the Ephemeris library. Potential users need to read the source code to understand how to use the framework.

## Current State

**README.md** contains:
- ✅ Project description
- ✅ CI badge
- ✅ Academic references
- ❌ No installation instructions
- ❌ No usage examples
- ❌ No API overview
- ❌ No quick start guide

## User Pain Points

New users need to:
1. Browse through test files to see usage
2. Check the demo app implementation
3. Guess at the API from source code
4. No guidance on common use cases

## Proposed Examples

### 1. Quick Start

```markdown
## Quick Start

### Parsing TLE Data

Two-Line Element (TLE) data is the standard format for satellite orbital information. Here's how to parse it:

\`\`\`swift
import Ephemeris

// TLE data for the International Space Station
let tleString = """
ISS (ZARYA)
1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
"""

// Parse the TLE
let tle = TwoLineElement(from: tleString)

// Access orbital parameters
print("Satellite: \(tle.name)")
print("Inclination: \(tle.inclination)°")
print("Eccentricity: \(tle.eccentricity)")
\`\`\`

### Creating an Orbit

\`\`\`swift
// Create an Orbit from the TLE
let orbit = Orbit(from: tle)

// Access orbital elements
print("Semi-major axis: \(orbit.semimajorAxis) km")
print("Orbital period: ~\(1440.0 / orbit.meanMotion) minutes")
\`\`\`

### Calculating Position

\`\`\`swift
// Calculate satellite position at current time
do {
    let position = try orbit.calculatePosition(at: Date())
    print("Latitude: \(position.x)°")
    print("Longitude: \(position.y)°")
    print("Altitude: \(position.z) km")
} catch {
    print("Error calculating position: \(error)")
}

// Calculate position at a future time
let oneHourFromNow = Date().addingTimeInterval(3600)
let futurePosition = try orbit.calculatePosition(at: oneHourFromNow)
\`\`\`

### Tracking Over Time

\`\`\`swift
// Track satellite positions over the next hour
let startTime = Date()
var positions: [(date: Date, latitude: Double, longitude: Double)] = []

for minutes in stride(from: 0, through: 60, by: 5) {
    let time = startTime.addingTimeInterval(TimeInterval(minutes * 60))
    if let position = try? orbit.calculatePosition(at: time) {
        positions.append((time, position.x, position.y))
    }
}

// Print the ground track
for (date, lat, lon) in positions {
    print("\(date): \(lat)°, \(lon)°")
}
\`\`\`
```

### 2. Common Use Cases

```markdown
## Common Use Cases

### Finding Next Pass Over Location

\`\`\`swift
// User's location
let observerLat = 37.7749  // San Francisco
let observerLon = -122.4194

// Check if satellite is visible
func isVisible(position: (x: Double, y: Double, z: Double)) -> Bool {
    let distance = calculateDistance(
        from: (observerLat, observerLon),
        to: (position.x, position.y)
    )
    return distance < 1000 // Within 1000km
}

// Find next pass (simplified example)
var currentTime = Date()
let checkInterval: TimeInterval = 60 // Check every minute

for _ in 0..<1440 { // Check for 24 hours
    if let position = try? orbit.calculatePosition(at: currentTime),
       isVisible(position: position) {
        print("Satellite visible at \(currentTime)")
        break
    }
    currentTime.addTimeInterval(checkInterval)
}
\`\`\`

### Getting Fresh TLE Data

\`\`\`swift
// TLE data should be updated regularly for accuracy
// Get fresh data from sources like:
// - https://celestrak.org/
// - https://www.space-track.org/

func fetchLatestTLE(for satelliteId: String) async throws -> TwoLineElement {
    // Implementation depends on your TLE source
    let url = URL(string: "https://celestrak.org/NORAD/elements/gp.php?CATNR=\(satelliteId)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    let tleString = String(data: data, encoding: .utf8)!
    return TwoLineElement(from: tleString)
}
\`\`\`
```

### 3. Integration Examples

```markdown
## Integration Examples

### MapKit Integration

See the included demo app for a complete example of displaying satellite tracks on a map using MapKit.

### Core Location Integration

\`\`\`swift
import CoreLocation
import Ephemeris

// Convert satellite position to CLLocationCoordinate2D
let orbit = Orbit(from: tle)
let position = try orbit.calculatePosition(at: Date())

let coordinate = CLLocationCoordinate2D(
    latitude: position.x,
    longitude: position.y
)

// Use with MapKit, annotations, etc.
\`\`\`
```

### 4. Important Notes

```markdown
## Important Notes

### TLE Data Accuracy

TLE data degrades over time. For accurate predictions:
- Update TLE data regularly (daily for LEO satellites)
- Use recent epoch dates (within days, not weeks)
- Be aware of perturbations not modeled in SGP4

### Coordinate Systems

The position returned by `calculatePosition(at:)` uses:
- **Latitude**: -90° (South Pole) to +90° (North Pole)
- **Longitude**: -180° (West) to +180° (East)
- **Altitude**: Kilometers above Earth's surface

### Time Zones

All calculations use UTC time internally. Make sure to convert to UTC:

\`\`\`swift
// Using Date() gives current UTC time
let position = try orbit.calculatePosition(at: Date())

// For specific times, ensure UTC
var calendar = Calendar.current
calendar.timeZone = TimeZone(identifier: "UTC")!
var components = DateComponents()
components.year = 2024
components.month = 1
components.day = 1
components.hour = 12
let utcDate = calendar.date(from: components)!
\`\`\`
```

## Additional Sections Needed

### Before Quick Start

```markdown
## Installation

### Swift Package Manager (Recommended)

Coming soon - see Issue #34

### Manual Installation

1. Download the latest release
2. Drag `Ephemeris.xcodeproj` into your Xcode project
3. Add Ephemeris framework to your target's dependencies
```

### After Examples

```markdown
## API Reference

For detailed API documentation, see:
- [Online Documentation](link-when-available)
- Inline documentation in source files
- Demo app in `EphemerisDemo/`

## Resources

### Where to Get TLE Data

- [Celestrak](https://celestrak.org/) - Public satellite TLEs
- [Space-Track.org](https://www.space-track.org/) - Official US Space Force catalog (registration required)
- [N2YO](https://www.n2yo.com/) - Real-time satellite tracking

### Understanding Orbital Mechanics

See the extensive list of academic resources in our README.
```

## Related Issues

- Issue #34 (SPM support - affects installation instructions)
- Issue #21 (API documentation generation)

## Priority

**Low** - Important for user experience but not critical

## Acceptance Criteria

- [ ] README includes installation instructions
- [ ] Quick start example with basic TLE parsing
- [ ] Position calculation example
- [ ] MapKit integration example
- [ ] Common use cases documented
- [ ] Important notes about accuracy and coordinate systems
- [ ] Links to TLE data sources
- [ ] Code examples tested and verified
- [ ] Examples match current API

## Notes

- Examples should work with current API (after Issue #1 is fixed, update examples to use `try`)
- Keep examples simple and focused
- Link to demo app for more complex examples
- Update examples when API changes
