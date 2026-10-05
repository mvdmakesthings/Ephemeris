# Changelog

All notable changes to Ephemeris will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - Unreleased

2.0 makes the library accurate enough for antenna pointing and cleans up the public API.
It is a breaking release: see **Migrating from 1.x** below.

### Added
- `SGP4`: pure Swift SGP4/SDP4 propagator for TLE data, ported from Vallado's reference
  implementation, including deep-space lunar-solar periodics and 12h/24h resonance.
  Supports WGS-72 (default), WGS-72 old and WGS-84 constants, and AFSPC or improved mode.
  Verified against Vallado's 666-point test set (max error 0.12 mm).
- `Propagator` protocol and `StateVector`. Position, look angles, pass prediction, ground
  tracks and sky tracks are written once and work with any propagator.
- `OrbitMeanElementsMessage`: CCSDS Orbit Mean-Elements Message (OMM) support. Parses
  JSON, XML, KVN and CSV as served by CelesTrak and Space-Track, with encoding detection.
  OMM has no catalog-number limit, a microsecond epoch, and states its frame and model.
- `MeanElementSet` protocol, adopted by `TwoLineElement` and `OrbitMeanElementsMessage`.
  `SGP4(elements:)` and `KeplerianOrbit(elements:)` accept either format.
- `SGP4` refuses SGP4-XP element sets (ephemeris type 4) with
  `SGP4Error.unsupportedEphemerisType` instead of producing wrong positions.
- `TwoLineElement.classification`, `.ephemerisType` and `.elementSetNumber`.
- `SatelliteCatalog`: loads thousands of satellites from a TLE document, an OMM document
  (any encoding) or parsed element sets. Bad entries are collected in `rejections` with a
  reason instead of failing the load, and when a satellite appears twice the newest epoch
  wins. Lookup by catalog number, international designator or name; `filter(_:)` and
  `excludingStale(olderThan:at:)`.
- Concurrent whole-catalog queries: `stateVectors(at:)`, `positions(at:)`,
  `lookAngles(from:at:minElevationDeg:)` and `passes(for:from:to:minElevationDeg:stepSeconds:)`,
  returning `SatelliteState`, `SatellitePosition`, `SatelliteLookAngles` and `SatellitePass`.
  Results are identical to a serial loop and in a stable order.
- `CatalogSatellite` with `regime` (`OrbitRegime`), perigee and apogee radius, `age(at:)`, and
  `canRise(forLatitudeDeg:minElevationDeg:)`, a conservative geometric test that lets
  catalog queries skip satellites that can never rise for an observer.
- `CatalogRejection` describing why an element set was left out of a catalog.
- `TwoLineElement.parseEach(_:)` and `OrbitMeanElementsMessage.parseEach(_:format:)` parse a
  multi-satellite document and return one result per entry.
- `docs/catalogs.md`: whole-catalog guide, including the visibility geometry and how to
  fetch catalog data without overloading CelesTrak or Space-Track.
- `docs/element-sets.md`: a guide to what element sets are and how TLE and OMM compare.
- `GravityModel` with `.wgs72`, `.wgs72old` and `.wgs84`.
- `SGP4Error` for decay and invalid-element conditions, with the reference error codes.
- `KeplerianOrbit` can be created from orbital elements directly, and has
  `meanAnomaly(at:)` and `trueAnomaly(at:)`.
- `PassWindow` reports passes already in progress at the start or still in progress at the
  end of the search window (`beginsBeforeSearch`, `endsAfterSearch`), and finds passes
  shorter than the sampling step. AOS and LOS are refined to 0.1 s.
- `GroundTrackPoint` carries altitude; `SkyTrackPoint` carries range and range rate.
- `CoordinateTransforms.ecefToGeodetic(_:)` and `eciToECEF(_:gmst:)` for state vectors.
- `Vector3D` operators `+`, `-`, `*` (scalar).
- TLE parser accepts the bare two-line form, any line endings, blank lines, and
  Space-Track's `0 `-prefixed name line; supports Alpha-5 catalog numbers; rejects element
  sets whose two lines have different catalog numbers.
- All public value types are `Sendable`, `Hashable` and `Codable`.

### Fixed
- Greenwich Mean Sidereal Time ignored the time of day, so Earth-fixed positions, azimuth,
  elevation, and pass times were only correct near 0h UTC. Now uses the full IAU-82
  expression (verified against Vallado Example 3-5), computed from the timestamp in seconds
  for sub-microsecond precision.
- Kepler's equation solver could stop after one Newton iteration when the step was negative,
  causing errors of several degrees for high-eccentricity orbits.
