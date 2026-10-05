# Observer Geometry and Pass Prediction

> **Brief Description**: Learn coordinate transformations (ECI → ECEF → ENU → Horizontal) and pass prediction algorithms for calculating satellite visibility from Earth-based locations.

## Overview

This document explains the mathematical foundations and coordinate transformations used in Ephemeris for computing satellite visibility from Earth-based observer locations.

**Theory-First Approach**: We begin with the mathematical foundations of coordinate systems and transformation matrices, then show how Ephemeris implements these concepts in Swift for practical satellite tracking applications.

**What You'll Learn:**
- Four coordinate systems: ECI, ECEF, Geodetic, and ENU
- Transformation matrices and Greenwich Mean Sidereal Time
- Azimuth, elevation, range, and range rate calculations
- Pass prediction algorithms (bisection and golden-section search)
- Atmospheric refraction corrections
- Swift implementation using the `Observer` and `Topocentric` types

**The observer support system enables you to:**
- Calculate azimuth, elevation, range, and range rate for any satellite from any location on Earth
- Predict satellite passes with accurate AOS (Acquisition of Signal), maximum elevation, and LOS (Loss of Signal) times
- Apply atmospheric refraction corrections for low-elevation observations

## Coordinate Systems

### 1. ECI (Earth-Centered Inertial)

An inertial reference frame with its origin at Earth's center. The frame does not rotate with Earth:
- **X-axis**: Points toward the vernal equinox (First Point of Aries)
- **Y-axis**: Completes right-handed coordinate system in the equatorial plane
- **Z-axis**: Points toward the North Pole

This is the natural frame for orbital mechanics calculations.

### 2. ECEF (Earth-Centered, Earth-Fixed)

A rotating reference frame fixed to Earth's surface:
- **X-axis**: Passes through the prime meridian at the equator
- **Y-axis**: Passes through 90°E longitude at the equator
- **Z-axis**: Points toward the North Pole (same as ECI)

This frame rotates with Earth at one revolution per sidereal day.

### 3. Geodetic Coordinates

The familiar latitude, longitude, and altitude system:
- **Latitude**: Angle north (positive) or south (negative) of the equator (-90° to +90°)
- **Longitude**: Angle east (positive) or west (negative) of the prime meridian (-180° to +180°)
- **Altitude**: Height above the WGS-84 reference ellipsoid (kilometers in `GeodeticPosition`; `Observer` takes meters)

### 4. ENU (East-North-Up)

A local tangent plane coordinate system centered at the observer:
- **East**: Points east along the local horizon
- **North**: Points north along the local horizon
- **Up**: Points toward zenith (perpendicular to the local horizon)

This is the natural frame for expressing azimuth and elevation.

## Coordinate Transformations

### Geodetic to ECEF

Converts observer location from latitude/longitude/altitude to Cartesian ECEF coordinates.

**Algorithm:**
```
N = a / sqrt(1 - e²·sin²(lat))
X = (N + h)·cos(lat)·cos(lon)
Y = (N + h)·cos(lat)·sin(lon)
Z = (N·(1 - e²) + h)·sin(lat)
```

Where:
- `a` = WGS-84 semi-major axis (6378.137 km)
- `e²` = WGS-84 eccentricity squared (0.00669437999014)
- `h` = altitude above ellipsoid (km)
- `N` = radius of curvature in the prime vertical

**Reference:** Vallado, Section 3.5

### ECI to ECEF

Transforms satellite position from inertial to Earth-fixed frame by rotating about the Z-axis by Greenwich Mean Sidereal Time (GMST).

**Algorithm:**
```
X_ecef =  cos(GMST)·X_eci + sin(GMST)·Y_eci
Y_ecef = -sin(GMST)·X_eci + cos(GMST)·Y_eci
Z_ecef = Z_eci
```

For velocity transformation, we also account for Earth's rotation:
```
V_ecef = R(GMST)·V_eci - ω_earth × R_ecef
```

