# Earth-Fixed Reference Frames and Geodetic Coordinates

> **Brief Description**: Learn about Earth-Centered Earth-Fixed (ECEF) coordinates, the WGS-84 ellipsoid, and geodetic coordinate transformations for satellite position calculations.

## Overview

While inertial frames are essential for orbital mechanics, **Earth-fixed frames** that rotate with the planet are crucial for mapping satellite positions to specific locations on Earth's surface. The **Earth-Centered Earth-Fixed (ECEF)** coordinate system and **geodetic coordinates** (latitude, longitude, altitude) provide this connection.

**Theory-First Approach**: We begin with the mathematical definition of ECEF, introduce the WGS-84 ellipsoid standard, explain geodetic coordinates in detail, and derive the transformation formulas between these systems.

**What You'll Learn:**
- The ECEF coordinate system and its rotation
- The WGS-84 ellipsoid and its parameters
- Geodetic vs geocentric latitude
- ECEF ↔ Geodetic coordinate transformations
- Practical applications in satellite tracking
- How Ephemeris implements these conversions

---

## Table of Contents

- [Earth-Centered Earth-Fixed (ECEF)](#earth-centered-earth-fixed-ecef)
- [Earth's Rotation Rate](#earths-rotation-rate)
- [The WGS-84 Reference Ellipsoid](#the-wgs-84-reference-ellipsoid)
- [Geodetic Coordinates](#geodetic-coordinates)
- [Geodetic vs Geocentric Latitude](#geodetic-vs-geocentric-latitude)
- [Geodetic to ECEF Transformation](#geodetic-to-ecef-transformation)
- [ECEF to Geodetic Transformation](#ecef-to-geodetic-transformation)
- [Applications in Satellite Tracking](#applications-in-satellite-tracking)
- [Ephemeris Implementation](#ephemeris-implementation)
- [See Also](#see-also)
- [References](#references)

---

## Earth-Centered Earth-Fixed (ECEF)

### Definition

The **Earth-Centered Earth-Fixed (ECEF)** coordinate system is a Cartesian coordinate system that:

- **Origin**: Located at Earth's center of mass (geocenter)
- **Rotation**: Rotates with Earth (completes one rotation per sidereal day)
- **Axes**: Fixed to Earth's surface, defined by the equator and prime meridian

**Key difference from ECI**: While ECI is inertial (non-rotating), ECEF rotates with Earth at approximately **one revolution per 23 hours, 56 minutes, and 4 seconds** (one sidereal day).

### ECEF Coordinate Axes

**X-axis** ($\hat{\mathbf{x}}_{ECEF}$):
$$
\text{Points through the intersection of the equator and prime meridian (0° latitude, 0° longitude)}
$$
- Passes through the Greenwich meridian
- Intersects Earth's surface in the Gulf of Guinea (near Africa)
- Also called the **Greenwich direction**

**Z-axis** ($\hat{\mathbf{z}}_{ECEF}$):
$$
\text{Points toward the North Pole (along Earth's rotation axis)}
$$
- Coincides with the Earth's spin axis
- Same as the ECI Z-axis direction (at any given instant)
- Perpendicular to the equatorial plane

**Y-axis** ($\hat{\mathbf{y}}_{ECEF}$):
$$
\hat{\mathbf{y}}_{ECEF} = \hat{\mathbf{z}}_{ECEF} \times \hat{\mathbf{x}}_{ECEF}
$$
- Completes right-handed coordinate system
- Points through 90° East longitude on the equator
- Lies in the equatorial plane

### Visual Representation


![ECEF Coordinate System](https://upload.wikimedia.org/wikipedia/commons/6/62/Ecef_coordinates.svg)
*Figure 1: Earth-Centered Earth-Fixed (ECEF) Coordinate System. The X-axis passes through the prime meridian at the equator, the Y-axis points through 90° East longitude, and the Z-axis points toward the North Pole. The frame rotates with Earth. Source: Chuckage, [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Ecef_coordinates.svg), licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).*

### Relationship to ECI

At any instant in time, the ECEF axes can be related to the ECI axes by a rotation about the Z-axis:

$$
\mathbf{r}_{ECEF}(t) = \mathbf{R}_z(\theta_{GMST}(t)) \cdot \mathbf{r}_{ECI}
$$

where:
- $\theta_{GMST}(t)$ = Greenwich Mean Sidereal Time at time $t$ (see [Time Systems](time-systems.md))
- $\mathbf{R}_z$ = rotation matrix about the Z-axis

The Z-axes coincide, but the X and Y axes rotate as Earth spins.

---

## Earth's Rotation Rate

### Mean Sidereal Day

Earth's rotation is measured relative to distant stars, not the Sun. This defines the **sidereal day**:

$$
T_{sidereal} = 23^h 56^m 4.0905^s = 86164.0905 \text{ seconds}
$$

**Sidereal vs Solar Day**:
- **Sidereal day**: Time for Earth to rotate 360° relative to stars (86,164 s)
- **Solar day**: Time for Sun to return to same position in sky (86,400 s)
- **Difference**: ~3 minutes 56 seconds

The difference arises because Earth orbits the Sun. After one sidereal rotation, Earth must rotate an additional ~1° to bring the Sun back to the same position.

### Angular Velocity

Earth's mean angular velocity is:

$$
\omega_{\oplus} = \frac{2\pi}{T_{sidereal}} = \frac{2\pi}{86164.0905} \approx 7.2921159 \times 10^{-5} \text{ rad/s}
$$

**Alternative expression** (used in WGS-84):
$$
\omega_{WGS84} = 7.292115 \times 10^{-5} \text{ rad/s}
$$

**In degrees per day**:
$$
\omega_{\oplus} = \frac{360°}{T_{sidereal}} \times 86400 \text{ s/day} = 360.9856° \text{ per solar day}
$$

This extra 0.9856° per solar day is why the GMST advances relative to UTC.

### Practical Implications

**For satellite tracking**:
1. A geostationary satellite orbits at the same angular velocity as Earth ($\omega_{\oplus}$)
2. The ECEF frame rotates, so satellite positions in ECEF change continuously
3. To map orbital positions (ECI) to ground locations, we must account for this rotation

---

## The WGS-84 Reference Ellipsoid

### What is WGS-84?

The **World Geodetic System 1984 (WGS-84)** is the standard geodetic reference system used globally for:
- GPS satellite navigation
- Cartography and mapping
- Aviation and maritime navigation
- Satellite tracking and orbit determination

**Ellipsoid model**: WGS-84 models Earth as an **oblate ellipsoid** (sphere flattened at the poles) rather than a perfect sphere.

### Why an Ellipsoid?

**Earth's true shape**:
- Equatorial bulge due to centrifugal force from rotation
- Equatorial radius ~21 km larger than polar radius
- Gravitational and rotational equilibrium creates this shape

**Perfect sphere approximation error**:
- Up to 21 km altitude error at poles
- Unacceptable for precision navigation

### Defining Parameters

WGS-84 specifies four fundamental parameters:

#### 1. Semi-Major Axis (Equatorial Radius)

$$
a = 6378137.0 \text{ meters (exact)}
$$

This is the radius at the equator, the maximum radius of the ellipsoid.

#### 2. Flattening

$$
f = \frac{1}{298.257223563} \approx 0.003352810664747
$$

Flattening describes how much the ellipsoid is "squashed":

$$
f = \frac{a - b}{a}
$$

where $b$ is the semi-minor axis (polar radius).

#### 3. Semi-Minor Axis (Polar Radius)

Derived from $a$ and $f$:

$$
b = a(1 - f) = 6356752.314245 \text{ meters}
$$

This is the radius from Earth's center to the pole.

#### 4. Earth's Gravitational Constant

$$
\mu = GM = 3.986004418 \times 10^{14} \text{ m}^3\text{/s}^2
$$

where $G$ is the gravitational constant and $M$ is Earth's mass.

### Derived Parameters

From the defining parameters, we can compute:

**Eccentricity** (first):
$$
e^2 = 2f - f^2 = 0.00669437999014
$$

$$
e = \sqrt{e^2} \approx 0.0818191908426
$$

**Eccentricity** (second):
$$
e'^2 = \frac{e^2}{1 - e^2} = 0.00673949674228
$$

**Mean radius**:
$$
R_1 = \frac{2a + b}{3} = 6371008.771 \text{ meters}
$$

### Ellipsoid Equation

In ECEF Cartesian coordinates, points on the WGS-84 ellipsoid surface satisfy:

$$
\frac{X^2 + Y^2}{a^2} + \frac{Z^2}{b^2} = 1
$$

Equivalently, in terms of geodetic latitude $\phi$:

$$
\frac{X^2 + Y^2}{(N(\phi) + h)^2 \cos^2(\phi)} + \frac{Z^2}{(N(\phi)(1-e^2) + h)^2} = 1
$$

where $N(\phi)$ is the radius of curvature (defined below) and $h$ is height above the ellipsoid.

---

## Geodetic Coordinates

### Definition

**Geodetic coordinates** describe a position on or near Earth's surface using three values:

1. **Geodetic Latitude** ($\phi$ or $\varphi$): Angle north (positive) or south (negative) of the equator
2. **Geodetic Longitude** ($\lambda$): Angle east (positive) or west (negative) of the prime meridian
3. **Geodetic Height** ($h$): Height above the reference ellipsoid surface

**Units**:
- Latitude: $-90°$ to $+90°$ (degrees)
- Longitude: $-180°$ to $+180°$ (degrees) or $0°$ to $360°$
- Height: meters (can be negative if below ellipsoid)

### Geodetic Latitude ($\phi$)

**Definition**: The angle between the **equatorial plane** and the **surface normal** at a point on the ellipsoid.

**Key point**: The surface normal does NOT pass through Earth's center (except at equator and poles).

**Range**:
- $\phi = 0°$: Equator
- $\phi = +90°$: North Pole
- $\phi = -90°$: South Pole

### Geodetic Longitude ($\lambda$)

**Definition**: The angle between the **prime meridian** and the **meridian** (line of constant longitude) passing through the point.

**Prime Meridian**: Defined to pass through the Royal Observatory in Greenwich, London (by international convention).

**Range**:
- $\lambda = 0°$: Prime meridian (Greenwich)
- $\lambda = +90°$: 90° East longitude
- $\lambda = -90°$ or $+270°$: 90° West longitude
- $\lambda = ±180°$: International Date Line (opposite side of Earth from Greenwich)

**Sign convention**:
- Positive: East of Greenwich
- Negative: West of Greenwich

### Geodetic Height ($h$)

**Definition**: The perpendicular distance from the ellipsoid surface to the point, measured along the surface normal.

**Important notes**:
- $h$ is NOT the same as altitude above sea level
- The **geoid** (mean sea level surface) undulates ±100 m relative to the WGS-84 ellipsoid
- GPS provides geodetic height; altimeters provide height above geoid

**Range**:
- $h > 0$: Above ellipsoid (spacecraft, aircraft, mountains)
- $h = 0$: On ellipsoid surface
- $h < 0$: Below ellipsoid (ocean trenches, valleys)

---

## Geodetic vs Geocentric Latitude

### The Key Difference

There are two ways to define latitude:

1. **Geodetic Latitude** ($\phi$): Angle from equator to **surface normal**
2. **Geocentric Latitude** ($\phi'$): Angle from equator to **radial line from geocenter**

**At the equator and poles**: $\phi = \phi'$ (they coincide)

**At all other latitudes**: $\phi \neq \phi'$ due to Earth's ellipsoidal shape

### Mathematical Relationship

The relationship between geodetic and geocentric latitude is:

$$
\tan(\phi') = (1 - e^2) \tan(\phi)
$$

or equivalently:

$$
\tan(\phi') = \frac{b^2}{a^2} \tan(\phi)
$$

### Maximum Difference

The maximum difference occurs at approximately $\phi \approx ±45°$:

$$
\phi - \phi' \approx 11.5 \text{ arcminutes} \approx 0.19°
$$

At this latitude, geodetic latitude is about 11.5 arcminutes (0.19°) **larger** than geocentric latitude.

**In distance**: At 45° latitude, this corresponds to about 21 km difference in where the "latitude line" is drawn.

### Why It Matters

**For satellite tracking**:
- TLEs and orbital elements use **geocentric** coordinates implicitly (radius from center)
- GPS and maps use **geodetic** coordinates (latitude/longitude)
- **Conversion is essential** when displaying satellite positions on maps

![Geodetic vs Geocentric Latitude](https://upload.wikimedia.org/wikipedia/commons/a/a6/Geocentric_vs_geodetic_latitude.svg)
*Figure 2: Comparison of geodetic latitude (φ) and geocentric latitude (φ'). Geodetic latitude is measured from the surface normal to the ellipsoid, while geocentric latitude is measured from the radial line through Earth's center. The difference arises from Earth's ellipsoidal shape. Source: SharkD/Datumizer, [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Geocentric_vs_geodetic_latitude.svg), public domain.*

---

## Geodetic to ECEF Transformation

### The Forward Problem

**Given**: Geodetic coordinates $(\phi, \lambda, h)$

**Find**: ECEF Cartesian coordinates $(X, Y, Z)$

This transformation has a **closed-form solution**.

### Radius of Curvature

The key quantity is the **radius of curvature in the prime vertical**, denoted $N(\phi)$:

$$
N(\phi) = \frac{a}{\sqrt{1 - e^2 \sin^2(\phi)}}
$$

where:
- $a$ = semi-major axis (6,378,137 m)
- $e^2$ = first eccentricity squared (0.00669437999014)
- $\phi$ = geodetic latitude

**Physical meaning**: $N(\phi)$ is the distance from the surface to the Z-axis along the surface normal.

**Limiting values**:
- At equator ($\phi = 0°$): $N(0) = a = 6,378,137$ m
- At poles ($\phi = ±90°$): $N(90°) = \frac{a}{\sqrt{1-e^2}} = 6,399,593.6$ m

### Transformation Formulas

The ECEF coordinates are:

$$
X = (N(\phi) + h) \cos(\phi) \cos(\lambda)
$$

$$
Y = (N(\phi) + h) \cos(\phi) \sin(\lambda)
$$

$$
Z = \left(N(\phi)(1 - e^2) + h\right) \sin(\phi)
$$

**Note the $Z$ formula**: The factor $(1 - e^2)$ accounts for the ellipsoidal flattening.

### Derivation Outline

The formulas arise from:
1. The ellipsoid equation in ECEF coordinates
2. The definition of geodetic latitude (angle of surface normal)
3. Parametric representation of the ellipse

**For a point on the ellipsoid** ($h = 0$), the surface normal at latitude $\phi$ intersects the equatorial plane at distance $N(\phi)$ from the Z-axis.

### Example Calculation

**Location**: Royal Observatory, Greenwich
- $\phi = 51.4778°$ N
- $\lambda = 0.0°$
- $h = 46$ m

**Calculate $N(\phi)$**:
$$
N(51.4778°) = \frac{6378137}{\sqrt{1 - 0.00669438 \times \sin^2(51.4778°)}} \approx 6388838.3 \text{ m}
$$

**Calculate ECEF**:
$$
X = (6388838.3 + 46) \times \cos(51.4778°) \times \cos(0°) \approx 3980574 \text{ m}
$$
$$
Y = (6388838.3 + 46) \times \cos(51.4778°) \times \sin(0°) = 0 \text{ m}
$$
$$
Z = (6388838.3 \times 0.99330562 + 46) \times \sin(51.4778°) \approx 4966825 \text{ m}
$$

**Result**: $(X, Y, Z) \approx (3,980,574, 0, 4,966,825)$ meters in ECEF

---

## ECEF to Geodetic Transformation

### The Inverse Problem

**Given**: ECEF Cartesian coordinates $(X, Y, Z)$

**Find**: Geodetic coordinates $(\phi, \lambda, h)$

This transformation **does not have a simple closed-form solution** and requires iterative methods.

### Longitude (Easy)

Longitude can be computed directly:

$$
\lambda = \arctan2(Y, X)
$$

This works because longitude is simply the angle in the equatorial plane.

**Quadrant handling**: Use `atan2(Y, X)` to correctly handle all four quadrants and return values in $(-180°, +180°]$.

### Latitude and Height (Iterative)

Computing $\phi$ and $h$ requires iteration because they are coupled through the ellipsoid equations.

### Bowring's Method (1976)

One of the most efficient iterative methods:

**Step 1**: Calculate auxiliary values
$$
p = \sqrt{X^2 + Y^2}
$$

$$
\theta = \arctan\left(\frac{Z \cdot a}{p \cdot b}\right)
$$

where $a$ and $b$ are WGS-84 semi-major and semi-minor axes.

**Step 2**: Initial latitude estimate
$$
\phi = \arctan\left(\frac{Z + e'^2 b \sin^3(\theta)}{p - e^2 a \cos^3(\theta)}\right)
$$

where $e^2$ and $e'^2$ are first and second eccentricity squared.

**Step 3**: Calculate $N(\phi)$ using the formula from the forward transformation

**Step 4**: Calculate height
$$
h = \frac{p}{\cos(\phi)} - N(\phi)
$$

**Convergence**: This method typically converges in **one iteration** for most cases, with accuracy better than 1 mm.

### Alternative: Fixed-Point Iteration

A simpler but slower method iterates until convergence:

**Initialize**: $\phi_0 = \arctan\left(\frac{Z}{p \cdot (1 - e^2)}\right)$

**Iterate**:
1. Calculate $N(\phi_n) = \frac{a}{\sqrt{1 - e^2 \sin^2(\phi_n)}}$
2. Calculate $h_n = \frac{p}{\cos(\phi_n)} - N(\phi_n)$
3. Update $\phi_{n+1} = \arctan\left(\frac{Z}{p \cdot \left(1 - \frac{e^2 N(\phi_n)}{N(\phi_n) + h_n}\right)}\right)$
4. Repeat until $|\phi_{n+1} - \phi_n| < \epsilon$ (e.g., $\epsilon = 10^{-12}$ radians)

**Convergence**: Typically 2-3 iterations for 1 mm accuracy.

### Edge Cases

**At the poles** ($p \approx 0$):
- Longitude is undefined
- Latitude is $\phi = \text{sign}(Z) \times 90°$
- Height is $h = |Z| - b$

**At the geocenter** ($X = Y = Z = 0$):
- All coordinates are undefined (singularity)
- Should never occur for satellite positions

---

## Applications in Satellite Tracking

### Position Display

The most common use of geodetic coordinates is **displaying satellite positions** on maps:

**Orbital calculation pipeline**:
1. TLE → Orbital elements (in ECI frame)
2. Propagate orbit → Position in ECI at time $t$
3. Transform ECI → ECEF (rotate by GMST)
4. Transform ECEF → Geodetic (iterative conversion)
5. **Display** $(latitude, longitude, altitude)$ on map

**Example**: "ISS is at 23.5°N, 74.3°W, 420 km altitude"

### Ground Track Visualization

**Ground track**: The path traced by a satellite's sub-satellite point (the point on Earth directly beneath the satellite).

**Calculation**:
```
For each time step t:
  1. Calculate r_ECI(t)
  2. Transform r_ECI(t) → r_ECEF(t)
  3. Convert r_ECEF(t) → (φ(t), λ(t), h(t))
  4. Plot (φ(t), λ(t)) on map
```

**Result**: A curve on Earth's surface showing where the satellite passes overhead.

### Observer Distance Calculations

To compute the distance from an observer to a satellite:

**Observer location** (geodetic): $(\phi_{obs}, \lambda_{obs}, h_{obs})$

**Satellite position** (geodetic): $(\phi_{sat}, \lambda_{sat}, h_{sat})$

**Method**:
1. Convert both to ECEF: $\mathbf{r}_{obs}$, $\mathbf{r}_{sat}$
2. Calculate range: $\rho = ||\mathbf{r}_{sat} - \mathbf{r}_{obs}||$

**Why ECEF?** Straight-line distance in 3D Cartesian space is simple. In geodetic coordinates, distance calculations are complex (great circle, ellipsoidal geodesics).

### Satellite Coverage

**Visibility**: A satellite is visible from an observer if the elevation angle > 0°

**Coverage area**: The region of Earth's surface from which a satellite is visible

**Calculation** (approximate for altitude $h_{sat}$):

Maximum viewing angle:
$$
\alpha_{max} = \arccos\left(\frac{R_E}{R_E + h_{sat}}\right)
$$

Coverage radius (great circle):
$$
d = R_E \cdot \alpha_{max}
$$

where $R_E \approx 6371$ km is Earth's mean radius.

---

## Ephemeris Implementation

### How Ephemeris Uses ECEF and Geodetic Coordinates

The Ephemeris framework implements the complete transformation chain:

**TLE → Geodetic Position**:
```swift
import Ephemeris

let tle = try TwoLineElement(from: tleString)
let orbit = Orbit(from: tle)

// Calculate position at time t
// Internally performs:
//   1. Orbital mechanics in ECI
//   2. ECI → ECEF transformation
//   3. ECEF → Geodetic conversion
let position = try orbit.calculatePosition(at: Date())

print("Lat: \(position.latitude)°")
print("Lon: \(position.longitude)°")
print("Alt: \(position.altitude) km")
```

**Behind the scenes** (`Orbit.swift`):
1. Propagate mean anomaly
2. Solve Kepler's equation for eccentric anomaly
3. Calculate position in orbital plane
4. Rotate to ECI using $(i, \Omega, \omega)$
5. **Transform to ECEF** using GMST rotation
6. **Convert to Geodetic** using iterative algorithm

### WGS-84 Constants in PhysicalConstants

Ephemeris defines WGS-84 parameters in `PhysicalConstants.swift`:

```swift
public struct Earth {
    public static let radius: Double = 6378.137  // km (equatorial)
    public static let µ: Double = 398600.4418    // km³/s²
    // ... other constants
}
```

### Coordinate Transform Utility

The `CoordinateTransforms` utility provides functions for manual transformations:

```swift
// Conceptual - actual implementation details in CoordinateTransforms.swift
public struct CoordinateTransforms {
    static func geodeticToECEF(
        latitudeDeg: Double,
        longitudeDeg: Double,
        altitudeMeters: Double
    ) -> (x: Double, y: Double, z: Double) {
        // Implementation with N(φ) calculation
        // Returns ECEF coordinates in meters
    }

    static func ECEFtoGeodetic(
        x: Double, y: Double, z: Double
    ) -> (latitudeDeg: Double, longitudeDeg: Double, altitudeMeters: Double) {
        // Iterative Bowring method
        // Returns geodetic coordinates
    }
}
```

**Note**: For full Swift examples, see [Observer Geometry](observer-geometry.md).

---

## See Also

**Learning Path**:
- **Previous**: [Inertial Frames](inertial-frames.md) - ECI coordinate system
- **Next**: [Observer Frames](observer-frames.md) - ENU and topocentric coordinates

**Related Concepts**:
- [Time Systems](time-systems.md) - GMST for ECI ↔ ECEF transformation
- [Coordinate Transformations](coordinate-transformations.md) - Full mathematical derivations

**Practical Guides**:
- [Observer Geometry](observer-geometry.md) - Swift implementation examples
- [Visualization](visualization.md) - Ground track plotting
- [Getting Started](getting-started.md) - Build satellite tracker app

---

## References

1. **National Geospatial-Intelligence Agency (NGA).** (2014). *World Geodetic System 1984: Its Definition and Relationships with Local Geodetic Systems*. NGA.STND.0036_1.0.0_WGS84, Version 1.0.0.
   - Official WGS-84 specification
   - Defining parameters and derived constants
   - Available: https://earth-info.nga.mil/GandG/wgs84/

2. **Vallado, David A.** (2013). *Fundamentals of Astrodynamics and Applications* (4th Edition). Microcosm Press.
   - Section 3.5: Coordinate Transformations
   - ECEF coordinate system definition
   - Geodetic conversion algorithms

3. **Montenbruck, Oliver, and Gill, Eberhard.** (2000). *Satellite Orbits: Models, Methods and Applications*. Springer.
   - Section 5.4: Topocentric Coordinates
   - Geodetic reference systems

4. **Bowring, B.R.** (1976). "Transformation from spatial to geographical coordinates." *Survey Review*, 23(181), 323-327.
   - Original Bowring method for ECEF → Geodetic
   - Efficient iterative algorithm

5. **Heiskanen, W.A., and Moritz, H.** (1967). *Physical Geodesy*. W.H. Freeman and Company.
   - Classical reference for geodetic theory
   - Ellipsoid mathematics

6. **Torge, Wolfgang.** (2001). *Geodesy* (3rd Edition). Walter de Gruyter.
   - Modern geodetic reference systems
   - Coordinate transformations

7. **Clynch, James R.** (2006). "Geodetic Coordinate Conversions." Naval Postgraduate School.
   - Practical algorithms for coordinate conversion
   - Available: https://www.oc.nps.edu/oc2902w/coord/coordcvt.pdf

8. **Zhu, J.** (1994). "Conversion of Earth-centered Earth-fixed coordinates to geodetic coordinates." *IEEE Transactions on Aerospace and Electronic Systems*, 30(3), 957-961.
   - Alternative closed-form methods
   - Accuracy comparisons

### Image Sources

**Diagram 1**: Earth-Centered Earth-Fixed (ECEF) Coordinate System
- **To be added**: Diagram showing ECEF axes relative to Earth
- **Source**: ResearchGate academic paper
- **License**: Used under fair use for educational purposes

**Diagram 2**: Geodetic vs Geocentric Latitude
- **To be added**: Visualization showing the difference between geodetic and geocentric latitude
- **Source**: ResearchGate academic paper
- **License**: Used under fair use for educational purposes

---

*This documentation is part of the [Ephemeris](https://github.com/mvdmakesthings/Ephemeris) framework for satellite tracking in Swift.*

**Last Updated**: October 20, 2025
**Version**: 1.0