- True anomaly used `sin E` and `cos E` where the formula needs `sin(E/2)` and `cos(E/2)`,
  so two-body positions were placed at the wrong point along the orbit (for a circular
  orbit the anomaly came out doubled).
- Position returned geocentric latitude and altitude above a sphere. It now returns WGS-84
  geodetic latitude and height above the ellipsoid (up to ~0.19° / ~21 km difference).
- Atmospheric refraction applied Bennett's formula, which expects apparent elevation, to the
  true elevation. Now uses Sæmundsson's formula for true elevation (about 0.08° at the
  horizon).
- Earth's rotation rate constant was mistyped (7.2921076e-5 instead of the WGS-84
  7.292115e-5 rad/s).

### Changed
- 2-digit TLE epoch years use the fixed NORAD convention (57-99 → 1957-1999,
  00-56 → 2000-2056) instead of a ±50-year window relative to the current date.
- Source layout: `Catalog/`, `Coordinates/`, `Observation/`, `Parsing/`, `Propagation/`,
  `Time/`, `Tracking/`, `Utilities/`.
- Pass prediction and sky tracks compute the observer's Earth-fixed position and local axes
  once per search instead of at every sample (about 10% faster, identical results).

### Removed
- `Orbitable` protocol (one conforming type, no generic consumers).
- `CalculationError` (unreachable: the TLE parser already rejects e ≥ 1).
- `@frozen` and `@inlinable` annotations, which only matter for ABI-stable binary
  frameworks.
- String subscripting helpers and `Double.round(to:)` (the parser now reads bytes by column).
- Unused constants: `Earth.meanRadius`, `semiMinorAxis`, `flattening`, `Time.secondsPerMinute`,
  and the `Angle` and `Calculation` namespaces.

### Migrating from 1.x

| 1.x | 2.0 |
|-----|-----|
| `Orbit(from: tle)` | `try SGP4(tle: tle)` for tracking, or `KeplerianOrbit(tle: tle)` for two-body |
| `Orbitable` | removed; use `KeplerianOrbit` or `Propagator` |
| `orbit.trueAnomaly` | `orbit.trueAnomaly(at: date)` |
| `calculatePosition(at: Date?)` | `calculatePosition(at: Date)` |
| `position.latitude` / `.longitude` / `.altitude` | `position.latitudeDeg` / `.longitudeDeg` / `.altitudeKm` |
| `groundPoint.latitudeDeg` | `groundPoint.position.latitudeDeg` |
| `skyPoint.azimuthDeg` / `.elevationDeg` | `skyPoint.topocentric.azimuthDeg` / `.elevationDeg` |
| `pass.max.time` / `.elevationDeg` / `.azimuthDeg` | `pass.culmination.time` / `.elevationDeg` / `.azimuthDeg` |
| `PassWindow.Point` | `PassWindow.Event` (adds `elevationDeg`) |
| `Date.julianDay(from: date)!` | `date.julianDate` |
| `Date.greenwichSideRealTime(from: jd)` | `Date.greenwichMeanSiderealTime(julianDate: jd)` or `date.greenwichMeanSiderealTime` |
| `Date.toJ2000(from: jd)` | `Date.julianCenturiesSinceJ2000(julianDate: jd)` |
| `JulianDay`, `J2000` type aliases | `JulianDate` |
| `PhysicalConstants.Earth.µ` / `.radius` / `.radsPerDay` | `.mu` / `.semiMajorAxis` / `.rotationRate` (rad/s) |
| `PhysicalConstants.Julian.j2000Epoch` | `PhysicalConstants.Julian.j2000` |
| `geodeticToECEF(latitudeDeg:longitudeDeg:altitudeMeters:)` | `geodeticToECEF(_: GeodeticPosition)` |
| `ecefToGeodetic(ecef:)` | `ecefToGeodetic(_:)` |
| `eciToECEF(eciPosition:gmst:)` | `eciToECEF(_:gmst:)` |
| `eciVelocityToECEF(eciPosition:eciVelocity:gmst:)` | `eciToECEF(_: StateVector, gmst:)` |
| `ecefToENU(ecefPosition:observerECEF:observerLatDeg:observerLonDeg:)` | `ecefToENU(_:observer:)` |
| `enuToAzEl(enu:)` | `enuToAzEl(_:)` |
| `applyRefraction(elevationDeg:)` | `apparentElevation(fromTrueElevationDeg:)` |
| `vectorA.subtract(vectorB)` | `vectorA - vectorB` |
| `tle.rightAscension` | `tle.rightAscensionOfAscendingNode` |
| `tle.epochYear`, `tle.epochDay`, `tle.elementSetEpochUTC` | `tle.epoch` (`Date`) |
| `tle.revolutionsAtEpoch` | `tle.revolutionNumberAtEpoch` |

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