Where `ω_earth` is Earth's angular velocity vector (0, 0, ω_z), with ω_z = 7.292115 × 10⁻⁵ rad/s (`PhysicalConstants.Earth.rotationRate`). In Ephemeris this is `CoordinateTransforms.eciToECEF(_:gmst:)` called with a `StateVector`.

**Reference:** Vallado, Section 3.7

### ECEF to ENU

Transforms from Earth-fixed to local observer frame.

**Algorithm:**
```
Δ = R_sat - R_obs  (relative position vector)

E = -sin(lon)·Δx + cos(lon)·Δy
N = -sin(lat)·cos(lon)·Δx - sin(lat)·sin(lon)·Δy + cos(lat)·Δz
U =  cos(lat)·cos(lon)·Δx + cos(lat)·sin(lon)·Δy + sin(lat)·Δz
```

**Reference:** Montenbruck & Gill, Section 5.4.1

### ENU to Azimuth/Elevation

Converts ENU coordinates to horizontal coordinates.

**Algorithm:**
```
Azimuth   = atan2(E, N)         [0° to 360°, clockwise from north]
Elevation = atan2(U, sqrt(E² + N²))  [-90° to +90°]
Range     = sqrt(E² + N² + U²)
```

## Topocentric Calculations

The `topocentric(at:for:applyRefraction:)` method performs the complete chain of transformations:

1. Calculate satellite position and velocity in ECI frame
2. Convert satellite state to ECEF using GMST
3. Convert observer position from geodetic to ECEF
4. Compute relative position vector (satellite - observer) in ECEF
5. Transform relative position to ENU frame
6. Calculate azimuth, elevation, and range from ENU
7. Optionally apply atmospheric refraction correction
8. Calculate range rate by projecting velocity onto line-of-sight

**Range Rate:**
```
range_rate = (R_sat - R_obs) · V_sat / range
```

Here `V_sat` is the Earth-relative (ECEF) velocity from step 2, so a stationary observer sees the right Doppler sign and size.

## Pass Prediction Algorithm

The `predictPasses(for:from:to:minElevationDeg:stepSeconds:)` method is available on any `Propagator` (`SGP4` or `KeplerianOrbit`) and uses a three-stage approach:

### Stage 1: Coarse Search

Step through time at regular intervals (default 30 seconds) to detect elevation crossing events:
- **AOS Event**: Elevation transitions from below to above minimum threshold
- **LOS Event**: Elevation transitions from above to below minimum threshold
- **Short-pass check**: If a sample is a local peak but still below the threshold, the real peak may be hiding between samples. The interval around it is searched for the true maximum, and if that clears the threshold the pass is kept. This catches passes shorter than the step size.

A pass that is already in progress at the start of the window, or still in progress at the end, is returned with `beginsBeforeSearch` or `endsAfterSearch` set to `true`, and its AOS or LOS is the window edge.

### Stage 2: Bisection Refinement

For each detected crossing, use bisection search to refine the time to 0.1 second accuracy:

```
while (t_right - t_left > 0.1 second):
    t_mid = (t_left + t_right) / 2
    el_mid = elevation(t_mid)
    
    if rising_edge:
        if el_mid < threshold:
            t_left = t_mid
        else:
            t_right = t_mid
    else:  # falling edge
        if el_mid > threshold:
            t_left = t_mid
        else:
            t_right = t_mid
```

### Stage 3: Maximum Elevation Search

Use golden-section search to find the precise time and elevation of maximum elevation (the culmination) within each pass:

```
φ = (1 + √5) / 2  (golden ratio)

while (t_b - t_a > 0.1 second):
    t_c = t_a + (t_b - t_a) / φ
    t_d = t_b - (t_b - t_a) / φ
    
    if elevation(t_c) > elevation(t_d):
        t_b = t_d
    else:
        t_a = t_c
```

**Reference:** Numerical Recipes, Chapter 10.2

## Atmospheric Refraction

Atmospheric refraction bends light rays, making objects appear higher in the sky than their true geometric position. This effect is most pronounced at low elevations.

### Sæmundsson Formula

The satellite's position gives us the true (geometric) elevation, so we need a formula that takes true elevation as input. For true elevations above -1°:
```
h = el + 10.3 / (el + 5.11)
R = 1.02 / tan(h)  (refraction in arc minutes)
el_apparent = el + R / 60.0
```

