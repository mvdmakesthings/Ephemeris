# Ephemeris

[![CI](https://github.com/mvdmakesthings/Ephemeris/workflows/CI/badge.svg)](https://github.com/mvdmakesthings/Ephemeris/actions)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE.md)
[![Platform](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20visionOS-lightgrey.svg)](https://developer.apple.com/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)

A Swift framework for satellite tracking and orbital mechanics calculations. Ephemeris provides tools to parse Two-Line Element (TLE) data and calculate orbital positions for Earth-orbiting satellites.

**Dual-Purpose Design**: Ephemeris serves both as a practical Swift framework for iOS developers building satellite tracking apps and as an educational tool for learning orbital mechanics through hands-on implementation. Each feature is documented with both mathematical foundations and Swift code examples.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Documentation](#documentation)
- [For AI Tools and Developers](#for-ai-tools-and-developers)
- [CI/CD](#cicd)
- [Contributing](#contributing)
- [References](#references)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Features

- 📡 **TLE and OMM Parsing**: Read NORAD Two-Line Elements and CCSDS Orbit Mean-Elements Messages (JSON, XML, KVN, CSV), the modern format with no catalog-number limit
- 🛰️ **SGP4/SDP4 Propagation**: Pure Swift port of the standard TLE propagator, including deep-space lunar-solar and resonance terms, verified against Vallado's published test vectors
- 📘 **Two-Body Orbits**: A simple Keplerian propagator for learning the underlying math
- 🌍 **Position Tracking**: Compute latitude, longitude, and altitude for satellites at any given time
- 👁️ **Observer-Based Tracking**: Calculate azimuth, elevation, range, and range rate from any location on Earth
- 🔭 **Pass Prediction**: Predict satellite passes with AOS, maximum elevation, and LOS times
- 🗂️ **Whole Catalogs**: Load thousands of satellites from a TLE or OMM document and ask what is overhead, where everything is, or what passes over you, using every CPU core
- ⬇️ **CelesTrak Downloads** (`EphemerisCatalog`): Fetch groups or single satellites with no account, with a disk cache, shared requests, pacing and backoff so your app stays a good citizen
- 📐 **Orbital Elements**: Support for all standard Keplerian orbital elements:
  - Semi-major axis
  - Eccentricity
  - Inclination
  - Right Ascension of Ascending Node (RAAN)
  - Argument of Perigee
  - Mean Anomaly and True Anomaly
- 🌐 **Coordinate Transformations**: ECI ↔ ECEF ↔ ENU coordinate system conversions
- 🌫️ **Atmospheric Refraction**: Optional correction for low-elevation observations
- ⏰ **Time Conversions**: Julian date and Greenwich Sidereal Time calculations
- 🔢 **High Precision**: Iterative algorithms for eccentric anomaly calculations

## Requirements

- iOS 16.0+ / macOS 13.0+ / watchOS 9.0+ / tvOS 16.0+ / visionOS 1.0+
- Swift 6.0+

**Platform Support Policy:** Ephemeris follows a "current minus two" support policy, supporting the current OS version minus two releases for broad compatibility while maintaining access to modern APIs.

## Installation

### Swift Package Manager

Add Ephemeris to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/mvdmakesthings/Ephemeris.git", from: "2.0.0")
]
```

Then add it to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "Ephemeris", package: "Ephemeris"),
            // Optional: download and cache catalogs from CelesTrak
            .product(name: "EphemerisCatalog", package: "Ephemeris")
        ]
    )
]
```

`Ephemeris` is the core library and never touches the network. `EphemerisCatalog` adds
`CelesTrakClient`, which downloads element sets with caching and rate limits built in.

Or in Xcode:

1. File → Add Packages...
2. Enter: `https://github.com/mvdmakesthings/Ephemeris.git`
3. Select version and click "Add Package"

### Manual Integration

1. Download the source code
2. Drag the `Ephemeris` folder into your Xcode project
3. Ensure the files are added to your target

## Usage

### Quick Start

```swift
import Ephemeris

// TLE data for the International Space Station (ISS)
let tleString = """
ISS (ZARYA)
1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
"""

// Parse the TLE data
do {
    let tle = try TwoLineElement(from: tleString)
    print("Satellite: \(tle.name)")
    
    // Create an SGP4 propagator from the TLE
    let sgp4 = try SGP4(tle: tle)

    // Calculate current position
    let position = try sgp4.calculatePosition(at: Date())
    print("Latitude: \(position.latitudeDeg)°")
    print("Longitude: \(position.longitudeDeg)°")
    print("Altitude: \(position.altitudeKm) km")
} catch {
    print("Error: \(error)")
}
```

### Choosing a Propagator

Both propagators conform to `Propagator`, so position, look angles, pass prediction, ground tracks and sky tracks work the same way with either one.

- **`SGP4`**: Use this for real tracking. TLEs are mean elements fitted with SGP4, so it's the only model that reproduces the orbit they describe. It includes Earth's oblateness, drag and, for periods of 225 minutes or more, lunar and solar gravity.
- **`KeplerianOrbit`**: Two-body Keplerian motion. It's great for learning how orbital elements work, but it ignores oblateness and drag, so a low-orbit satellite drifts hundreds of kilometers from reality within a day.

```swift
let sgp4 = try SGP4(tle: tle)

// Inertial (TEME) position and velocity 90 minutes after the TLE epoch
let state = try sgp4.propagate(minutesSinceEpoch: 90)
print("Position: \(state.position) km")
print("Velocity: \(state.velocity) km/s")

// Look angles and passes for an observer
let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
let lookAngles = try sgp4.topocentric(at: Date(), for: observer)
let passes = try sgp4.predictPasses(for: observer, from: Date(), to: Date().addingTimeInterval(86400))
```

### Accessing Orbital Elements

The classical elements live on `KeplerianOrbit`, which reads them straight from the TLE:

```swift
let orbit = KeplerianOrbit(tle: tle)

// Access orbital parameters
print("Semi-major axis: \(orbit.semimajorAxis) km")
print("Eccentricity: \(orbit.eccentricity)")
print("Inclination: \(orbit.inclination)°")
print("RAAN: \(orbit.rightAscensionOfAscendingNode)°")
print("Argument of Perigee: \(orbit.argumentOfPerigee)°")
print("Mean Anomaly: \(orbit.meanAnomaly)°")
print("Mean Motion: \(orbit.meanMotion) revolutions/day")
print("True Anomaly now: \(orbit.trueAnomaly(at: Date()))°")
print("Apogee: \(orbit.apogeeAltitude) km, Perigee: \(orbit.perigeeAltitude) km")
print("Period: \(orbit.orbitalPeriod / 60) minutes")
```

### Calculate Position at Specific Time

```swift
// Create a specific date
let calendar = Calendar.current
let components = DateComponents(year: 2020, month: 4, day: 15, hour: 12, minute: 0)
let specificDate = calendar.date(from: components)

// Calculate position at that time
if let date = specificDate {
    let position = try sgp4.calculatePosition(at: date)
    print("At \(date):")
    print("  Latitude: \(position.latitudeDeg)°")
    print("  Longitude: \(position.longitudeDeg)°")
    print("  Altitude: \(position.altitudeKm) km")
}
```

### Track Satellite Over Time

```swift
import Foundation

// Track satellite position every minute for an hour
let startTime = Date()
let timeInterval: TimeInterval = 60 // seconds

for i in 0..<60 {
    let time = startTime.addingTimeInterval(Double(i) * timeInterval)
    
    do {
        let position = try sgp4.calculatePosition(at: time)
        print("T+\(i) min: \(position.latitudeDeg)°, \(position.longitudeDeg)°, \(position.altitudeKm) km")
    } catch {
        print("Error calculating position: \(error)")
    }
}
```

### Multiple Satellites

For a handful of satellites, build one `SGP4` each. For a whole catalog (the 10,000+
active satellites CelesTrak publishes), use `SatelliteCatalog`, which loads a TLE or OMM
document, skips bad entries, and runs queries on every CPU core:

```swift
// Download (or load from cache) every amateur radio satellite
let client = CelesTrakClient(appIdentifier: "MyTracker/1.0")   // import EphemerisCatalog
let catalog = try await client.catalog(for: .group(.amateur)).catalog
print("Loaded \(catalog.satellites.count), rejected \(catalog.rejections.count)")

// What is above 10° right now? (highest first)
let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
let overhead = await catalog.lookAngles(from: observer, at: Date(), minElevationDeg: 10)
for item in overhead {
    print(item.satellite.name, item.topocentric.azimuthDeg, item.topocentric.elevationDeg)
}

// Every pass in the next hour, in order of rise time
let now = Date()
let passes = await catalog.passes(for: observer, from: now, to: now.addingTimeInterval(3600))
```

See [Working With Whole Catalogs](./docs/catalogs.md) for the details, including how to
download catalog data without overloading the public servers.

### Error Handling

```swift
// Comprehensive error handling
let tleString = """
SATELLITE NAME
1 12345U 20001A   20100.50000000  .00001234  00000-0  12345-4 0  9995
2 12345  51.6400  90.0000 0001000  45.0000  90.0000 15.50000000123457
"""

do {
    let tle = try TwoLineElement(from: tleString)
    let sgp4 = try SGP4(tle: tle)
    let position = try sgp4.calculatePosition(at: Date())
    
    print("Successfully calculated position: \(position.latitudeDeg)°, \(position.longitudeDeg)°")
    
} catch TLEParsingError.invalidFormat(let message) {
    print("Invalid TLE format: \(message)")
} catch TLEParsingError.invalidChecksum(let line, let expected, let actual) {
    print("Checksum error on line \(line): expected \(expected), got \(actual)")
} catch TLEParsingError.invalidNumber(let field, let value) {
    print("Invalid number in field '\(field)': \(value)")
} catch TLEParsingError.invalidEccentricity(let value) {
    print("Eccentricity \(value) is outside 0 ≤ e < 1")
} catch let error as SGP4Error {
    // For example .decayed when the orbit has dropped into the atmosphere
    print("SGP4 error \(error.code): \(error.localizedDescription)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Working with Julian Dates and Sidereal Time

```swift
import Foundation

// Convert the current date to a Julian Date
let julianDate = Date().julianDate
print("Current Julian Date: \(julianDate)")

// Greenwich Mean Sidereal Time
let gmst = Date.greenwichMeanSiderealTime(julianDate: julianDate)
print("Greenwich Mean Sidereal Time: \(gmst) radians")

// The same value straight from a Date
print("GMST now: \(Date().greenwichMeanSiderealTime) radians")

// Julian centuries since J2000
let centuries = Date.julianCenturiesSinceJ2000(julianDate: julianDate)
print("Julian centuries since J2000: \(centuries)")

// A TLE epoch is already a Date
let tle = try TwoLineElement(from: tleString)
print("TLE epoch: \(tle.epoch), Julian Date \(tle.epoch.julianDate)")
```

### Predict Satellite Passes

Calculate when and where a satellite will be visible from your location:

```swift
import Ephemeris

// Parse ISS TLE
let tleString = """
ISS (ZARYA)
1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
"""
let tle = try TwoLineElement(from: tleString)
let sgp4 = try SGP4(tle: tle)

// Define your observer location (Louisville, Kentucky)
let observer = Observer(
    latitudeDeg: 38.2542,    // Latitude (positive = north)
    longitudeDeg: -85.7594,  // Longitude (positive = east)
    altitudeMeters: 140      // Altitude above sea level
)

// Predict passes over the next 24 hours
let now = Date()
let tomorrow = now.addingTimeInterval(24 * 3600)

let passes = try sgp4.predictPasses(
    for: observer,
    from: now,
    to: tomorrow,
    minElevationDeg: 10.0,  // Only passes above 10° elevation
    stepSeconds: 30          // Search granularity
)

// Display results
for (i, pass) in passes.enumerated() {
    print("\nPass #\(i + 1)")
    print("AOS: \(pass.aos.time)")
    print("  Azimuth: \(pass.aos.azimuthDeg)°")
    print("MAX: \(pass.culmination.time)")
    print("  Elevation: \(pass.culmination.elevationDeg)°")
    print("  Azimuth: \(pass.culmination.azimuthDeg)°")
    print("LOS: \(pass.los.time)")
    print("  Azimuth: \(pass.los.azimuthDeg)°")
    print("Duration: \(Int(pass.duration)) seconds")
    if pass.beginsBeforeSearch || pass.endsAfterSearch {
        print("(Pass is cut off by the search window)")
    }
}
```

### Calculate Topocentric Coordinates

Get azimuth, elevation, and range for a satellite at any time:

```swift
// Calculate current look angles
let topo = try sgp4.topocentric(at: Date(), for: observer)

print("Satellite Position:")
print("  Azimuth: \(topo.azimuthDeg)°")        // Direction (0° = North, 90° = East)
print("  Elevation: \(topo.elevationDeg)°")    // Angle above horizon
print("  Range: \(topo.rangeKm) km")           // Distance to satellite
print("  Range Rate: \(topo.rangeRateKmPerSec) km/s")  // Approaching/receding

// Apply atmospheric refraction correction for low elevations
let topoRefracted = try sgp4.topocentric(
    at: Date(),
    for: observer,
    applyRefraction: true
)
print("Apparent Elevation (with refraction): \(topoRefracted.elevationDeg)°")
```

### Custom Satellite Analysis

```swift
// Analyze orbital characteristics
func analyzeOrbit(_ orbit: KeplerianOrbit) {
    let earthRadius = PhysicalConstants.Earth.semiMajorAxis

    // Apogee and perigee altitudes (KeplerianOrbit also has
    // apogeeAltitude and perigeeAltitude for this)
    let apogee = orbit.semimajorAxis * (1 + orbit.eccentricity) - earthRadius
    let perigee = orbit.semimajorAxis * (1 - orbit.eccentricity) - earthRadius
    
    print("Orbital Analysis:")
    print("  Semi-major axis: \(orbit.semimajorAxis) km")
    print("  Eccentricity: \(orbit.eccentricity)")
    print("  Apogee altitude: \(apogee) km")
    print("  Perigee altitude: \(perigee) km")
    print("  Inclination: \(orbit.inclination)°")
    
    // Determine orbit type
    if orbit.inclination < 10 {
        print("  Type: Equatorial orbit")
    } else if orbit.inclination > 80 && orbit.inclination < 100 {
        print("  Type: Polar orbit")
    } else {
        print("  Type: Inclined orbit")
    }
    
    // Calculate orbital period
    let mu = PhysicalConstants.Earth.mu
    let period = 2 * .pi * sqrt(pow(orbit.semimajorAxis, 3) / mu)
    print("  Orbital period: \(period / 60) minutes")
}

// Use the analyzer
let tle = try TwoLineElement(from: tleString)
let orbit = KeplerianOrbit(tle: tle)
analyzeOrbit(orbit)
```

## Documentation

Ephemeris documentation is designed to teach orbital mechanics through practical Swift implementation. Choose your learning path:

### 📚 Choose Your Path

#### 🚀 Quick Start: "I want to build an app NOW"
1. **[Getting Started Guide](./docs/getting-started.md)** - Build your first satellite tracker in 30 minutes
2. Jump to specific guides as needed

#### 🎓 Deep Dive: "I want to understand orbital mechanics"
1. **[Orbital Elements](./docs/orbital-elements.md)** - The six Keplerian elements with math and Swift
2. **[Element Sets: TLE and OMM](./docs/element-sets.md)** - What a published orbit is, and why OMM is replacing the TLE
3. **[Observer Geometry](./docs/observer-geometry.md)** - Coordinate transformations and pass prediction
4. **[Working With Whole Catalogs](./docs/catalogs.md)** - Thousands of satellites at once, visibility geometry, and fetching data responsibly
5. **[Visualization](./docs/visualization.md)** - Ground tracks, sky tracks, and iOS integration
6. **[Coordinate Transformations](./docs/coordinate-transformations.md)** - Deep dive into ECI, ECEF, and transformations

#### 🔍 Reference: "I need specific information"
- **[LLM.txt](./LLM.txt)** - Project context for AI tools

### 📖 Documentation Overview

**Theory + Practice Documents** (Math → Swift implementation):
- **[Orbital Elements](./docs/orbital-elements.md)** - Keplerian elements, TLE format, Kepler's equation, accuracy considerations
- **[Element Sets: TLE and OMM](./docs/element-sets.md)** - TLE and OMM formats compared, field by field, and how to load each
- **[Observer Geometry](./docs/observer-geometry.md)** - Coordinate transformations, topocentric calculations, pass prediction algorithms
- **[Working With Whole Catalogs](./docs/catalogs.md)** - Catalog loading and queries, which satellites can ever rise, concurrency, performance, and data etiquette
- **[Visualization](./docs/visualization.md)** - Ground tracks, sky tracks, SwiftUI Charts, and MapKit integration

**Practical Guides** (Code-focused):
- **[Getting Started](./docs/getting-started.md)** - Quick-start tutorial with complete examples

**Reference**:
- **[Coordinate Transformations](./docs/coordinate-transformations.md)** - Mathematical foundations of coordinate transformations

### Core Types

- **`TwoLineElement`**: Parses and represents NORAD TLE format satellite data
- **`SGP4`**: The SGP4/SDP4 propagator for TLE data, used for real tracking
- **`KeplerianOrbit`**: Classical orbital elements with a two-body propagator, used for learning
- **`Propagator`**: The protocol both propagators conform to, providing `stateVector(at:)`, `calculatePosition(at:)`, `topocentric(at:for:)`, `predictPasses(for:from:to:)`, `groundTrack(from:to:)` and `skyTrack(for:from:to:)`
- **`GeodeticPosition`**: Latitude, longitude and altitude above the WGS-84 ellipsoid (`latitudeDeg`, `longitudeDeg`, `altitudeKm`)
- **`Observer`**: Represents an Earth-based observer location (latitude, longitude, altitude)
- **`Topocentric`**: Contains azimuth, elevation, range, and range rate for observer-relative coordinates
- **`PassWindow`**: Describes a satellite pass with AOS, culmination (maximum elevation), and LOS events
- **`SatelliteCatalog`**: Many satellites loaded from a TLE or OMM document, with lookups and concurrent `positions(at:)`, `lookAngles(from:at:)` and `passes(for:from:to:)` queries
- **`CelesTrakClient`** (`EphemerisCatalog`): Downloads catalogs from CelesTrak with caching, pacing and backoff
- **`CatalogSatellite`**: One catalog entry: its element set, `SGP4` propagator, orbit regime and element-set age
- **`CoordinateTransforms`**: Utility functions for converting between coordinate systems (ECI, ECEF, ENU)

### Where to Get Orbit Data

Element sets (as TLE or OMM) can be obtained from:
- [CelesTrak](https://celestrak.org/NORAD/elements/) - Free, updated frequently. Add `&FORMAT=JSON` to a GP query for OMM
- [Space-Track.org](https://www.space-track.org/) - Official source (free registration required)
- [N2YO.com](https://www.n2yo.com/) - Real-time tracking and TLE data

These are free public services. `CelesTrakClient` caches, paces and backs off for you; if
you write your own downloader, fetch whole groups, cache what you download, and don't fetch
the same group more than once every couple of hours.
See [Getting Catalog Data Responsibly](./docs/catalogs.md#getting-catalog-data-responsibly).

### Key Concepts

**TLE Format**: Accepts both the three-line (name + data) and bare two-line forms, with any line endings. 2-digit epoch years follow the NORAD convention (57-99 → 1957-1999, 00-56 → 2000-2056), and Alpha-5 catalog numbers (e.g. `A0001` = 100001) are supported.

**OMM Format**: `OrbitMeanElementsMessage.parse(_:)` reads CelesTrak and Space-Track OMM data in JSON, XML, KVN or CSV and detects the encoding. An OMM carries the same SGP4 elements as a TLE but has no catalog-number limit, a full-precision epoch, and states its frame and model. Both conform to `MeanElementSet`, so `SGP4(elements:)` accepts either. See [Element Sets](./docs/element-sets.md).

**Accuracy**: With `SGP4`, expect about 1 km of error at the TLE epoch, growing by roughly 1-3 km per day for low Earth orbit. TLE age is the main error source, so refresh TLEs every day or two for antenna pointing.

**Propagation**: `SGP4` is a line-by-line port of Vallado's reference implementation ("Revisiting Spacetrack Report #3", AIAA 2006-6753). It matches the published verification output (`tcppver.out`, 666 points across 33 satellites) to within 0.12 mm. `KeplerianOrbit` uses two-body Keplerian mechanics for teaching and ignores all perturbations. See [Orbital Elements](./docs/orbital-elements.md) for the theory.

## For AI Tools and Developers

For developers using AI-assisted coding tools (ChatGPT, Claude, GitHub Copilot), Ephemeris includes an **[LLM.txt](./LLM.txt)** file that provides natural-language context about the project's purpose, architecture, and design goals. This helps large language models better understand the framework when providing code suggestions, generating documentation, or answering questions about the codebase.

The LLM.txt file includes:
- High-level overview of what Ephemeris is and what it isn't
- Descriptions of core components and their relationships
- Design philosophy and implementation approach
- Intended use cases and limitations
- Future roadmap features

This context-aware documentation improves the accuracy of AI-generated code and explanations when working with Ephemeris.

## CI/CD

This project uses GitHub Actions for continuous integration:

- **Build and Test**: Automatically builds the framework and runs all tests on every push and pull request using Swift Package Manager
- **SwiftLint**: Enforces Swift style and conventions in strict mode

### Running Tests Locally

Ephemeris uses **XCTest** (Apple's standard testing framework) for all tests.

```bash
# Build the package
swift build

# Run tests
swift test

# Run tests with verbose output
swift test --verbose
```

The test suite includes 126 tests covering:
- TLE parsing and validation
- SGP4/SDP4 propagation against Vallado's verification vectors
- Orbital calculations and Kepler's equation
- Coordinate transformations (ECI, ECEF, Geodetic, ENU)
- Observer-relative calculations (topocentric coordinates)
- Pass prediction algorithms
- Ground track and sky track generation

**All tests must pass before submitting a pull request.**

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on:

- Development setup
- Code style and conventions
- Testing requirements
- Documentation standards
- Pull request process

### Quick Start for Contributors

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/Ephemeris.git
cd Ephemeris

# Create a feature branch
git checkout -b feature/amazing-feature

# Build and test
swift build
swift test

# Run SwiftLint
swiftlint lint --strict

# Make changes, commit, and push
git commit -m 'Add amazing feature'
git push origin feature/amazing-feature
```

For major changes, please open an issue first to discuss what you would like to change.

## References

### Satellite Tracking and Orbital Mechanics

- [Satellite Tracking Using NORAD Two-Line Element Set Format](http://www.afahc.ro/ro/afases/2016/MATH&IT/CROITORU_OANCEA.pdf) - Transilvania University of Braşov, by Emilian-Ionuţ CROITORU and Gheorghe OANCEA
- [Calculation of Satellite Position from Ephemeris Data](https://ascelibrary.org/doi/pdf/10.1061/9780784411506.ap03) - Applied GPS for Engineers and Project Managers, ascelibrary.org
- [Describing Orbits](https://www.faa.gov/about/office_org/headquarters_offices/avs/offices/aam/cami/library/online_libraries/aerospace_medicine/tutorial/media/iii.4.1.4_describing_orbits.pdf) - FAA US Government
- [Transformation of Orbit Elements](https://onlinelibrary.wiley.com/doi/pdf/10.1002/9781118542200.app1) - Space Electronic Reconnaissance: Localization Theories and Methods
- [Introduction to Orbital Mechanics](https://www.csun.edu/~hcmth017/master/master.html) - W. Horn, B. Shapiro, C. Shubin, F. Varedi, California State University Northridge
- [Computation of Sub-Satellite Points from Orbital Elements](https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19650015945.pdf) - Richard H. Christ, NASA
- [Satellite Orbits](http://calculuscastle.com/orbit.pdf) - Calculus Castle

### Sidereal Time and Julian Date Calculations

- [Methods of Astrodynamics: A Computer Approach](https://www.academia.edu/20528856/Methods_of_Astrodynamics_a_Computer_Approach)
- [Sidereal Time](http://www2.arnes.si/~gljsentvid10/sidereal.htm)
- [Revisiting Spacetrack Report #3](http://www.celestrak.com/publications/AIAA/2006-6753/AIAA-2006-6753-Rev3.pdf) - Celestrak
- [Computing Julian Date](https://www.aavso.org/computing-jd) - AAVSO

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE.md](LICENSE.md) file for details.

Copyright © 2020 Michael VanDyke

## Acknowledgements

Special thanks to all the researchers, institutions, and open source projects that made this work possible.

### Open Source Projects

- **[ZeiSatTrack](https://github.com/dhmspector/ZeitSatTrack)** [Apache 2.0] - Reference for rotation math and Julian date conversion calculations

