# Ephemeris API Documentation

Welcome to the Ephemeris API documentation. This framework provides tools for satellite tracking and orbital mechanics calculations.

## Getting Started

- [Installation Guide](../README.md#installation)
- [Usage Examples](../README.md#usage)
- [Introduction to Orbital Elements](Introduction-to-Orbital-Elements.md)

## Core Types

### Orbit
The main type for representing and calculating satellite orbits.

**Key Properties:**
- `semimajorAxis: Double` - Half the distance between perigee and apogee (km)
- `eccentricity: Double` - Shape of the orbit (0 = circular, approaching 1 = highly elliptical)
- `inclination: Degrees` - Tilt of the orbital plane (0-180°)
- `rightAscensionOfAscendingNode: Degrees` - Orbital plane rotation (Ω)
- `argumentOfPerigee: Degrees` - Orientation of perigee (ω)
- `trueAnomaly: Degrees` - Current position in orbit (ν or θ)
- `meanAnomaly: Degrees` - Time-based position (M)
- `meanMotion: Double` - Revolutions per day

**Key Methods:**
- `init(from: TwoLineElement)` - Creates orbit from TLE data
- `calculatePosition(at: Date?) throws -> Position` - Calculates satellite position at a specific time

**Static Methods:**
- `calculateSemimajorAxis(meanMotion: Double) -> Double` - Computes semi-major axis from mean motion
- `calculateEccentricAnomaly(eccentricity: Double, meanAnomaly: Degrees) -> Degrees` - Solves for eccentric anomaly
- `calculateTrueAnomaly(eccentricity: Double, eccentricAnomaly: Degrees) throws -> Degrees` - Computes true anomaly

### TwoLineElement
Parses and represents NORAD Two-Line Element (TLE) satellite data.

**Key Properties:**
- `name: String` - Satellite name
- `catalogNumber: Int` - NORAD catalog number
- `epochYear: Int` - Epoch year (4 digits)
- `epochDay: Double` - Day of year with fractional day
- `inclination: Degrees` - Orbital inclination
- `rightAscension: Degrees` - Right Ascension of Ascending Node (RAAN)
- `eccentricity: Double` - Orbital eccentricity
- `argumentOfPerigee: Degrees` - Argument of perigee
- `meanAnomaly: Degrees` - Mean anomaly at epoch
- `meanMotion: Double` - Mean motion (revolutions/day)

**Initializer:**
- `init(from: String) throws` - Parses a three-line TLE string

**Throws:**
- `TLEParsingError` - Various parsing errors with detailed context

### Orbit.Position
Represents a geographic position for a satellite.

**Properties:**
- `latitude: Double` - Latitude in degrees (-90 to 90)
- `longitude: Double` - Longitude in degrees (-180 to 180)
- `altitude: Double` - Altitude above Earth's surface in kilometers

### Orbitable Protocol
Defines requirements for types representing orbital elements.

**Required Properties:**
- `semimajorAxis: Double`
- `eccentricity: Double`
- `inclination: Degrees`
- `rightAscensionOfAscendingNode: Degrees`
- `argumentOfPerigee: Degrees`
- `trueAnomaly: Degrees`
- `meanAnomaly: Degrees`
- `meanMotion: Double`

## Physical Constants

### PhysicalConstants
Centralized collection of physical and mathematical constants.

**Nested Structures:**
- `PhysicalConstants.Earth` - Earth's physical properties (WGS84 standard)
  - `µ: Double` - Gravitational constant (398600.4418 km³/s²)
  - `radius: Double` - Equatorial radius (6378.137 km)
  - `meanRadius: Double` - Mean radius (6371.0 km)
  - `radsPerDay: Double` - Rotation rate (6.3003809866574 rad/day)

- `PhysicalConstants.Time` - Time conversion constants
  - `secondsPerDay: Double` - 86400.0
  - `daysPerJulianCentury: Double` - 36525.0
  - `secondsPerHour: Double` - 3600.0
  - `secondsPerMinute: Double` - 60.0

- `PhysicalConstants.Julian` - Julian date reference points
  - `unixEpoch: Double` - Unix epoch as Julian Day (2440587.5)
  - `j2000Epoch: Double` - J2000.0 epoch (2451545.0)

- `PhysicalConstants.Calculation` - Algorithm parameters
  - `defaultAccuracy: Double` - 0.00001
  - `maxIterations: Int` - 500

- `PhysicalConstants.Angle` - Angular constants
  - `degreesPerCircle: Double` - 360.0
  - `radiansPerCircle: Double` - 2π

## Date & Time Extensions

### Date Extensions
Astronomical time conversion utilities.

**Static Methods:**
- `julianDay(from: Date) -> JulianDay?` - Converts Date to Julian Day Number
- `julianDayFromEpoch(epochYear: Int, epochDayFraction: Double) -> JulianDay` - Converts TLE epoch to Julian Day
- `greenwichSideRealTime(from: JulianDay) -> Radians` - Calculates Greenwich Sidereal Time
- `toJ2000(from: JulianDay) -> J2000` - Converts to Julian centuries since J2000.0

## Mathematical Extensions

### Double Extensions
Math utilities for orbital calculations.

**Methods:**
- `round(to places: Int) -> Double` - Rounds to specified decimal places
- `inRadians() -> Radians` - Converts degrees to radians
- `inDegrees() -> Degrees` - Converts radians to degrees

## Type Aliases

Semantic type aliases for clarity:

- `Degrees` = `Double` - Angular measurement in degrees
- `Radians` = `Double` - Angular measurement in radians
- `JulianDay` = `Double` - Julian Day Number
- `J2000` = `Double` - Julian centuries since J2000.0

## Error Types

### TLEParsingError
Errors that occur during TLE parsing.

**Cases:**
- `invalidFormat(String)` - Malformed TLE structure
- `invalidNumber(field: String, value: String)` - Invalid numeric value
- `missingLine(expected: Int, actual: Int)` - Wrong number of lines
- `invalidStringRange(field: String, range: String)` - String subscript error
- `invalidChecksum(line: Int, expected: Int, actual: Int)` - Checksum mismatch
- `invalidEccentricity(value: Double)` - Eccentricity out of range (must be < 1.0)

### CalculationError
Errors in orbital calculations.

**Cases:**
- `reachedSingularity` - Singularity in calculation (typically eccentricity >= 1.0)

## Example Usage

See the [README Usage Section](../README.md#usage) for comprehensive examples including:
- Quick start guide
- Tracking satellites over time
- Multiple satellite tracking
- Error handling patterns
- Julian date conversions
- Custom orbital analysis

## References

- [Introduction to Orbital Elements](Introduction-to-Orbital-Elements.md)
- [Two-Line Element Format (Wikipedia)](https://en.wikipedia.org/wiki/Two-line_element_set)
- [WGS84 Geodetic System](http://www.unoosa.org/pdf/icg/2012/template/WGS_84.pdf)
- [Kepler's Laws of Planetary Motion](https://en.wikipedia.org/wiki/Kepler%27s_laws_of_planetary_motion)

## License

Ephemeris is licensed under the Apache License 2.0. See [LICENSE.md](../LICENSE.md) for details.

---

**Generated for Ephemeris v1.0** | [GitHub Repository](https://github.com/mvdmakesthings/Ephemeris) | [Report Issues](https://github.com/mvdmakesthings/Ephemeris/issues)