Bennett's better-known formula (`R = 1 / tan(el + 7.31 / (el + 4.4))`) goes the other way: it takes the apparent elevation and returns the refraction to subtract. Feeding it a true elevation gives a slightly wrong answer near the horizon, which is why Ephemeris uses Sæmundsson's form. In Swift this is `CoordinateTransforms.apparentElevation(fromTrueElevationDeg:)`.

**Notes:**
- This formula assumes standard atmospheric conditions (10°C, 1010 mbar)
- Refraction is approximately 0.5° at the horizon
- Effect decreases rapidly with increasing elevation
- Below -1°, refraction becomes unpredictable, so the elevation is returned unchanged
- This is an optical model; radio refraction depends on humidity and is usually somewhat larger near the horizon

**Reference:** Sæmundsson, Sky and Telescope 72 (1986), as given in Meeus, *Astronomical Algorithms* (2nd ed.), Eq. 16.4

## Example Usage

### Basic Topocentric Calculation

```swift
import Ephemeris

// Parse satellite TLE
let tleString = """
ISS (ZARYA)
1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
"""
let tle = try TwoLineElement(from: tleString)
let sgp4 = try SGP4(tle: tle)

// Define observer location (Louisville, Kentucky)
let observer = Observer(
    latitudeDeg: 38.2542,
    longitudeDeg: -85.7594,
    altitudeMeters: 140
)

// Calculate current position
let topo = try sgp4.topocentric(at: Date(), for: observer)
print("Azimuth: \(topo.azimuthDeg)°")
print("Elevation: \(topo.elevationDeg)°")
print("Range: \(topo.rangeKm) km")
print("Range Rate: \(topo.rangeRateKmPerSec) km/s")
```

### Pass Prediction

```swift
// Predict passes over next 24 hours
let now = Date()
let tomorrow = now.addingTimeInterval(24 * 3600)

let passes = try sgp4.predictPasses(
    for: observer,
    from: now,
    to: tomorrow,
    minElevationDeg: 10.0,  // Only passes above 10°
    stepSeconds: 30          // 30-second search granularity
)

for (i, pass) in passes.enumerated() {
    print("\nPass \(i + 1):")
    print("  AOS: \(pass.aos.time) at \(pass.aos.azimuthDeg)° azimuth")
    print("  MAX: \(pass.culmination.time) at \(pass.culmination.elevationDeg)° elevation")
    print("  LOS: \(pass.los.time) at \(pass.los.azimuthDeg)° azimuth")
    print("  Duration: \(pass.duration) seconds")
}
```

### With Refraction Correction

```swift
// Apply atmospheric refraction for low-elevation observations
let topoRefracted = try sgp4.topocentric(
    at: Date(),
    for: observer,
    applyRefraction: true
)
print("Geometric Elevation: \(topo.elevationDeg)°")
print("Apparent Elevation: \(topoRefracted.elevationDeg)°")
```

## Performance Considerations

### Pass Prediction Performance

The computational cost scales with:
- **Time window**: Longer windows require more coarse search steps
- **Step size**: Smaller steps increase accuracy but take more time
- **Minimum elevation**: Higher thresholds filter out more passes

**Typical performance:**
- 24-hour window with 30-second steps: ~2,900 evaluation points
- Each topocentric calculation: ~50 μs on modern hardware
- Total time for 24-hour prediction: ~150 ms

### Optimization Tips

1. **Choose appropriate step size**: 30-60 seconds is usually sufficient
2. **Use minimum elevation threshold**: Filter out low-elevation passes you don't need
3. **Limit time window**: Only search the period you need
4. **Cache observer ECEF position**: If computing multiple satellites for same observer

## Accuracy

### Coordinate Transformations
- Geodetic to ECEF: Sub-meter accuracy using WGS-84 ellipsoid
- ECI to ECEF: Millimeter accuracy with proper GMST calculation
- Azimuth/Elevation: 0.01° accuracy or better

