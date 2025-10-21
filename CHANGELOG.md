# Changelog

All notable changes to Ephemeris will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet

## [1.0.0] - 2025-10-21

### Added
- TLE (Two-Line Element) parsing with comprehensive validation and checksum verification
- Keplerian orbital mechanics calculations using two-body dynamics
- Position calculations with full coordinate transformation pipeline (ECI → ECEF → Geodetic)
- Pass prediction for ground observers using bisection and golden-section search algorithms
- Ground track generation for orbital path visualization
- Sky track visualization data for observer-relative satellite paths
- Topocentric coordinate transformations (azimuth, elevation, range)
- Atmospheric refraction correction using Bennett formula
- Comprehensive documentation suite with mathematical foundations
- Full test coverage using XCTest framework
- Swift 6.0 tools support with Swift 5 language mode
- Multi-platform support following "current minus two" policy:
  - iOS 16.0+ (Current: iOS 18)
  - macOS 13.0+ (Current: macOS 15)
  - watchOS 9.0+ (Current: watchOS 11)
  - tvOS 16.0+ (Current: tvOS 18)
  - visionOS 1.0+ (All versions supported)
- Educational documentation including:
  - Getting Started guide
  - Orbital Elements deep-dive
  - Observer Geometry and pass prediction
  - Coordinate Systems mathematical foundations
  - Time Systems (Julian Day, GMST)
  - Visualization integration guides (SwiftUI, MapKit)
- Protocol-oriented design with `Orbitable` protocol for extensibility
- Pure Swift implementation from first principles
- Zero external dependencies (Foundation-only)
- Apache 2.0 open source license

### Changed
- Migrated from Spectre BDD framework to XCTest for standard testing
- Adopted standard Sources/Tests directory structure per Swift Package Manager conventions
- Removed unsafe compiler flags to enable package distribution
- Updated testing infrastructure to use `.testTarget` instead of `.executableTarget`

### Technical Highlights
- **Architecture**: Protocol-oriented design with immutable value types
- **Accuracy**: Best within 1-3 days of TLE epoch using Keplerian mechanics
- **Performance**: Optimized for readability and education over maximum performance
- **Thread Safety**: All core types are immutable structs with value semantics
- **Physical Constants**: WGS-84 Earth parameters with documented sources
- **Coordinate Systems**: Support for ECI, ECEF, ENU, and Horizontal (Az/El) coordinates
- **Time Systems**: Julian Day and Greenwich Mean Sidereal Time calculations
- **Iterative Solvers**: Newton-Raphson method for Kepler's equation with convergence guarantees

### Known Limitations
- Uses simplified two-body Keplerian mechanics (not SGP4/SDP4)
- Does not model atmospheric drag, solar radiation pressure, or gravitational perturbations
- Best accuracy within 1-3 days of TLE epoch
- Requires regular TLE updates for LEO satellites (every 1-3 days recommended)
- Educational focus prioritizes code clarity over maximum performance

### Platform Support Policy
Ephemeris follows a "current minus two" platform support policy, supporting the current OS version minus two major releases. This balances broad device coverage (~95% of active devices) with access to modern APIs. Platform minimums are reviewed annually or with major releases.

[Unreleased]: https://github.com/mvdmakesthings/Ephemeris/compare/1.0.0...HEAD
[1.0.0]: https://github.com/mvdmakesthings/Ephemeris/releases/tag/1.0.0
