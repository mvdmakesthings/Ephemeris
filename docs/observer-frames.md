# Observer-Centered Coordinate Frames

> **Brief Description**: Learn about local topocentric coordinate systems including East-North-Up (ENU) and horizontal coordinates (azimuth, elevation) for satellite visibility calculations.

## Overview

While global coordinate systems (ECI, ECEF) describe satellite positions in space, **observer-centered coordinate frames** are essential for determining whether a satellite is visible from a specific location on Earth and where to point antennas or telescopes.

**Theory-First Approach**: We begin with the mathematical concept of local tangent planes, define the ENU coordinate system, derive horizontal coordinates (azimuth and elevation), and show how these relate to satellite tracking applications.

**What You'll Learn:**
- The local tangent plane concept
- East-North-Up (ENU) coordinate system definition
- Transformation from ECEF to ENU
- Horizontal coordinates (azimuth, elevation, range)
- Elevation angle and horizon visibility
- Applications in pass prediction and antenna pointing
- How Ephemeris implements topocentric coordinates

---

## Table of Contents

- [The Local Tangent Plane](#the-local-tangent-plane)
- [East-North-Up (ENU) Coordinates](#east-north-up-enu-coordinates)
- [ECEF to ENU Transformation](#ecef-to-enu-transformation)
- [Horizontal Coordinates](#horizontal-coordinates)
- [Azimuth and Elevation](#azimuth-and-elevation)
- [Range and Range Rate](#range-and-range-rate)
- [Visibility and Horizon](#visibility-and-horizon)
- [Applications in Satellite Tracking](#applications-in-satellite-tracking)
- [Ephemeris Implementation](#ephemeris-implementation)
- [See Also](#see-also)
- [References](#references)

---

## The Local Tangent Plane

### Concept

A **local tangent plane** is a flat surface that touches (is tangent to) the Earth's ellipsoid at a specific observer location. This plane provides a natural reference for describing directions and positions relative to that observer.

**Analogy**: Imagine standing on Earth's surface. Your local horizon appears flat, and the sky appears as a hemisphere above you. The local tangent plane is the mathematical representation of this flat horizon.

### Mathematical Definition

For an observer at geodetic coordinates $(\phi_{obs}, \lambda_{obs}, h_{obs})$:

**Tangent Plane**:
- **Origin**: At the observer's location
- **Orientation**: Perpendicular to the local vertical (surface normal direction)
- **Axes**: Aligned with cardinal directions (East, North) and vertical (Up)

The tangent plane is perpendicular to the **geodetic vertical** (the surface normal to the WGS-84 ellipsoid at the observer's location).

### Why Local Frames?

**Global vs Local**:
- **ECEF**: Good for describing absolute positions in space
- **Local**: Natural for describing relative positions from observer's perspective

**Practical advantages**:
1. **Intuitive**: East/North/Up matches human perception
2. **Simple distance**: Euclidean distance in flat plane (for nearby objects)
3. **Visibility**: Elevation angle directly indicates if satellite is above horizon
4. **Antenna pointing**: Azimuth and elevation are exactly what servos need

### Limitations

**Small area approximation**:
- Assumes Earth is locally flat
- Valid for distances << Earth's radius (~100-1000 km)
- For global positioning, must use ECEF or geodetic

---

## East-North-Up (ENU) Coordinates

### Definition

The **East-North-Up (ENU)** coordinate system is a Cartesian coordinate frame centered at the observer with:

**E-axis** ($\hat{\mathbf{e}}$): Points **East** along the local horizon
- Perpendicular to local meridian
- Lies in the tangent plane
- Positive eastward direction

**N-axis** ($\hat{\mathbf{n}}$): Points **North** along the local horizon
- Lies in the meridian plane
- Lies in the tangent plane
- Positive northward direction (toward North Pole)

**U-axis** ($\hat{\mathbf{u}}$): Points **Up** perpendicular to tangent plane
- Aligned with local vertical (geodetic zenith)
- Perpendicular to both E and N axes
- Positive upward (away from Earth's center)

**Right-handed system**: $\hat{\mathbf{u}} = \hat{\mathbf{e}} \times \hat{\mathbf{n}}$

### Visual Representation


![ENU Coordinate System](https://upload.wikimedia.org/wikipedia/commons/7/73/ECEF_ENU_Longitude_Latitude_relationships.svg)
*Figure 1: East-North-Up (ENU) local coordinate system and its relationship to ECEF, longitude, and latitude. The E-axis points east along the local horizon, N-axis points north, and U-axis points toward zenith. Source: Mike1024, [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:ECEF_ENU_Longitude_Latitude_relationships.svg), public domain.*

### ENU Unit Vectors in ECEF

The ENU unit vectors can be expressed in ECEF coordinates using the observer's geodetic latitude $\phi$ and longitude $\lambda$:

**East unit vector**:
$$
\hat{\mathbf{e}} = \begin{bmatrix} -\sin(\lambda) \\ \cos(\lambda) \\ 0 \end{bmatrix}_{ECEF}
$$

**North unit vector**:
$$
\hat{\mathbf{n}} = \begin{bmatrix} -\sin(\phi)\cos(\lambda) \\ -\sin(\phi)\sin(\lambda) \\ \cos(\phi) \end{bmatrix}_{ECEF}
$$

**Up unit vector**:
$$
\hat{\mathbf{u}} = \begin{bmatrix} \cos(\phi)\cos(\lambda) \\ \cos(\phi)\sin(\lambda) \\ \sin(\phi) \end{bmatrix}_{ECEF}
$$

**Note**: The up vector $\hat{\mathbf{u}}$ points along the geodetic vertical (surface normal), not toward Earth's center.

### NEU vs ENU Convention

**Two conventions exist**:

**North-East-Up (NEU)**:
- Common in geodesy and surveying
- X-axis = North, Y-axis = East, Z-axis = Up

**East-North-Up (ENU)**:
- Common in aerospace and navigation
- X-axis = East, Y-axis = North, Z-axis = Up

**Ephemeris uses ENU** (East-North-Up) following aerospace conventions.

**Conversion**: Simply swap the first two coordinates
$$
(E, N, U)_{ENU} = (N, E, U)_{NEU}
$$

---

## ECEF to ENU Transformation

### The Transformation Problem

**Given**:
- Observer position in ECEF: $\mathbf{r}_{obs}$
- Satellite position in ECEF: $\mathbf{r}_{sat}$

**Find**: Satellite position relative to observer in ENU coordinates

### Relative Position Vector

First, compute the relative position (satellite minus observer):

$$
\Delta\mathbf{r} = \mathbf{r}_{sat} - \mathbf{r}_{obs} = \begin{bmatrix} \Delta X \\ \Delta Y \\ \Delta Z \end{bmatrix}_{ECEF}
$$

This vector points from observer to satellite in ECEF coordinates.

### Rotation Matrix

The transformation from ECEF to ENU involves a rotation based on the observer's geodetic latitude $\phi$ and longitude $\lambda$:

$$
\begin{bmatrix} E \\ N \\ U \end{bmatrix} = \mathbf{R}_{ECEF \to ENU} \begin{bmatrix} \Delta X \\ \Delta Y \\ \Delta Z \end{bmatrix}
$$

where the rotation matrix is:

$$
\mathbf{R}_{ECEF \to ENU} = \begin{bmatrix}
-\sin(\lambda) & \cos(\lambda) & 0 \\
-\sin(\phi)\cos(\lambda) & -\sin(\phi)\sin(\lambda) & \cos(\phi) \\
\cos(\phi)\cos(\lambda) & \cos(\phi)\sin(\lambda) & \sin(\phi)
\end{bmatrix}
$$

### Derivation Overview

The transformation matrix arises from two sequential rotations:

**Step 1**: Rotate about Z-axis by $-\lambda$ (aligns X-axis with local meridian)

**Step 2**: Rotate about Y-axis by $(90° - \phi)$ (aligns Z-axis with local vertical)

**Combined**: The product of these two rotation matrices yields $\mathbf{R}_{ECEF \to ENU}$

For detailed derivation, see [Coordinate Transformations](coordinate-transformations.md).

### Example Calculation

**Observer** (Royal Observatory, Greenwich):
- $\phi = 51.4778°$, $\lambda = 0°$
- ECEF position: $\mathbf{r}_{obs} = (3980574, 0, 4966825)$ m

**Satellite** (example):
- ECEF position: $\mathbf{r}_{sat} = (4200000, 1500000, 5100000)$ m

**Relative position**:
$$
\Delta\mathbf{r} = (4200000 - 3980574, 1500000 - 0, 5100000 - 4966825) = (219426, 1500000, 133175) \text{ m}
$$

**Rotation matrix** (with $\phi = 51.4778°$, $\lambda = 0°$):
$$
\mathbf{R} = \begin{bmatrix}
0 & 1 & 0 \\
-0.7806 & 0 & 0.6250 \\
0.6250 & 0 & 0.7806
\end{bmatrix}
$$

**ENU coordinates**:
$$
\begin{bmatrix} E \\ N \\ U \end{bmatrix} = \begin{bmatrix}
0 & 1 & 0 \\
-0.7806 & 0 & 0.6250 \\
0.6250 & 0 & 0.7806
\end{bmatrix} \begin{bmatrix} 219426 \\ 1500000 \\ 133175 \end{bmatrix} = \begin{bmatrix} 1500000 \\ -88083 \\ 241223 \end{bmatrix} \text{ m}
$$

**Result**: Satellite is **1500 km east**, **88 km south**, and **241 km up** from the observer.

---

## Horizontal Coordinates

### Definition

**Horizontal coordinates** (also called **topocentric coordinates** or **alt-azimuth coordinates**) describe the position of a satellite in the observer's sky using:

1. **Azimuth** ($A$ or $Az$): Compass bearing
2. **Elevation** ($E$ or $El$): Angle above horizon
3. **Range** ($\rho$): Distance to satellite

These are **spherical coordinates** derived from the ENU Cartesian coordinates.

![Horizontal Coordinate System](https://upload.wikimedia.org/wikipedia/commons/f/f7/Azimuth-Altitude_schematic.svg)
*Figure 2: Horizontal coordinate system (also called alt-azimuth system) showing azimuth and elevation (altitude). Azimuth is measured clockwise from north along the horizon, elevation is the angle above the horizon toward zenith. Source: TWCarlson, [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Azimuth-Altitude_schematic.svg), licensed under [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).*

---

## Azimuth and Elevation

### Azimuth

**Definition**: The compass bearing from observer to satellite, measured clockwise from **North**.

$$
A = \arctan2(E, N)
$$

where `arctan2(y, x)` is the four-quadrant arctangent function.

**Range**: $0°$ to $360°$ (or $-180°$ to $+180°$)

**Cardinal directions**:
- $A = 0°$ (or $360°$): North
- $A = 90°$: East
- $A = 180°$: South
- $A = 270°$: West

**Calculation note**: Use `atan2(E, N)` to handle all quadrants correctly. Most programming languages return values in $[-\pi, \pi]$, which may need conversion to $[0°, 360°]$.

### Elevation

**Definition**: The angle above the local horizon, measured from the tangent plane.

$$
El = \arcsin\left(\frac{U}{\sqrt{E^2 + N^2 + U^2}}\right) = \arcsin\left(\frac{U}{\rho}\right)
$$

Equivalently:
$$
El = \arctan\left(\frac{U}{\sqrt{E^2 + N^2}}\right)
$$

**Range**: $-90°$ to $+90°$

**Special values**:
- $El = 0°$: Satellite on horizon
- $El = 90°$: Satellite directly overhead (zenith)
- $El = -90°$: Satellite directly below (nadir)

**Visibility**: Satellite is visible when $El > 0°$

### Zenith Angle

An alternative to elevation is the **zenith angle** $z$:

$$
z = 90° - El
$$

**Range**: $0°$ to $180°$

**Special values**:
- $z = 0°$: Zenith (directly overhead)
- $z = 90°$: Horizon
- $z = 180°$: Nadir (directly below)

Some fields (astronomy) prefer zenith angle, others (aviation, satellite tracking) prefer elevation.

### Example

From the previous ECEF→ENU calculation:
- $E = 1,500,000$ m
- $N = -88,083$ m
- $U = 241,223$ m

**Azimuth**:
$$
A = \arctan2(1500000, -88083) = 93.36° \text{ (slightly south of due east)}
$$

**Elevation**:
$$
\rho = \sqrt{1500000^2 + (-88083)^2 + 241223^2} \approx 1,519,485 \text{ m}
$$
$$
El = \arcsin(241223 / 1519485) = 9.13° \text{ (low on horizon)}
$$

---

## Range and Range Rate

### Range

**Range** ($\rho$) is the straight-line distance from observer to satellite:

$$
\rho = \sqrt{E^2 + N^2 + U^2} = ||\Delta\mathbf{r}_{ENU}||
$$

Alternatively, in ECEF:
$$
\rho = ||\Delta\mathbf{r}_{ECEF}|| = ||\mathbf{r}_{sat} - \mathbf{r}_{obs}||
$$

**Units**: Typically kilometers (km) or meters (m)

### Range Rate

**Range rate** ($\dot{\rho}$) is the rate of change of range—how fast the satellite is approaching or receding from the observer.

$$
\dot{\rho} = \frac{d\rho}{dt} = \frac{\Delta\mathbf{r} \cdot \Delta\mathbf{v}}{||\Delta\mathbf{r}||}
$$

where:
- $\Delta\mathbf{r} = \mathbf{r}_{sat} - \mathbf{r}_{obs}$ (relative position)
- $\Delta\mathbf{v} = \mathbf{v}_{sat} - \mathbf{v}_{obs}$ (relative velocity)
- The dot $\cdot$ denotes vector dot product

**Interpretation**:
- $\dot{\rho} > 0$: Satellite receding (moving away)
- $\dot{\rho} < 0$: Satellite approaching (moving closer)
- $\dot{\rho} = 0$: Closest approach or furthest point

**Units**: km/s or m/s

**Physical meaning**: Component of relative velocity along the line of sight.

### Doppler Shift

Range rate is directly related to **Doppler shift** in radio communications:

$$
\Delta f = -\frac{f_0 \dot{\rho}}{c}
$$

where:
- $f_0$ = transmitted frequency
- $c$ = speed of light (299,792 km/s)
- $\Delta f$ = observed frequency shift

**Example**: For an L-band satellite at 1.5 GHz with $\dot{\rho} = -3$ km/s:
$$
\Delta f = -\frac{1.5 \times 10^9 \times (-3)}{299792} \approx +15 \text{ kHz}
$$

Approaching satellites have **positive** Doppler shifts (higher frequency).

---

## Visibility and Horizon

### Geometric Horizon

A satellite is geometically visible when its elevation angle exceeds zero:

$$
\text{Visible} \iff El > 0° \iff U > 0
$$

**Horizon line**: The circle on the celestial sphere at $El = 0°$

### Practical Visibility

**Real-world considerations** modify this simple criterion:

**1. Atmospheric Refraction**:
- Light bends when passing through atmosphere
- Satellites appear ~0.5° higher than geometric position at horizon
- Effect diminishes with increasing elevation

**2. Terrain Obstructions**:
- Mountains, buildings, trees block line of sight
- Must have clear path to satellite

**3. Minimum Elevation for Tracking**:
- Atmospheric distortion increases near horizon
- Signal-to-noise ratio degrades
- **Typical minimum**: 5° to 10° elevation for reliable satellite contact

### Atmospheric Refraction Correction

The **Bennett formula** (1982) approximates refraction:

$$
R = \frac{1.02}{\tan(El + \frac{10.3}{El + 5.11})}
$$

where $R$ is the refraction correction in arcminutes and $El$ is in degrees.

**Apparent elevation**:
$$
El_{apparent} = El_{geometric} + R
$$

**Example**: At $El = 0°$ (horizon):
$$
R \approx 34 \text{ arcminutes} = 0.57°
$$

This is why the Sun appears to rise before it geometrically clears the horizon.

---

## Applications in Satellite Tracking

### Pass Prediction

**Satellite pass**: Period when satellite is visible (elevation > threshold)

**Key events**:
1. **AOS (Acquisition of Signal)**: Satellite rises above minimum elevation
2. **TCA (Time of Closest Approach)**: Maximum elevation reached
3. **LOS (Loss of Signal)**: Satellite drops below minimum elevation

**Calculation**:
```
For each time step:
  1. Calculate satellite position (ECEF)
  2. Transform to observer ENU
  3. Compute elevation angle
  4. If elevation crosses threshold → mark AOS or LOS
```

For details on the bisection algorithm used, see [Observer Geometry](observer-geometry.md).

### Antenna Pointing

**Ground station tracking**: Point antenna at satellite as it moves across sky

**Required information**:
- **Azimuth**: Rotate antenna in horizontal plane
- **Elevation**: Tilt antenna above horizon

**Servo control**: Most antenna mounts use (Az, El) directly:
```
azimuthMotor.setAngle(A)
elevationMotor.setAngle(El)
```

**Tracking rate**: As satellite moves, continuously update angles

**Predict-ahead**: Account for servo lag by predicting position 1-2 seconds ahead

### Sky Track Visualization

**Sky track**: Path of satellite across observer's sky

**Polar plot**: Commonly displayed on polar diagram
- **Radial axis**: Zenith angle $z$ (0° at center = overhead)
- **Angular axis**: Azimuth (0° = North at top)

**Sky Track Polar Plot Example:**

A polar plot visualization of a satellite pass would show:
- **Center**: Zenith (90° elevation, directly overhead)
- **Outer circle**: Horizon (0° elevation)
- **Concentric circles**: Elevation angle increments (typically 10°, 20°, 30°, etc.)
- **Radial lines**: Azimuth directions (N, E, S, W marked)
- **Satellite track**: Curved line showing the satellite's path across the sky from AOS to LOS

*Note: Sky track polar plots can be generated using tools like MATLAB's `skyplot()` function, Python satellite tracking libraries (e.g., Skyfield, pyorbital), or online satellite tracking services. See the [Visualization](visualization.md) guide for SwiftUI implementation examples.*

For SwiftUI implementation, see [Visualization](visualization.md).

### Communications Link Budget

**Free-space path loss** depends on range:

$$
L_{path} = 20 \log_{10}\left(\frac{4\pi \rho}{\lambda}\right) \text{ dB}
$$

where:
- $\rho$ = range to satellite
- $\lambda$ = wavelength of radio signal

**Atmospheric attenuation** increases at low elevations:
- More atmosphere to traverse
- Water vapor absorption
- Typically specify $El_{min} = 10°$ for reliable communications

---

## Ephemeris Implementation

### The Observer Type

Ephemeris represents an observer location:

```swift
import Ephemeris

let observer = Observer(
    latitudeDeg: 38.2542,      // Latitude in degrees
    longitudeDeg: -85.7594,    // Longitude in degrees
    altitudeMeters: 140        // Altitude in meters
)
```

Internally, `Observer`:
- Stores geodetic coordinates
- Converts to ECEF when needed for transformations
- Used in topocentric calculations

### Topocentric Coordinates

Calculate azimuth, elevation, range, and range rate:

```swift
import Ephemeris
import Foundation

// Observer location
let observer = Observer(
    latitudeDeg: 38.2542,
    longitudeDeg: -85.7594,
    altitudeMeters: 140
)

// Satellite orbit
let tle = try TwoLineElement(from: tleString)
let orbit = Orbit(from: tle)

// Calculate topocentric coordinates
let topo = try orbit.topocentric(at: Date(), for: observer)

print("Azimuth: \(topo.azimuthDeg)°")
print("Elevation: \(topo.elevationDeg)°")
print("Range: \(topo.rangeKm) km")
print("Range Rate: \(topo.rangeRateKmPerSec) km/s")

// Check visibility
if topo.elevationDeg > 0 {
    print("Satellite is visible!")
} else {
    print("Satellite is below horizon")
}
```

### The Topocentric Type

```swift
public struct Topocentric {
    public let azimuthDeg: Double        // 0-360°, clockwise from north
    public let elevationDeg: Double      // -90 to +90°
    public let rangeKm: Double           // Distance in km
    public let rangeRateKmPerSec: Double // Radial velocity
}
```

### Behind the Scenes

When you call `orbit.topocentric(at:for:)`, Ephemeris:

1. **Propagates orbit**: Calculates satellite position in ECI
2. **Transforms to ECEF**: Rotates by GMST
3. **Converts observer**: Geodetic → ECEF for observer
4. **Computes relative position**: $\Delta\mathbf{r} = \mathbf{r}_{sat} - \mathbf{r}_{obs}$
5. **Transforms to ENU**: Applies rotation matrix based on observer (φ, λ)
6. **Calculates Az/El**: Converts ENU to spherical coordinates
7. **Computes range rate**: Dot product of relative position and velocity

**See**: [Observer Geometry](observer-geometry.md) for full Swift implementation details.

### Pass Prediction

Predict when satellite is visible:

```swift
let passes = try orbit.predictPasses(
    for: observer,
    from: Date(),
    to: Date().addingTimeInterval(24 * 3600),  // Next 24 hours
    minElevationDeg: 10.0,   // Only passes above 10°
    stepSeconds: 30           // Search every 30 seconds
)

for pass in passes {
    print("AOS: \(pass.aos.time) at \(pass.aos.azimuthDeg)° Az")
    print("MAX: \(pass.max.time) at \(pass.max.elevationDeg)° El")
    print("LOS: \(pass.los.time) at \(pass.los.azimuthDeg)° Az")
    print("Duration: \(pass.duration) seconds\n")
}
```

The `predictPasses` method uses bisection to find AOS/LOS times and golden-section search to find maximum elevation. See [Observer Geometry](observer-geometry.md) for algorithm details.

---

## See Also

**Learning Path**:
- **Previous**: [Earth-Fixed Frames](earth-fixed-frames.md) - ECEF and geodetic coordinates
- **Next**: [Coordinate Transformations](coordinate-transformations.md) - Full transformation mathematics

**Related Concepts**:
- [Inertial Frames](inertial-frames.md) - ECI coordinate system
- [Time Systems](time-systems.md) - GMST for transformations

**Practical Guides**:
- [Observer Geometry](observer-geometry.md) - Complete Swift implementation with examples
- [Visualization](visualization.md) - Sky track plotting in SwiftUI
- [Getting Started](getting-started.md) - Build satellite tracker app

---

## References

1. **ESA Navipedia.** (2024). "Transformations between ECEF and ENU coordinates."
   - Detailed transformation formulas
   - Available: https://gssc.esa.int/navipedia/index.php/Transformations_between_ECEF_and_ENU_coordinates

2. **Vallado, David A.** (2013). *Fundamentals of Astrodynamics and Applications* (4th Edition). Microcosm Press.
   - Section 4.4: Topocentric Coordinate Systems
   - Azimuth and elevation calculations

3. **Montenbruck, Oliver, and Gill, Eberhard.** (2000). *Satellite Orbits: Models, Methods and Applications*. Springer.
   - Section 5.4: Topocentric Coordinates
   - Range and range rate formulas

4. **Bennett, G.G.** (1982). "The Calculation of Astronomical Refraction in Marine Navigation." *Journal of Navigation*, 35(2), 255-259.
   - Atmospheric refraction formula
   - Accurate to ~0.1 arcminutes for elevation > 15°

5. **Snyder, John P.** (1987). *Map Projections: A Working Manual*. U.S. Geological Survey Professional Paper 1395.
   - Local tangent plane coordinates
   - Geodetic reference systems

6. **Wertz, James R., and Larson, Wiley J. (eds.).** (1999). *Space Mission Analysis and Design* (3rd Edition). Microcosm Press and Kluwer Academic Publishers.
   - Chapter 11: Orbit and Constellation Design
   - Ground station visibility

7. **Kaplan, Elliott D., and Hegarty, Christopher J. (eds.).** (2006). *Understanding GPS: Principles and Applications* (2nd Edition). Artech House.
   - Chapter 4: Satellite Signal Acquisition and Tracking
   - ENU coordinate applications in GPS

### Image Sources

**Image 1**: East-North-Up (ENU) Coordinate System
- **Placeholder**: To be replaced with diagram from academic source
- **Shows**: ENU axes relative to observer on Earth's surface
- **Source**: ResearchGate or similar academic repository

**Image 2**: Horizontal Coordinate System
- **Placeholder**: To be replaced with azimuth/elevation diagram
- **Shows**: Azimuth measured from north, elevation from horizon
- **Source**: Academic textbook or paper on coordinate systems

**Image 3**: Sky Track Polar Plot
- **Placeholder**: To be replaced with example polar plot
- **Shows**: Satellite path across observer's sky in polar coordinates
- **Source**: Example from satellite tracking paper

---

*This documentation is part of the [Ephemeris](https://github.com/mvdmakesthings/Ephemeris) framework for satellite tracking in Swift.*

**Last Updated**: October 20, 2025
**Version**: 1.0