### Pass Prediction
- AOS/LOS times: 0.1 second accuracy (bisection tolerance)
- Maximum elevation: 0.1 second in time, 0.01° in elevation
- Very brief passes between samples are caught by the short-pass check, though a pass that only grazes the threshold can still be missed with a large step
- Pass elevations are geometric (no refraction)

### Limitations
- Accuracy is limited by the propagator: `SGP4` follows the TLE closely near its epoch, while `KeplerianOrbit` ignores drag and oblateness and drifts quickly
- Polar motion (a few meters) is neglected in the ECI to ECEF rotation
- Refraction model assumes standard atmosphere
- Does not include parallax correction for close objects

## References

1. **Vallado, David A.** *Fundamentals of Astrodynamics and Applications* (4th Edition). Microcosm Press, 2013.
   - Primary reference for coordinate transformations
   - Chapter 3: Coordinate Systems
   - Chapter 4: Time and Coordinate Systems

2. **Montenbruck, Oliver and Gill, Eberhard.** *Satellite Orbits: Models, Methods and Applications*. Springer, 2000.
   - Section 5.4: Topocentric Coordinates

3. **Meeus, Jean.** *Astronomical Algorithms* (2nd Edition). Willmann-Bell, 1998.
   - Chapter 16: Atmospheric Refraction (Sæmundsson's and Bennett's formulas)

4. **Press, William H., et al.** *Numerical Recipes: The Art of Scientific Computing* (3rd Edition). Cambridge University Press, 2007.
   - Chapter 10: Minimization or Maximization of Functions
   - Golden-section search algorithm

## Swift Implementation in Ephemeris

Now let's see how Ephemeris implements these coordinate transformations and pass prediction algorithms in Swift.

### The `Observer` Type

The `Observer` struct represents a ground-based observer location:

```swift
import Ephemeris

// Create an observer (Louisville, Kentucky)
let observer = Observer(
    latitudeDeg: 38.2542,       // Latitude (degrees)
    longitudeDeg: -85.7594,     // Longitude (degrees, positive = east)
    altitudeMeters: 140         // Altitude above sea level (meters)
)

print("Observer location: \(observer.latitudeDeg)° lat, \(observer.longitudeDeg)° lon")
```

### Calculating Topocentric Coordinates

The `topocentric(at:for:)` method performs the complete transformation chain:

```swift
import Ephemeris
import Foundation

// Parse satellite TLE
let tleString = """
ISS (ZARYA)
1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
"""

let tle = try TwoLineElement(from: tleString)
let sgp4 = try SGP4(tle: tle)

// Calculate current look angles
let topo = try sgp4.topocentric(at: Date(), for: observer)

print("Azimuth: \(topo.azimuthDeg)°")          // Direction (0° = North)
print("Elevation: \(topo.elevationDeg)°")      // Angle above horizon
print("Range: \(topo.rangeKm) km")             // Distance to satellite
print("Range Rate: \(topo.rangeRateKmPerSec) km/s")  // Velocity

// Check if satellite is visible
if topo.elevationDeg > 0 {
    print("Satellite is above the horizon!")
} else {
    print("Satellite is below the horizon")
}
```

**The `Topocentric` Type:**

```swift
public struct Topocentric: Hashable, Codable, Sendable {
    public let azimuthDeg: Degrees       // 0-360°, clockwise from north
    public let elevationDeg: Degrees     // -90 to +90°
    public let rangeKm: Double           // Distance in km
    public let rangeRateKmPerSec: Double // Positive when moving away
}
```

### Atmospheric Refraction Correction

Apply refraction for low-elevation observations:

```swift
// Without refraction (geometric elevation)
let topoGeometric = try sgp4.topocentric(
    at: Date(),
    for: observer,
    applyRefraction: false
)

// With refraction (apparent elevation)
let topoRefracted = try sgp4.topocentric(
    at: Date(),
    for: observer,
    applyRefraction: true
)

print("Geometric elevation: \(topoGeometric.elevationDeg)°")
print("Apparent elevation: \(topoRefracted.elevationDeg)°")
print("Refraction correction: \(topoRefracted.elevationDeg - topoGeometric.elevationDeg)°")
```

