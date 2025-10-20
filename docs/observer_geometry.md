# Observer Geometry and Pass Prediction

This document explains the mathematical foundations and coordinate transformations used in Ephemeris for computing satellite visibility from Earth-based observer locations.

## Overview

The observer support system enables you to:
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
- **Altitude**: Height above the WGS-84 reference ellipsoid (in meters)

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

Where `ω_earth` is Earth's angular velocity vector (0, 0, ω_z).

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

## Pass Prediction Algorithm

The `predictPasses(for:from:to:minElevationDeg:stepSeconds:)` method uses a three-stage approach:

### Stage 1: Coarse Search

Step through time at regular intervals (default 30 seconds) to detect elevation crossing events:
- **AOS Event**: Elevation transitions from below to above minimum threshold
- **LOS Event**: Elevation transitions from above to below minimum threshold

### Stage 2: Bisection Refinement

For each detected crossing, use bisection search to refine the time to ±1 second accuracy:

```
while (t_right - t_left > 1 second):
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

Use golden-section search to find the precise time and elevation of maximum elevation within each pass:

```
φ = (1 + √5) / 2  (golden ratio)

while (t_b - t_a > 1 second):
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

### Bennett Formula

For elevations above -1°:
```
h = el + 7.31 / (el + 4.4)
R = 1.0 / tan(h)  (refraction in arc minutes)
el_apparent = el + R / 60.0
```

**Notes:**
- This formula assumes standard atmospheric conditions (10°C, 1010 mbar)
- Refraction is approximately 0.5° at the horizon
- Effect decreases rapidly with increasing elevation
- Below -1°, refraction becomes unpredictable

**Reference:** Bennett, "The Calculation of Astronomical Refraction in Marine Navigation", Journal of Navigation (1982)

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
let orbit = Orbit(from: tle)

// Define observer location (Louisville, Kentucky)
let observer = Observer(
    latitudeDeg: 38.2542,
    longitudeDeg: -85.7594,
    altitudeMeters: 140
)

// Calculate current position
let topo = try orbit.topocentric(at: Date(), for: observer)
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

let passes = try orbit.predictPasses(
    for: observer,
    from: now,
    to: tomorrow,
    minElevationDeg: 10.0,  // Only passes above 10°
    stepSeconds: 30          // 30-second search granularity
)

for (i, pass) in passes.enumerated() {
    print("\nPass \(i + 1):")
    print("  AOS: \(pass.aos.time) at \(pass.aos.azimuthDeg)° azimuth")
    print("  MAX: \(pass.max.time) at \(pass.max.elevationDeg)° elevation")
    print("  LOS: \(pass.los.time) at \(pass.los.azimuthDeg)° azimuth")
    print("  Duration: \(pass.duration) seconds")
}
```

### With Refraction Correction

```swift
// Apply atmospheric refraction for low-elevation observations
let topoRefracted = try orbit.topocentric(
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
- AOS/LOS times: ±1 second accuracy (bisection tolerance)
- Maximum elevation: ±1 second in time, 0.01° in elevation
- Coarse search may miss very brief passes (< 30 seconds)

### Limitations
- Does not account for atmospheric drag perturbations
- Uses simplified two-body dynamics (not full SGP4/SDP4)
- Refraction model assumes standard atmosphere
- Does not include parallax correction for close objects

## References

1. **Vallado, David A.** *Fundamentals of Astrodynamics and Applications* (4th Edition). Microcosm Press, 2013.
   - Primary reference for coordinate transformations
   - Chapter 3: Coordinate Systems
   - Chapter 4: Time and Coordinate Systems

2. **Montenbruck, Oliver and Gill, Eberhard.** *Satellite Orbits: Models, Methods and Applications*. Springer, 2000.
   - Section 5.4: Topocentric Coordinates

3. **Bennett, G.G.** "The Calculation of Astronomical Refraction in Marine Navigation." *Journal of Navigation*, Vol. 35, No. 2, 1982, pp. 255-259.
   - Atmospheric refraction formula

4. **Press, William H., et al.** *Numerical Recipes: The Art of Scientific Computing* (3rd Edition). Cambridge University Press, 2007.
   - Chapter 10: Minimization or Maximization of Functions
   - Golden-section search algorithm

## Additional Resources

- [WGS-84 Reference](http://www.unoosa.org/pdf/icg/2012/template/WGS_84.pdf)
- [Celestrak: Orbit Basics](https://celestrak.org/columns/v02n01/)
- [Earth Observation Portal: Coordinate Systems](https://earth.esa.int/web/eoportal/satellite-missions/o/orbview-1)
