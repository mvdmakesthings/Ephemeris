# Ground-Track and Sky-Track Visualization

This document describes the mathematical foundations and practical applications of ground-track and sky-track plotting for satellite motion visualization in the Ephemeris framework.

## Overview

Ephemeris provides two primary visualization methods for satellite motion:

1. **Ground Track**: The path traced by the satellite's sub-satellite point (SSP) on Earth's surface
2. **Sky Track**: The path traced by the satellite across an observer's local sky

Both methods are essential for mission planning, educational demonstrations, and validating orbital propagation accuracy.

---

## Ground-Track Plotting

### Mathematical Foundation

The ground track represents the projection of a satellite's position onto Earth's surface. For a satellite at position $\mathbf{r}_{\text{ECI}}$ in the Earth-Centered Inertial (ECI) frame, we compute its geodetic coordinates (latitude $\phi$, longitude $\lambda$, altitude $h$).

#### Coordinate Transformation

The transformation from ECI to Earth-Centered Earth-Fixed (ECEF) coordinates accounts for Earth's rotation:

$$
\mathbf{r}_{\text{ECEF}} = R_z(-\theta_{\text{GMST}}) \cdot \mathbf{r}_{\text{ECI}}
$$

where $\theta_{\text{GMST}}$ is the Greenwich Mean Sidereal Time and $R_z$ is the rotation matrix about the z-axis:

$$
R_z(\theta) = \begin{bmatrix}
\cos\theta & \sin\theta & 0 \\
-\sin\theta & \cos\theta & 0 \\
0 & 0 & 1
\end{bmatrix}
$$

#### Geodetic Coordinates

From ECEF coordinates $(x, y, z)$, we compute:

**Longitude:**
$$
\lambda = \arctan2(y, x)
$$

**Latitude:**
$$
\phi = 90° - \arccos\left(\frac{z}{\|\mathbf{r}_{\text{ECEF}}\|}\right)
$$

**Altitude:**
$$
h = \|\mathbf{r}_{\text{ECEF}}\| - R_{\oplus}
$$

where $R_{\oplus}$ is Earth's mean radius (6378.137 km for WGS-84).

### Implementation

The `groundTrack()` method generates a time series of geodetic positions:

```swift
let groundTrack = try orbit.groundTrack(
    from: startDate,
    to: endDate,
    stepSeconds: 60
)

for point in groundTrack {
    print("\(point.time): \(point.latitudeDeg)°, \(point.longitudeDeg)°")
}
```

### Orbital Characteristics in Ground Tracks

#### Inclination Effects

The **orbital inclination** $i$ constrains the latitude range of the ground track:

$$
-i \leq \phi \leq i
$$

- **Equatorial orbits** ($i \approx 0°$): Ground track follows the equator
- **Polar orbits** ($i \approx 90°$): Ground track covers all latitudes
- **Sun-synchronous orbits** ($i \approx 98°$): Retrograde, covering high latitudes

#### Earth's Rotation

Due to Earth's rotation ($\omega_{\oplus} \approx 7.2921 \times 10^{-5}$ rad/s), successive orbital passes shift westward:

$$
\Delta\lambda = -\frac{2\pi}{n} \cdot \omega_{\oplus}
$$

where $n$ is the satellite's mean motion in rad/s.

#### Geostationary Orbits

For geostationary satellites ($n = \omega_{\oplus}$), the ground track becomes a single point (ideally) or a small figure-eight pattern due to orbital eccentricity and inclination.

### Visualization Applications

1. **Coverage Analysis**: Determine which ground stations can communicate with the satellite
2. **Mission Planning**: Plan observation windows for Earth observation satellites
3. **Educational Demonstrations**: Illustrate Kepler's laws and orbital mechanics
4. **Collision Avoidance**: Visualize proximity to ground-based hazards

---

## Sky-Track Plotting

### Mathematical Foundation

The sky track represents a satellite's apparent motion across an observer's local sky, described in the horizontal coordinate system (azimuth-elevation).

#### Observer Reference Frame

For an observer at geodetic position $(\phi_{\text{obs}}, \lambda_{\text{obs}}, h_{\text{obs}})$, we define the **East-North-Up (ENU)** local tangent plane:

$$
\mathbf{r}_{\text{ENU}} = R_{\text{ECEF→ENU}} \cdot (\mathbf{r}_{\text{sat,ECEF}} - \mathbf{r}_{\text{obs,ECEF}})
$$

where the rotation matrix is:

$$
R_{\text{ECEF→ENU}} = \begin{bmatrix}
-\sin\lambda & \cos\lambda & 0 \\
-\sin\phi\cos\lambda & -\sin\phi\sin\lambda & \cos\phi \\
\cos\phi\cos\lambda & \cos\phi\sin\lambda & \sin\phi
\end{bmatrix}
$$

#### Horizontal Coordinates

From ENU coordinates $(e, n, u)$:

**Azimuth** (clockwise from north):
$$
A = \arctan2(e, n)
$$

**Elevation** (angle above horizon):
$$
E = \arctan2\left(u, \sqrt{e^2 + n^2}\right)
$$

**Range** (slant distance):
$$
\rho = \sqrt{e^2 + n^2 + u^2}
$$

### Implementation

The `skyTrack()` method generates a time series of azimuth-elevation pairs:

```swift
let skyTrack = try orbit.skyTrack(
    for: observer,
    from: startDate,
    to: endDate,
    stepSeconds: 10
)

for point in skyTrack where point.elevationDeg > 0 {
    print("\(point.time): Az \(point.azimuthDeg)°, El \(point.elevationDeg)°")
}
```

### Pass Characteristics

#### Horizon Crossing

A satellite is **visible** when $E > 0°$. Typical minimum elevations for tracking:
- **Amateur radio**: 0° (horizon)
- **Optical observations**: 10-15° (atmospheric effects)
- **High-precision tracking**: 20-30° (multipath reduction)

#### Pass Duration

For a circular orbit at altitude $h$ and observer latitude $\phi$, the approximate maximum pass duration is:

$$
t_{\text{max}} \approx \frac{2}{n} \arccos\left(\frac{R_{\oplus}}{R_{\oplus} + h}\right)
$$

where $n$ is the mean motion.

#### Maximum Elevation

The maximum elevation $E_{\text{max}}$ depends on the satellite's closest approach distance. For overhead passes ($E_{\text{max}} = 90°$), the satellite passes directly through the observer's zenith.

### Atmospheric Refraction

Near the horizon, atmospheric refraction bends light rays, increasing the apparent elevation. The Bennett formula provides a correction:

$$
\Delta E = \cot\left(E + \frac{7.31}{E + 4.4}\right) \text{ arcmin}
$$

This correction is applied when `applyRefraction: true` is specified in topocentric calculations.

### Visualization Applications

1. **Antenna Pointing**: Generate azimuth-elevation commands for tracking antennas
2. **Pass Prediction**: Identify optimal observation windows
3. **Photography Planning**: Determine when and where to photograph satellites
4. **Amateur Radio**: Plan communication windows with satellites

---

## Data Formats

### GroundTrackPoint

```swift
public struct GroundTrackPoint {
    let time: Date              // UTC timestamp
    let latitudeDeg: Double     // Geodetic latitude (-90 to 90°)
    let longitudeDeg: Double    // Geodetic longitude (-180 to 180°)
}
```

### SkyTrackPoint

```swift
public struct SkyTrackPoint {
    let time: Date              // UTC timestamp
    let azimuthDeg: Double      // Azimuth (0-360°, clockwise from north)
    let elevationDeg: Double    // Elevation (-90 to 90°, negative = below horizon)
}
```

---

## Export and Integration

### SwiftUI Charts

Ground track and sky track data can be directly plotted using SwiftUI Charts:

```swift
import Charts

Chart {
    ForEach(groundTrack, id: \.time) { point in
        PointMark(
            x: .value("Longitude", point.longitudeDeg),
            y: .value("Latitude", point.latitudeDeg)
        )
    }
}
```

### GeoJSON Export

For integration with mapping tools (Leaflet, Mapbox), export ground tracks as GeoJSON:

```swift
func exportGeoJSON(_ groundTrack: [Orbit.GroundTrackPoint]) -> String {
    let coordinates = groundTrack.map { "[\($0.longitudeDeg), \($0.latitudeDeg)]" }
    return """
    {
      "type": "Feature",
      "geometry": {
        "type": "LineString",
        "coordinates": [\(coordinates.joined(separator: ", "))]
      }
    }
    """
}
```

### Polar Plots (Sky Track)

For visualizing satellite passes, use polar coordinates:

```swift
// Convert azimuth-elevation to polar coordinates
let r = 90 - skyPoint.elevationDeg  // Distance from center
let theta = skyPoint.azimuthDeg     // Angle from north
```

---

## Example: ISS Ground Track

```swift
// ISS TLE
let tleString = """
ISS (ZARYA)
1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
"""

let tle = try TwoLineElement(from: tleString)
let orbit = Orbit(from: tle)

// Generate 24-hour ground track
let now = Date()
let tomorrow = now.addingTimeInterval(86400)
let groundTrack = try orbit.groundTrack(
    from: now,
    to: tomorrow,
    stepSeconds: 60
)

print("Generated \(groundTrack.count) ground track points")
// Expected: ~1440 points (24 hours * 60 minutes)
```

## Example: ISS Pass Observation

```swift
// Observer in Louisville, Kentucky
let observer = Observer(
    latitudeDeg: 38.2542,
    longitudeDeg: -85.7594,
    altitudeMeters: 140
)

// Generate sky track for next pass
let passStart = Date()  // Determine from predictPasses()
let passEnd = passStart.addingTimeInterval(600)  // 10-minute pass

let skyTrack = try orbit.skyTrack(
    for: observer,
    from: passStart,
    to: passEnd,
    stepSeconds: 5  // High resolution for smooth plotting
)

// Find maximum elevation
let maxPoint = skyTrack.max { $0.elevationDeg < $1.elevationDeg }
print("Maximum elevation: \(maxPoint?.elevationDeg ?? 0)° at \(maxPoint?.time ?? Date())")
```

---

## Performance Considerations

### Time Step Selection

The time step (`stepSeconds`) parameter affects both accuracy and performance:

| Application | Recommended Step | Rationale |
|-------------|-----------------|-----------|
| Ground track overview | 60-120 seconds | Smooth curves, low memory |
| Detailed ground track | 30-60 seconds | High accuracy |
| Sky track visualization | 5-30 seconds | Smooth pass curves |
| Antenna control | 1-10 seconds | Real-time pointing |

### Computational Complexity

Each point requires:
1. **Orbital propagation**: $O(n_{\text{iter}})$ for solving Kepler's equation
2. **Coordinate transformations**: $O(1)$ matrix operations
3. **Time complexity**: $O(n_{\text{points}})$ where $n_{\text{points}} = \frac{t_{\text{end}} - t_{\text{start}}}{\Delta t}$

For a 24-hour ground track with 60-second steps:
- Points generated: 1440
- Typical computation time: < 100 ms (modern hardware)

---

## References

1. **Vallado, D. A.** (2013). *Fundamentals of Astrodynamics and Applications* (4th ed.). Microcosm Press.
   - Chapter 3: Coordinate Systems
   - Chapter 4: Orbit Determination

2. **Montenbruck, O., & Gill, E.** (2000). *Satellite Orbits: Models, Methods and Applications*. Springer.
   - Section 5.4: Topocentric Coordinates

3. **Bennett, G. G.** (1982). "The Calculation of Astronomical Refraction in Marine Navigation." *Journal of Navigation*, 35(2), 255-259.

4. **WGS-84 Ellipsoid Parameters**: National Geospatial-Intelligence Agency (NGA)
   - Semi-major axis: 6378.137 km
   - Flattening: 1/298.257223563

5. **IERS Conventions** (2010). International Earth Rotation and Reference Systems Service.
   - Earth rotation parameters
   - Coordinate system transformations

---

## See Also

- [Introduction to Orbital Elements](Introduction-to-Orbital-Elements.md)
- [Observer Geometry](observer_geometry.md)
- [API Reference](API-Reference.md)

---

*Last Updated: October 20, 2025*