### Predicting Satellite Passes

The `predictPasses(for:from:to:minElevationDeg:stepSeconds:)` method uses bisection and golden-section search:

```swift
import Ephemeris
import Foundation

// Define observer
let observer = Observer(
    latitudeDeg: 38.2542,
    longitudeDeg: -85.7594,
    altitudeMeters: 140
)

// Parse satellite TLE
let tle = try TwoLineElement(from: issTLEString)
let sgp4 = try SGP4(tle: tle)

// Predict passes over next 24 hours
let now = Date()
let tomorrow = now.addingTimeInterval(24 * 3600)

let passes = try sgp4.predictPasses(
    for: observer,
    from: now,
    to: tomorrow,
    minElevationDeg: 10.0,  // Only passes above 10° elevation
    stepSeconds: 30          // Search every 30 seconds
)

print("Found \(passes.count) passes in the next 24 hours\n")

// Display each pass
for (i, pass) in passes.enumerated() {
    print("Pass #\(i + 1):")
    print("  AOS: \(pass.aos.time)")
    print("    Azimuth: \(String(format: "%.1f", pass.aos.azimuthDeg))°")
    print("    Elevation: \(String(format: "%.1f", pass.aos.elevationDeg))°")
    print("  MAX: \(pass.culmination.time)")
    print("    Azimuth: \(String(format: "%.1f", pass.culmination.azimuthDeg))°")
    print("    Elevation: \(String(format: "%.1f", pass.culmination.elevationDeg))°")
    print("  LOS: \(pass.los.time)")
    print("    Azimuth: \(String(format: "%.1f", pass.los.azimuthDeg))°")
    print("    Elevation: \(String(format: "%.1f", pass.los.elevationDeg))°")
    print("  Duration: \(Int(pass.duration)) seconds\n")
}
```

**The `PassWindow` Type:**

```swift
public struct PassWindow: Hashable, Codable, Sendable {
    public struct Event: Hashable, Codable, Sendable {
        public let time: Date
        public let azimuthDeg: Degrees
        public let elevationDeg: Degrees
    }

    public let aos: Event          // Acquisition of Signal
    public let culmination: Event  // Maximum elevation
    public let los: Event          // Loss of Signal
    public let beginsBeforeSearch: Bool  // Already up at the start of the search window
    public let endsAfterSearch: Bool     // Still up at the end of the search window
    public var duration: TimeInterval { los.time.timeIntervalSince(aos.time) }
}
```

### Coordinate Transform Utilities

Ephemeris provides the `CoordinateTransforms` utility for manual transformations:

```swift
import Ephemeris

let observer = Observer(
    latitudeDeg: 38.2542,
    longitudeDeg: -85.7594,
    altitudeMeters: 140
)

// Observer geodetic → ECEF (GeodeticPosition altitude is in km)
let observerECEF = CoordinateTransforms.geodeticToECEF(observer.geodeticPosition)

// Satellite ECI → ECEF → ENU → azimuth/elevation, by hand
let date = Date()
let state = try sgp4.stateVector(at: date)
let satelliteECEF = CoordinateTransforms.eciToECEF(state.position, gmst: date.greenwichMeanSiderealTime)
let enu = CoordinateTransforms.ecefToENU(satelliteECEF, observer: observer.geodeticPosition)
let lookAngles = CoordinateTransforms.enuToAzEl(enu)
print("Az: \(lookAngles.azimuthDeg)°, El: \(lookAngles.elevationDeg)°, Range: \(lookAngles.rangeKm) km")

// Vector3D supports +, -, * scalar, dot(_:) and magnitude
let lineOfSight = satelliteECEF - observerECEF
print("Range check: \(lineOfSight.magnitude) km")

// Physical constants used in the transformations
print("Earth's μ: \(PhysicalConstants.Earth.mu) km³/s²")
print("Earth equatorial radius: \(PhysicalConstants.Earth.semiMajorAxis) km")
```

### Complete Example: Real-Time Satellite Tracker

