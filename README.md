# Ephemeris

[![CI](https://github.com/mvdmakesthings/Ephemeris/workflows/CI/badge.svg)](https://github.com/mvdmakesthings/Ephemeris/actions)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE.md)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)

A Swift framework for satellite tracking and orbital mechanics calculations. Ephemeris provides tools to parse Two-Line Element (TLE) data and calculate orbital positions for Earth-orbiting satellites.

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

- 📡 **TLE Parsing**: Parse NORAD Two-Line Element (TLE) format satellite data
- 🛰️ **Orbital Calculations**: Calculate satellite positions using orbital mechanics
- 🌍 **Position Tracking**: Compute latitude, longitude, and altitude for satellites at any given time
- 📐 **Orbital Elements**: Support for all standard Keplerian orbital elements:
  - Semi-major axis
  - Eccentricity
  - Inclination
  - Right Ascension of Ascending Node (RAAN)
  - Argument of Perigee
  - Mean Anomaly and True Anomaly
- ⏰ **Time Conversions**: Julian date and Greenwich Sidereal Time calculations
- 🔢 **High Precision**: Iterative algorithms for eccentric anomaly calculations

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.5+

## Installation

### Swift Package Manager

Add Ephemeris to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/mvdmakesthings/Ephemeris.git", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["Ephemeris"]
    )
]
```

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
    
    // Create an orbit from the TLE
    let orbit = Orbit(from: tle)
    
    // Calculate current position
    let position = try orbit.calculatePosition(at: Date())
    print("Latitude: \(position.latitude)°")
    print("Longitude: \(position.longitude)°")
    print("Altitude: \(position.altitude) km")
} catch {
    print("Error: \(error)")
}
```

### Accessing Orbital Elements

```swift
let orbit = Orbit(from: tle)

// Access orbital parameters
print("Semi-major axis: \(orbit.semimajorAxis) km")
print("Eccentricity: \(orbit.eccentricity)")
print("Inclination: \(orbit.inclination)°")
print("RAAN: \(orbit.rightAscensionOfAscendingNode)°")
print("Argument of Perigee: \(orbit.argumentOfPerigee)°")
print("Mean Anomaly: \(orbit.meanAnomaly)°")
print("Mean Motion: \(orbit.meanMotion) revolutions/day")
```

### Calculate Position at Specific Time

```swift
// Create a specific date
let calendar = Calendar.current
let components = DateComponents(year: 2020, month: 4, day: 15, hour: 12, minute: 0)
let specificDate = calendar.date(from: components)

// Calculate position at that time
if let date = specificDate {
    let position = try? orbit.calculatePosition(at: date)
    if let pos = position {
        print("At \(date):")
        print("  Latitude: \(pos.latitude)°")
        print("  Longitude: \(pos.longitude)°")
        print("  Altitude: \(pos.altitude) km")
    }
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
        let position = try orbit.calculatePosition(at: time)
        print("T+\(i) min: \(position.latitude)°, \(position.longitude)°, \(position.altitude) km")
    } catch {
        print("Error calculating position: \(error)")
    }
}
```

### Multiple Satellites

```swift
// Track multiple satellites
let satellites = [
    ("ISS", issТleString),
    ("GOES-16", goes16TleString),
    ("GPS BIIF-1", gpsTleString)
]

for (name, tleString) in satellites {
    do {
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)
        let position = try orbit.calculatePosition(at: Date())
        
        print("\(name):")
        print("  Position: \(position.latitude)°, \(position.longitude)°")
        print("  Altitude: \(position.altitude) km")
        print()
    } catch {
        print("Error processing \(name): \(error)")
    }
}
```

### Error Handling