```swift
import Ephemeris
import Foundation

func trackSatelliteInRealTime(propagator: Propagator, observer: Observer, duration: TimeInterval) throws {
    let startTime = Date()
    let endTime = startTime.addingTimeInterval(duration)
    var currentTime = startTime

    print("=== Real-Time Satellite Tracking ===")
    print("Observer: \(observer.latitudeDeg)° lat, \(observer.longitudeDeg)° lon\n")

    while currentTime <= endTime {
        let topo = try propagator.topocentric(at: currentTime, for: observer)

        let formatter = DateFormatter()
        formatter.timeStyle = .medium

        print("[\(formatter.string(from: currentTime))]")
        print("  Az: \(String(format: "%6.2f", topo.azimuthDeg))° " +
              "El: \(String(format: "%6.2f", topo.elevationDeg))° " +
              "Range: \(String(format: "%7.1f", topo.rangeKm)) km " +
              "Rate: \(String(format: "%+6.2f", topo.rangeRateKmPerSec)) km/s")

        if topo.elevationDeg > 0 {
            print("  >>> VISIBLE <<<")
        }

        // Update every 10 seconds
        currentTime = currentTime.addingTimeInterval(10)
        print()
    }
}

// Usage
let tle = try TwoLineElement(from: issTLEString)
let sgp4 = try SGP4(tle: tle)
let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

try trackSatelliteInRealTime(propagator: sgp4, observer: observer, duration: 600)  // Track for 10 minutes
```

### Performance Considerations

**Topocentric Calculation:**
- Single calculation: ~50 microseconds
- Includes: position propagation, all coordinate transformations, azimuth/elevation
- Suitable for real-time tracking at 10 Hz+ update rates

**Pass Prediction:**
- 24-hour window, 30-second steps: ~2,900 evaluation points
- Bisection refinement: ~10 iterations per AOS/LOS (to 0.1 s)
- Golden-section search: ~15 iterations for max elevation
- Total time: ~150-200 ms for typical LEO satellite

**Optimization Tips:**
1. Use larger `stepSeconds` for faster searches (trade-off: may miss brief passes)
2. Increase `minElevationDeg` to filter low-quality passes
3. Limit search window to required time period
4. Cache TLE parsing if tracking multiple passes from same TLE

---

## See Also

**Learning Path:**
- **Previous**: [Orbital Elements](orbital-elements.md) - Foundation of satellite motion
- **Next**: [Visualization](visualization.md) - Ground tracks and sky tracks

**Practical Guides:**
- [Getting Started](getting-started.md) - Quick-start tutorial

**Deep Dives:**
- [Coordinate Transformations](coordinate-transformations.md) - Mathematical foundations

---

## References

1. **Vallado, David A.** *Fundamentals of Astrodynamics and Applications* (4th Edition). Microcosm Press, 2013.
   - Primary reference for coordinate transformations
   - Chapter 3: Coordinate Systems
   - Chapter 4: Time and Coordinate Systems

2. **Montenbruck, Oliver and Gill, Eberhard.** *Satellite Orbits: Models, Methods and Applications*. Springer, 2000.
   - Section 5.4: Topocentric Coordinates

3. **Meeus, Jean.** *Astronomical Algorithms* (2nd Edition). Willmann-Bell, 1998.
   - Chapter 16: Atmospheric Refraction (Sæmundsson's and Bennett's formulas)

4. **Press, William H., et al.** *Numerical Recipes: The Art of Scientific Computing* (3rd Edition). Cambridge University Press, 2007.
   - Chapter 10: Minimization or Maximization of Functions
   - Golden-section search algorithm

## Additional Resources

- [WGS-84 Reference](http://www.unoosa.org/pdf/icg/2012/template/WGS_84.pdf)
- [Celestrak: Orbit Basics](https://celestrak.org/columns/v02n01/)
- [Earth Observation Portal: Coordinate Systems](https://earth.esa.int/web/eoportal/satellite-missions/o/orbview-1)

---

*This documentation is part of the [Ephemeris](https://github.com/mvdmakesthings/Ephemeris) framework for satellite tracking in Swift.*

**Last Updated**: October 20, 2025
**Version**: 1.0