```swift
// Comprehensive error handling
let tleString = """
SATELLITE NAME
1 12345U 20001A   20100.50000000  .00001234  00000-0  12345-4 0  9999
2 12345  51.6400  90.0000 0001000  45.0000  90.0000 15.50000000123456
"""

do {
    let tle = try TwoLineElement(from: tleString)
    let orbit = Orbit(from: tle)
    let position = try orbit.calculatePosition(at: Date())
    
    print("Successfully calculated position: \(position.latitude)°, \(position.longitude)°")
    
} catch TLEParsingError.invalidFormat(let message) {
    print("Invalid TLE format: \(message)")
} catch TLEParsingError.invalidChecksum(let line, let expected, let actual) {
    print("Checksum error on line \(line): expected \(expected), got \(actual)")
} catch TLEParsingError.invalidNumber(let field, let value) {
    print("Invalid number in field '\(field)': \(value)")
} catch CalculationError.reachedSingularity {
    print("Cannot calculate orbit: eccentricity >= 1.0 (not an elliptical orbit)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Working with Julian Dates and Sidereal Time

```swift
import Foundation

// Convert current date to Julian Day
if let julianDay = Date.julianDay(from: Date()) {
    print("Current Julian Day: \(julianDay)")
    
    // Calculate Greenwich Sidereal Time
    let gst = Date.greenwichSideRealTime(from: julianDay)
    print("Greenwich Sidereal Time: \(gst) radians")
    
    // Convert to J2000 epoch
    let j2000 = Date.toJ2000(from: julianDay)
    print("Julian centuries since J2000: \(j2000)")
}

// Convert TLE epoch to Julian Day
let epochJD = Date.julianDayFromEpoch(epochYear: 2020, epochDayFraction: 97.82871450)
print("TLE Epoch as Julian Day: \(epochJD)")
```

### Custom Satellite Analysis

```swift
// Analyze orbital characteristics
func analyzeOrbit(_ orbit: Orbit) {
    let earthRadius = PhysicalConstants.Earth.radius
    
    // Calculate apogee and perigee
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
    let mu = PhysicalConstants.Earth.µ
    let period = 2 * .pi * sqrt(pow(orbit.semimajorAxis, 3) / mu)
    print("  Orbital period: \(period / 60) minutes")
}

// Use the analyzer
let tle = try TwoLineElement(from: tleString)
let orbit = Orbit(from: tle)
analyzeOrbit(orbit)
```

## Documentation

### Core Types

- **`TwoLineElement`**: Represents and parses NORAD TLE format satellite data
- **`Orbit`**: Represents orbital parameters and provides position calculation methods
- **`Orbitable`**: Protocol defining requirements for orbital element data

### Where to Get TLE Data

TLE data for satellites can be obtained from:
- [CelesTrak](https://celestrak.com/NORAD/elements/)
- [Space-Track.org](https://www.space-track.org/) (requires free registration)
- [N2YO.com](https://www.n2yo.com/)

### TLE Format Limitations

The TLE format uses 2-digit years, which requires interpretation logic. Ephemeris uses a **±50 year window** relative to the current date:

- **Supported Range**: TLE data from approximately 50 years in the past to 50 years in the future is supported
- **Recent Data**: The framework is designed for current/recent satellite tracking data
- **Historical Data**: Very old TLE data (>50 years old) may be parsed incorrectly
- **Future-Proof**: The Y2K-style date handling automatically adjusts as time progresses, preventing issues through at least 2107

For typical use cases involving current satellite tracking, this limitation is not a concern.

### Additional Documentation

- **[Introduction to Orbital Elements](./docs/Introduction-to-Orbital-Elements.md)** - Comprehensive guide to understanding the six Keplerian orbital elements, TLE format, and ensuring prediction accuracy
- **[API Reference](./docs/API-Reference.md)** - Complete API documentation for all public types and methods

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
- **SwiftLint**: Enforces Swift style and conventions

### Running Tests Locally

The Ephemeris test suite uses [Spectre](https://github.com/kylef/Spectre), a BDD-style testing framework for Swift. Tests are run as an executable rather than with the standard XCTest framework.

```bash
# Build the package
swift build

# Run tests using the executable
swift run EphemerisTests
```

The test suite is pure Swift and does not require Xcode. It can be run on any system with Swift installed (including Linux).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Clone your fork
3. Create a feature branch (`git checkout -b feature/amazing-feature`)
4. Make your changes
5. Run SwiftLint: `swiftlint lint`
6. Run tests if possible
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

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

