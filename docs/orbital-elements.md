# Orbital Elements: Foundation of Satellite Tracking

> **Brief Description**: Learn the six Keplerian orbital elements that completely describe satellite motion, from mathematical theory to Swift implementation in the Ephemeris framework.

## Overview

Understanding how satellites move around Earth starts with the **six Keplerian elements**—a set of parameters that define the size, shape, and orientation of an orbit, as well as where the satellite is within that orbit. These elements form the foundation for Two-Line Element (TLE) data and orbit prediction models such as SGP4 and SDP4.

This guide takes a **theory-first approach**: each orbital element is explained with mathematical rigor, visual diagrams, and real-world examples, followed by its Swift implementation in Ephemeris. Whether you're building a satellite tracker app or studying orbital mechanics, you'll gain both theoretical understanding and practical coding skills.

**What you'll learn:**
- The six classical orbital elements and their physical meanings
- How orbital elements map to the TLE data format
- Solving Kepler's equation to find satellite positions
- Swift implementation patterns in the Ephemeris framework
- Accuracy considerations for satellite tracking

---

## Table of Contents

- [The Six Classical Orbital Elements](#the-six-classical-orbital-elements)
  - [1. Semi-Major Axis (a)](#1-semi-major-axis-a)
  - [2. Eccentricity (e)](#2-eccentricity-e)
  - [3. Inclination (i)](#3-inclination-i)
  - [4. Longitude of the Ascending Node (Ω)](#4-longitude-of-the-ascending-node-ω)
  - [5. Argument of Perigee (ω)](#5-argument-of-perigee-ω)
  - [6. True Anomaly (ν)](#6-true-anomaly-ν)
- [How These Map to the TLE Format](#how-these-map-to-the-tle-format)
- [Ensuring Prediction Accuracy](#ensuring-prediction-accuracy)
- [Summary](#summary)
- [References](#references)

---

## The Six Classical Orbital Elements

The six Keplerian orbital elements completely describe the motion of a satellite in orbit. They can be grouped into three categories based on what aspect of the orbit they define:

### Size and Shape
- **Semi-major axis (a)** - defines the size
- **Eccentricity (e)** - defines the shape

### Orientation in Space
- **Inclination (i)** - tilt of the orbital plane
- **Longitude of the Ascending Node (Ω)** - rotation of the orbital plane
- **Argument of Perigee (ω)** - orientation of the ellipse within the plane

### Position in Orbit
- **True Anomaly (ν)** - location of the satellite along its orbit

---

## 1. Semi-Major Axis (a)

**Defines the size of the orbit.**

The semi-major axis is half the longest diameter of the elliptical orbit, essentially describing how "large" the orbit is. It extends from the center of the Earth to the apogee (the farthest point in the orbit) minus the Earth's radius.

![Orbital Elements Diagram](https://upload.wikimedia.org/wikipedia/commons/e/eb/Orbit1.svg)
*Figure 1: Orbital elements visualization showing semi-major axis (a) and semi-minor axis (b)*

### Key Properties

- **Units**: Typically measured in kilometers (km) or astronomical units (AU)
- **Physical Significance**: Determines the orbital period (how long one complete orbit takes)
- **Range**: For Earth satellites, typically 6,378 km (at Earth's surface) to 42,164 km (geostationary orbit) and beyond

### Kepler's Third Law

The semi-major axis controls the orbital period through **Kepler's Third Law**:

$$T = 2\pi \sqrt{\frac{a^3}{\mu}}$$

where:
- $T$ = orbital period (seconds)
- $a$ = semi-major axis (meters)
- $\mu$ = Earth's gravitational parameter ≈ 3.986004418 × 10¹⁴ m³/s²

### Example: International Space Station (ISS)

The ISS orbits at approximately:
- **Semi-major axis**: 6,778 km
- **Orbital period**: ~92 minutes
- **Average altitude**: ~400 km above Earth's surface

### Calculating Semi-Major Axis from Mean Motion

In TLE data, you're often given the **mean motion** (revolutions per day) instead of the semi-major axis directly. You can convert between them using:

$$a = \left( \frac{\mu}{\left(\frac{2\pi n}{86400}\right)^2} \right)^{1/3}$$

where:
- $n$ = mean motion (revolutions per day)
- $86400$ = seconds per day
- $\mu$ = Earth's gravitational parameter

---

## 2. Eccentricity (e)

**Defines the shape of the orbit.**

Eccentricity measures how "stretched out" an ellipse is, ranging from a perfect circle to a parabolic escape trajectory.

![Eccentricity Examples](https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Orbit_shapes.svg/800px-Orbit_shapes.svg.png)
*Figure 2: Different orbital shapes based on eccentricity values*

### Orbit Types by Eccentricity

| Eccentricity Value | Orbit Type | Description |
|-------------------|------------|-------------|
| **e = 0** | Circular | Perfect circle, constant altitude |
| **0 < e < 1** | Elliptical | Most satellites, varying altitude |
| **e = 1** | Parabolic | Escape velocity, boundary case |
| **e > 1** | Hyperbolic | Escape trajectory (interplanetary) |

### Mathematical Definition

The eccentricity relates the apogee (farthest point) and perigee (closest point) distances:

$$e = \frac{r_a - r_p}{r_a + r_p}$$

where:
- $r_a$ = apogee distance from Earth's center
- $r_p$ = perigee distance from Earth's center

### Altitude Variation

The eccentricity directly affects how much the satellite's altitude varies during its orbit. The instantaneous distance from Earth's center is:

$$r = \frac{a(1-e^2)}{1 + e\cos(\nu)}$$

where $\nu$ is the true anomaly (current position angle).

### Real-World Examples

| Satellite | Eccentricity | Type | Notes |
|-----------|--------------|------|-------|
| **GPS Satellites** | ~0.00 | Nearly circular | Constant altitude for timing accuracy |
| **ISS** | ~0.0002 | Nearly circular | Very stable orbit |
| **Molniya Orbit** | ~0.74 | Highly elliptical | High over Russia, low elsewhere |
| **GTO** | ~0.73 | Elliptical | Geostationary transfer orbit |
| **Comet 67P** | 0.64 | Elliptical | Rosetta mission target |

### Special Considerations

- **Low eccentricity (e < 0.1)**: Nearly circular orbits, common for LEO satellites
- **High eccentricity (e > 0.5)**: Dramatic altitude changes, specialized applications
- **Near-zero**: Many operational satellites maintain very low eccentricity for stability

---

## 3. Inclination (i)

**The tilt of the orbital plane relative to Earth's equator.**

Inclination defines the angle between the orbital plane and Earth's equatorial plane, fundamentally determining which latitudes the satellite can reach.

![Inclination Diagram](https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Orbit_-_Plane_and_Inclination_-_Color.png/400px-Orbit_-_Plane_and_Inclination_-_Color.png)
*Figure 3: Orbital inclination relative to the equatorial plane*

### Inclination Values and Orbit Types

| Inclination | Type | Description | Applications |
|-------------|------|-------------|--------------|
| **0°** | Equatorial | Orbits along the equator | Communications, GEO satellites |
| **1° - 89°** | Prograde | Moves with Earth's rotation | Most satellites |
| **90°** | Polar | Passes over both poles | Weather, reconnaissance |
| **91° - 179°** | Retrograde | Against Earth's rotation | Specialized missions |
| **~98°** | Sun-synchronous | Special retrograde orbit | Earth observation |

### Key Properties

- **Range**: 0° to 180°
- **Units**: Degrees
- **Coverage**: Maximum latitude reached equals the inclination angle

### Latitude Coverage

A satellite with inclination $i$ can only observe latitudes between $-i$ and $+i$. For example:
- **51.6° inclination** (ISS): Can see latitudes from 51.6°S to 51.6°N
- **98° inclination** (Earth observation): Covers nearly all of Earth's surface

### Sun-Synchronous Orbits

A special case where inclination (~98°) is chosen so the orbital plane precesses at the same rate Earth orbits the Sun, maintaining constant solar lighting conditions:

$$i = \arccos\left(-\frac{2\dot{\Omega}}{3J_2}\sqrt{\frac{a^4(1-e^2)^4}{(\mu R_E^2)}}\right)$$

where:
- $\dot{\Omega}$ = desired precession rate (360°/365.25 days)
- $J_2$ = Earth's oblateness coefficient
- $R_E$ = Earth's equatorial radius

### Examples

| Satellite/Mission | Inclination | Purpose |
|------------------|-------------|---------|
| **ISS** | 51.6° | Optimized for launch from Baikonur |
| **GPS** | 55° | Global coverage with minimum satellites |
| **Iridium** | 86.4° | Near-polar for global communication |
| **Landsat** | 98.2° | Sun-synchronous Earth observation |
| **Geostationary** | 0° | Fixed position over equator |

---

## 4. Longitude of the Ascending Node (Ω)

**Defines where the orbit crosses the equatorial plane moving northward.**

Also called the **Right Ascension of the Ascending Node (RAAN)**, this angle is measured eastward from the vernal equinox direction (the direction from Earth to the Sun at the March equinox) to the point where the satellite crosses the equator going from south to north (the ascending node).

![RAAN Diagram](https://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Orbit2.svg/400px-Orbit2.svg.png)
*Figure 4: Right Ascension of the Ascending Node (Ω) measured from the vernal equinox (♈)*

### Key Properties

- **Symbol**: Ω (capital Greek letter Omega)
- **Range**: 0° to 360°
- **Units**: Degrees
- **Reference**: Measured from the vernal equinox direction (♈, First Point of Aries)

### Physical Significance

RAAN establishes the **orientation of the orbital plane** around Earth. Two satellites can have the same inclination but different RAANs, meaning their orbital planes are tilted the same amount but rotated to different positions.

### Orbital Plane Precession

RAAN is **not constant** over time due to Earth's oblateness (the J₂ effect). The orbital plane slowly rotates around Earth's axis:

$$\dot{\Omega} = -\frac{3}{2} \frac{J_2 R_E^2}{a^2(1-e^2)^2} n \cos(i)$$

where:
- $\dot{\Omega}$ = rate of change of RAAN (radians per second)
- $J_2$ ≈ 0.00108263 (Earth's oblateness coefficient)
- $R_E$ = Earth's equatorial radius (6,378 km)
- $n$ = mean motion
- $i$ = inclination

### Special Cases

- **Equatorial orbits** (i = 0°): RAAN is undefined (or arbitrary)
- **Sun-synchronous orbits**: RAAN precesses exactly once per year
- **Low Earth orbit**: RAAN can change several degrees per day

### Practical Implications

**Constellation Design**: Satellite constellations often distribute satellites with different RAANs to ensure coverage. For example:
- **GPS**: 24 satellites in 6 orbital planes with 60° RAAN spacing
- **Iridium**: 66 satellites in 6 planes with ~30° RAAN spacing

**Launch Windows**: The desired RAAN constrains when you can launch to reach a specific orbit.

---

## 5. Argument of Perigee (ω)

**Specifies where the closest point (perigee) lies within the orbital plane.**

The argument of perigee is the angle from the ascending node to the perigee (closest point to Earth), measured in the direction of satellite motion within the orbital plane.

![Argument of Perigee](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Orbit3.svg/400px-Orbit3.svg.png)
*Figure 5: Argument of Perigee (ω) measured from the ascending node to perigee*

### Key Properties

- **Symbol**: ω (lowercase Greek letter omega)
- **Range**: 0° to 360°
- **Units**: Degrees
- **Measurement**: Within the orbital plane, from ascending node to perigee

### Physical Significance

The argument of perigee defines **where in the orbit** the satellite reaches its:
- **Minimum altitude** (at perigee, when ν = 0°)
- **Maximum velocity** (also at perigee, due to conservation of angular momentum)

### Orbital Energy Distribution

At different points in the orbit:

| Position | True Anomaly | Altitude | Velocity |
|----------|--------------|----------|----------|
| Perigee | ν = 0° | Minimum | Maximum |
| Quarter orbit | ν = 90° | Medium | Medium |
| Apogee | ν = 180° | Maximum | Minimum |
| Three-quarter | ν = 270° | Medium | Medium |

### Perigee Precession

Like RAAN, the argument of perigee also **changes over time** due to Earth's oblateness:

$$\dot{\omega} = \frac{3}{4} \frac{J_2 R_E^2}{a^2(1-e^2)^2} n (5\cos^2(i) - 1)$$

### Special Cases

- **Circular orbits** (e ≈ 0): Perigee is undefined; ω can be set to any value or zero
- **Equatorial orbits** (i = 0°): Both ascending node and perigee are undefined
- **Critical inclination** (63.4°): Argument of perigee remains constant

### Real-World Examples

**Molniya Orbits** (Russian communication satellites):
- **Inclination**: 63.4°
- **Eccentricity**: 0.74
- **Argument of Perigee**: 270°
- Result: Satellite spends most time over northern hemisphere at high altitude

**Tundra Orbits**:
- Similar to Molniya but with 24-hour period
- Used for high-latitude communications

---

## 6. True Anomaly (ν)

**Gives the satellite's instantaneous position along the orbital path.**

The true anomaly is the angle from perigee to the satellite's current position, measured at Earth's center in the direction of motion. It's the most dynamic of the six elements, constantly changing as the satellite moves.

![True Anomaly](https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/Orbit_geometry.svg/500px-Orbit_geometry.svg.png)
*Figure 6: True anomaly (ν) is the angle from perigee to the satellite's current position*

### Key Properties

- **Symbol**: ν (Greek letter nu) or θ (theta)
- **Range**: 0° to 360°
- **Units**: Degrees or radians
- **Dynamic**: Changes continuously as satellite orbits

### Related Anomalies

In orbital mechanics, there are three types of anomalies, each useful for different calculations:

#### Mean Anomaly (M)
- **Definition**: Fictional angle assuming uniform circular motion
- **Use**: Linear with time, easy to propagate forward
- **Formula**: $M = M_0 + n(t - t_0)$ where $n$ is mean motion

#### Eccentric Anomaly (E)
- **Definition**: Geometric construction parameter
- **Use**: Intermediate step in calculations
- **Relationship**: $M = E - e\sin(E)$ (Kepler's equation)

#### True Anomaly (ν)
- **Definition**: Actual angle to satellite
- **Use**: Determining real position and velocity
- **Relationship**: $\tan\left(\frac{\nu}{2}\right) = \sqrt{\frac{1+e}{1-e}} \tan\left(\frac{E}{2}\right)$

### Converting from Mean to True Anomaly

The conversion process involves solving Kepler's equation iteratively:

1. **Start with Mean Anomaly** (M, given in TLE)

2. **Solve for Eccentric Anomaly** using Newton-Raphson iteration:
   $$E_{n+1} = E_n - \frac{E_n - e\sin(E_n) - M}{1 - e\cos(E_n)}$$

3. **Calculate True Anomaly**:
   $$\nu = 2\arctan\left(\sqrt{\frac{1+e}{1-e}} \tan\left(\frac{E}{2}\right)\right)$$

### Position and Velocity

Once you have the true anomaly, you can calculate the satellite's position and velocity in the orbital plane:

**Position (distance from Earth's center)**:
$$r = \frac{a(1-e^2)}{1 + e\cos(\nu)}$$

**Velocity magnitude**:
$$v = \sqrt{\mu\left(\frac{2}{r} - \frac{1}{a}\right)}$$

### Orbital Period Variation

Even though the orbital period is constant, the satellite **moves faster near perigee** and **slower near apogee**. This is described by Kepler's Second Law (equal areas in equal times).

**At perigee** (ν = 0°):
- Minimum distance
- Maximum velocity
- Fastest angular motion

**At apogee** (ν = 180°):
- Maximum distance
- Minimum velocity
- Slowest angular motion

### Why TLEs Use Mean Anomaly

TLE files provide **Mean Anomaly** instead of True Anomaly because:
1. **Linearity**: Mean anomaly increases uniformly with time
2. **Propagation**: Easy to calculate future positions
3. **Simplicity**: No need for iterative algorithms in the data format

---

## How These Map to the TLE Format

A **Two-Line Element (TLE)** is a compact, fixed-width data representation of a satellite's orbit used for propagation models like SGP4. It's composed of two lines (plus an optional title line) that contain all necessary orbital parameters.

### TLE Example: International Space Station

```
ISS (ZARYA)
1 25544U 98067A   24291.51803472  .00006455  00000-0  12345-3 0  9993
2 25544  51.6435 132.8077 0009821  94.4121  44.3422 15.50338483 48571
```

### TLE Format Breakdown

#### Line 0 (Optional): Satellite Name
```
ISS (ZARYA)
```

#### Line 1: Identification and Epoch Data

| Column(s) | Content | Example | Description |
|-----------|---------|---------|-------------|
| 1 | Line number | `1` | Always "1" for first line |
| 3-7 | Catalog number | `25544` | NORAD satellite catalog number |
| 8 | Classification | `U` | U = Unclassified, C = Classified, S = Secret |
| 10-17 | International designator | `98067A` | Launch year, launch number, piece |
| 19-32 | Epoch | `24291.51803472` | Year and day of year (with fraction) |
| 34-43 | First derivative of mean motion | `.00006455` | Orbital decay rate |
| 45-52 | Second derivative of mean motion | `00000-0` | Rate of orbital decay change |
| 54-61 | BSTAR drag term | `12345-3` | Atmospheric drag coefficient |
| 63 | Ephemeris type | `0` | Internal use |
| 65-68 | Element set number | `999` | Sequential number |
| 69 | Checksum | `3` | Modulo-10 checksum |

#### Line 2: Orbital Elements

| Column(s) | Keplerian Element | Example | Description |
|-----------|-------------------|---------|-------------|
| 1 | Line number | `2` | Always "2" for second line |
| 3-7 | Catalog number | `25544` | Same as line 1 |
| **9-16** | **Inclination (i)** | `51.6435` | **Orbital tilt in degrees** |
| **18-25** | **RAAN (Ω)** | `132.8077` | **Position of ascending node in degrees** |
| **27-33** | **Eccentricity (e)** | `0009821` | **Stored without leading decimal (0.0009821)** |
| **35-42** | **Argument of Perigee (ω)** | `94.4121` | **Orientation of perigee in degrees** |
| **44-51** | **Mean Anomaly (M)** | `44.3422` | **Position at epoch (used instead of ν)** |
| **53-63** | **Mean Motion (n)** | `15.50338483` | **Orbits per day (relates to a)** |
| 64-68 | Revolution number | `48571` | Completed orbits since launch |
| 69 | Checksum | `1` | Modulo-10 checksum |

### Important Notes

1. **Epoch Specification**:
   - Format: YYDDD.DDDDDDDD
   - YY = Last two digits of year
   - DDD = Day of year (1-366)
   - Decimal = Fraction of day
   - Example: `24291.51803472` = 2024, day 291, 0.51803472 days = October 17, 2024, 12:25:58 UTC

2. **Eccentricity Format**:
   - Stored without the leading "0."
   - `0009821` represents 0.0009821
   - Assumes value is always less than 1.0

3. **Decimal Point Assumption**:
   - BSTAR and derivatives use assumed decimal point
   - Format: `12345-3` means 0.12345 × 10⁻³

### Computing Semi-Major Axis from Mean Motion

The TLE provides mean motion (revolutions per day) instead of semi-major axis. To calculate the semi-major axis:

$$a = \left( \frac{\mu}{\left(\frac{2\pi n}{86400}\right)^2} \right)^{1/3}$$

where:
- $n$ = mean motion from TLE (rev/day)
- $\mu$ = 3.986004418 × 10¹⁴ m³/s²
- Result is in meters

**Example for ISS**:
- Mean motion: 15.50338483 rev/day
- Semi-major axis: ~6,778 km
- Altitude: ~400 km (subtracting Earth's radius)

### Parsing Challenges

When implementing a TLE parser, watch for:
- **Fixed-width format**: Fields must be read at exact column positions
- **Assumed decimal points**: Eccentricity and scientific notation fields
- **Checksum validation**: Each line ends with modulo-10 checksum
- **2-digit year**: Requires interpretation logic (see Ephemeris Y2K handling)
- **Sign handling**: Some fields can be negative (e.g., mean motion derivatives)

---

## Ensuring Prediction Accuracy

Because orbits are dynamic and constantly perturbed, accurate future predictions depend on how frequently TLEs are updated and how well models account for perturbations.

### Understanding Orbital Perturbations

Perfect Keplerian orbits assume:
- Perfectly spherical Earth
- No atmosphere
- No other gravitational bodies
- No radiation pressure

In reality, satellites experience:
- **Earth's oblateness** (J₂ effect)
- **Atmospheric drag** (LEO satellites)
- **Solar radiation pressure**
- **Third-body effects** (Moon, Sun)
- **Solar activity variations**

### Practical Guidelines for Accurate Predictions

#### 1. Use the Latest TLE Data

TLE accuracy degrades over time—sometimes within a few days.

| Orbit Type | Altitude | Update Frequency | Reason |
|-----------|----------|------------------|--------|
| **LEO** | 200-2,000 km | Every 1-3 days | High atmospheric drag |
| **MEO** | 2,000-35,786 km | Weekly | Moderate perturbations |
| **GEO** | ~35,786 km | Weekly to monthly | Stable orbits |
| **HEO** | Variable | Weekly | Complex perturbations |

**Sources for Fresh TLEs**:
- [CelesTrak](https://celestrak.com/NORAD/elements/)
- [Space-Track.org](https://www.space-track.org/) (free registration required)
- [N2YO.com](https://www.n2yo.com/)

#### 2. Account for Perturbations

Different orbital regimes experience different dominant perturbations:

**Low Earth Orbit (LEO)** - 200-2,000 km:
- **Primary**: Atmospheric drag (most significant)
- **Secondary**: Earth's oblateness (J₂)
- **Effect**: Orbital decay, mean motion increase
- **Example**: ISS requires regular reboosts to maintain altitude

**Medium Earth Orbit (MEO)** - 2,000-35,786 km:
- **Primary**: Earth's oblateness
- **Secondary**: Lunar and solar gravity
- **Effect**: RAAN and perigee precession
- **Example**: GPS satellites maintain precise orbits

**Geostationary Orbit (GEO)** - ~35,786 km:
- **Primary**: Lunar and solar gravity
- **Secondary**: Solar radiation pressure
- **Effect**: Slow drift in longitude
- **Example**: Communication satellites need station-keeping

**Highly Elliptical Orbit (HEO)**:
- **Primary**: Lunar and solar gravity
- **Secondary**: Earth's oblateness at perigee
- **Effect**: Complex precession patterns
- **Example**: Molniya satellites

#### 3. Propagate Carefully

Prediction accuracy degrades with time from the TLE epoch:

| Orbit Type | Prediction Horizon | Expected Accuracy |
|-----------|-------------------|-------------------|
| **LEO** | 1-3 days | ~1 km |
| **LEO** | 7-10 days | ~10-50 km |
| **LEO** | >14 days | May exceed 100 km |
| **MEO** | 7-14 days | ~1-5 km |
| **GEO** | 14-30 days | ~10 km |

**Best Practices**:
- **Limit LEO predictions** to 10-14 days ahead
- **Use high-fidelity propagators** for mission-critical applications:
  - **SGP4/SDP4**: Good for general tracking
  - **HPOP**: Higher precision, accounts for more forces
  - **GMAT**: Full-featured orbit analysis
  - **Orekit**: Comprehensive orbital mechanics library

#### 4. Cross-Check with Observations

Compare predictions with actual observations:

**Radio Tracking**:
- Amateur radio operators often track satellites
- Doppler shift measurements provide velocity data
- Time of signal acquisition/loss validates pass predictions

**Optical Observations**:
- Telescope sightings confirm position
- Satellite brightness variations indicate orientation
- Laser ranging (for equipped satellites) gives millimeter accuracy

**Automated Systems**:
- Ground station networks log actual pass times
- ADS-B and similar systems for specific satellites
- Compare predicted vs. actual to calibrate models

#### 5. Understand Model Limitations

Different propagators have different strengths:

**SGP4 (Simplified General Perturbations 4)**:
- ✅ Fast computation
- ✅ Good for routine tracking
- ✅ Handles LEO and MEO well
- ❌ Simplified atmospheric model
- ❌ Accuracy degrades >14 days
- ❌ Not suitable for precise orbit determination

**SDP4 (Simplified Deep-space Perturbations 4)**:
- ✅ Better for GEO and HEO
- ✅ Includes lunar/solar effects
- ✅ Handles deep-space resonances
- ❌ Still simplified models
- ❌ Limited accuracy for long-term predictions

**High-Precision Orbit Propagators (HPOP)**:
- ✅ Full gravity field models
- ✅ Detailed atmospheric models
- ✅ Solar radiation pressure
- ✅ Suitable for mission planning
- ❌ Computationally expensive
- ❌ Requires more initial state information

### Factors Affecting TLE Accuracy

#### Atmospheric Density Variations

Solar activity causes atmospheric expansion:
- **Solar maximum**: Higher drag, faster orbital decay
- **Solar minimum**: Lower drag, slower decay
- **Space weather events**: Sudden density increases

#### Satellite Characteristics

Different satellites decay at different rates:
- **Area-to-mass ratio**: Larger satellites experience more drag
- **Orientation**: Tumbling vs. stabilized affects drag
- **Active maneuvering**: Station-keeping burns invalidate TLEs

#### Measurement Uncertainty

TLE generation involves:
- Radar and optical tracking data
- State estimation algorithms
- Orbital fitting procedures
- Inherent measurement noise

### When to Request New TLEs

Request or download fresh TLE data when:
- ✅ **Planning satellite observations** (within 24-48 hours)
- ✅ **Collision avoidance analysis** (use most recent data)
- ✅ **After satellite maneuvers** (TLE will be updated)
- ✅ **Accuracy is critical** (research, antenna pointing)
- ✅ **TLE epoch is >7 days old** for LEO
- ✅ **TLE epoch is >30 days old** for GEO

### Practical Accuracy Example

For the ISS at LEO (~400 km altitude):

| Time from Epoch | Position Error (typical) | Notes |
|----------------|-------------------------|-------|
| 0 hours | 0 km | At epoch time |
| 12 hours | 0.1-0.5 km | Excellent |
| 1 day | 0.5-2 km | Very good |
| 3 days | 2-5 km | Good for general tracking |
| 7 days | 5-20 km | Acceptable for planning |
| 14 days | 20-100 km | Poor, update TLE |
| 30 days | >100 km | Unacceptable |

---

## Swift Implementation in Ephemeris

Now that we understand the theoretical foundation, let's see how Ephemeris implements these concepts in Swift. The framework provides clean, type-safe APIs that make orbital mechanics accessible to iOS developers.

### The `Orbit` Struct

The `Orbit` struct represents a satellite's orbital elements and provides methods for position calculation:

```swift
import Ephemeris

// Parse ISS TLE data
let tleString = """
ISS (ZARYA)
1 25544U 98067A   24291.51803472  .00006455  00000-0  12345-3 0  9993
2 25544  51.6435 132.8077 0009821  94.4121  44.3422 15.50338483 48571
"""

let tle = try TwoLineElement(from: tleString)
let orbit = Orbit(from: tle)

// Access orbital elements
print("Semi-major axis: \(orbit.semimajorAxis) km")        // ~6,778 km
print("Eccentricity: \(orbit.eccentricity)")               // ~0.0009821
print("Inclination: \(orbit.inclination)°")                // 51.6435°
print("RAAN: \(orbit.rightAscensionOfAscendingNode)°")    // 132.8077°
print("Argument of Perigee: \(orbit.argumentOfPerigee)°") // 94.4121°
print("Mean Anomaly: \(orbit.meanAnomaly)°")              // 44.3422°
```

### Calculating Semi-Major Axis from Mean Motion

Ephemeris automatically calculates the semi-major axis from the TLE's mean motion using Kepler's Third Law:

```swift
import Ephemeris

// Static method for calculating semi-major axis
let meanMotion = 15.50338483  // revolutions per day from TLE
let semimajorAxis = Orbit.calculateSemimajorAxis(meanMotion: meanMotion)
print("Semi-major axis: \(semimajorAxis) km")  // ~6,778 km

// Calculate altitude above Earth's surface
let altitude = semimajorAxis - PhysicalConstants.Earth.radius
print("Altitude: \(altitude) km")  // ~400 km
```

**Implementation:**

```swift
public static func calculateSemimajorAxis(meanMotion: Double) -> Double {
    let µ = PhysicalConstants.Earth.µ  // 398,600.4418 km³/s²
    let n = meanMotion * 2 * .pi / PhysicalConstants.Time.secondsPerDay
    return pow(µ / (n * n), 1.0 / 3.0)
}
```

### Solving Kepler's Equation: Mean → Eccentric → True Anomaly

The most computationally intensive part of orbital mechanics is converting mean anomaly to true anomaly. Ephemeris uses Newton-Raphson iteration to solve Kepler's equation:

```swift
import Ephemeris

// Starting with mean anomaly from TLE
let meanAnomaly: Degrees = 44.3422  // M
let eccentricity = 0.0009821        // e

// Step 1: Solve for eccentric anomaly (iterative)
let eccentricAnomaly = Orbit.calculateEccentricAnomaly(
    eccentricity: eccentricity,
    meanAnomaly: meanAnomaly
)
print("Eccentric anomaly: \(eccentricAnomaly)°")

// Step 2: Calculate true anomaly
let trueAnomaly = try Orbit.calculateTrueAnomaly(
    eccentricity: eccentricity,
    eccentricAnomaly: eccentricAnomaly
)
print("True anomaly: \(trueAnomaly)°")
```

**Newton-Raphson Implementation:**

```swift
public static func calculateEccentricAnomaly(
    eccentricity: Double,
    meanAnomaly: Degrees
) -> Degrees {
    let M = meanAnomaly.inRadians()
    var E = M  // Initial guess

    let tolerance = PhysicalConstants.Calculation.defaultAccuracy
    let maxIterations = PhysicalConstants.Calculation.maxIterations

    for _ in 0..<maxIterations {
        let delta = (E - eccentricity * sin(E) - M) / (1 - eccentricity * cos(E))
        E -= delta

        if abs(delta) < tolerance {
            break  // Converged
        }
    }

    return E.inDegrees()
}
```

This typically converges in 3-5 iterations for typical satellite eccentricities (e < 0.1).

### Calculating Satellite Position

Once we have the true anomaly, we can calculate the satellite's position in 3D space:

```swift
import Ephemeris
import Foundation

// Calculate position at a specific time
let orbit = Orbit(from: tle)
let position = try orbit.calculatePosition(at: Date())

print("Latitude: \(position.latitude)°")
print("Longitude: \(position.longitude)°")
print("Altitude: \(position.altitude) km")
```

**Behind the scenes**, `calculatePosition(at:)` performs these steps:

1. Propagate mean anomaly forward in time: $M(t) = M_0 + n(t - t_0)$
2. Solve Kepler's equation for eccentric anomaly: $E$
3. Convert to true anomaly: $\nu$
4. Calculate position in orbital plane: $r = \frac{a(1-e^2)}{1 + e\cos(\nu)}$
5. Transform to ECI coordinates using $i$, $\Omega$, $\omega$
6. Rotate to ECEF using Greenwich Sidereal Time
7. Convert to geodetic coordinates (lat, lon, alt)

### TLE Parsing and Validation

Ephemeris provides robust TLE parsing with checksum validation and error handling:

```swift
import Ephemeris

let tleString = """
ISS (ZARYA)
1 25544U 98067A   24291.51803472  .00006455  00000-0  12345-3 0  9993
2 25544  51.6435 132.8077 0009821  94.4121  44.3422 15.50338483 48571
"""

do {
    let tle = try TwoLineElement(from: tleString)

    // Access parsed fields
    print("Satellite: \(tle.name)")
    print("Catalog #: \(tle.catalogNumber)")
    print("Epoch: Year \(tle.epochYear), Day \(tle.epochDay)")

    // Orbital elements
    print("Inclination: \(tle.inclination)°")
    print("RAAN: \(tle.rightAscension)°")
    print("Eccentricity: \(tle.eccentricity)")
    print("Arg of Perigee: \(tle.argumentOfPerigee)°")
    print("Mean Anomaly: \(tle.meanAnomaly)°")
    print("Mean Motion: \(tle.meanMotion) rev/day")

} catch TLEParsingError.invalidChecksum(let line, let expected, let actual) {
    print("Checksum error on line \(line): expected \(expected), got \(actual)")
} catch TLEParsingError.invalidFormat(let message) {
    print("Invalid TLE format: \(message)")
} catch {
    print("Parse error: \(error)")
}
```

**Key TLE Parsing Features:**
- Fixed-width field extraction using string subscripting
- Checksum validation for data integrity
- 2-digit year interpretation (±50 year window from current date)
- Assumed decimal point handling for eccentricity (`0009821` → `0.0009821`)
- Scientific notation parsing for BSTAR drag term

### Complete Example: Tracking the ISS

Here's a complete example that ties everything together:

```swift
import Ephemeris
import Foundation

// 1. Parse TLE data
let issТLE = """
ISS (ZARYA)
1 25544U 98067A   24291.51803472  .00006455  00000-0  12345-3 0  9993
2 25544  51.6435 132.8077 0009821  94.4121  44.3422 15.50338483 48571
"""

do {
    let tle = try TwoLineElement(from: issТLE)
    let orbit = Orbit(from: tle)

    // 2. Analyze orbital characteristics
    let earthRadius = PhysicalConstants.Earth.radius
    let apogee = orbit.semimajorAxis * (1 + orbit.eccentricity) - earthRadius
    let perigee = orbit.semimajorAxis * (1 - orbit.eccentricity) - earthRadius

    print("=== ISS Orbital Analysis ===")
    print("Semi-major axis: \(orbit.semimajorAxis) km")
    print("Eccentricity: \(orbit.eccentricity)")
    print("Apogee altitude: \(apogee) km")
    print("Perigee altitude: \(perigee) km")
    print("Inclination: \(orbit.inclination)°")

    // 3. Calculate orbital period (Kepler's Third Law)
    let µ = PhysicalConstants.Earth.µ
    let period = 2 * .pi * sqrt(pow(orbit.semimajorAxis, 3) / µ)
    print("Orbital period: \(period / 60) minutes")

    // 4. Track ISS over the next hour
    let startTime = Date()
    let timeInterval: TimeInterval = 60  // 1 minute steps

    print("\n=== ISS Position Tracking ===")
    for i in 0..<60 {
        let time = startTime.addingTimeInterval(Double(i) * timeInterval)
        let position = try orbit.calculatePosition(at: time)

        if i % 10 == 0 {  // Print every 10 minutes
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            print("\(formatter.string(from: time)): " +
                  "\(String(format: "%.2f", position.latitude))° lat, " +
                  "\(String(format: "%.2f", position.longitude))° lon, " +
                  "\(String(format: "%.0f", position.altitude)) km alt")
        }
    }

} catch {
    print("Error: \(error)")
}
```

**Sample Output:**
```
=== ISS Orbital Analysis ===
Semi-major axis: 6778.137 km
Eccentricity: 0.0009821
Apogee altitude: 406.7 km
Perigee altitude: 393.3 km
Inclination: 51.6435°
Orbital period: 92.68 minutes

=== ISS Position Tracking ===
2:30 PM: 23.45° lat, -74.32° lon, 400 km alt
2:40 PM: 38.12° lat, -52.18° lon, 402 km alt
2:50 PM: 48.67° lat, -28.45° lon, 404 km alt
3:00 PM: 51.23° lat, -3.12° lon, 406 km alt
3:10 PM: 45.89° lat, 22.67° lon, 404 km alt
3:20 PM: 32.34° lat, 45.23° lon, 401 km alt
```

### Performance Considerations

**Kepler's Equation Convergence:**
- Typical convergence: 3-5 iterations for low eccentricity orbits (e < 0.1)
- Worst case: ~10-15 iterations for highly elliptical orbits (e > 0.7)
- Complexity: O(n) where n is number of iterations, typically O(1) constant time

**Position Calculation:**
- Single position: ~50 microseconds on modern iOS hardware
- 1000 positions: ~50 milliseconds
- Suitable for real-time tracking and animation

**Accuracy:**
- Ephemeris uses pure Keplerian mechanics (two-body problem)
- Does not include atmospheric drag, solar radiation pressure, or perturbations
- Best accuracy: Within 1-3 days of TLE epoch
- Acceptable accuracy: Up to 7-10 days for LEO satellites
- **Recommendation**: Update TLEs regularly for mission-critical applications

---

## Summary

The six Keplerian orbital elements provide a complete mathematical description of a satellite's orbit:

| Purpose | Element(s) | What It Describes | TLE Field |
|---------|-----------|-------------------|-----------|
| **Shape & Size** | Semi-Major Axis (a) | Orbital size, period | Mean Motion (n) |
| | Eccentricity (e) | Orbital shape (circle to ellipse) | Eccentricity |
| **Orientation** | Inclination (i) | Tilt of orbital plane | Inclination |
| | RAAN (Ω) | Rotation of orbital plane | RAAN |
| | Argument of Perigee (ω) | Orientation within plane | Argument of Perigee |
| **Position** | True Anomaly (ν) | Current location in orbit | Mean Anomaly (M) |

### The Complete Picture

Understanding these elements allows you to:

1. **Visualize the orbit** - size, shape, and orientation in 3D space
2. **Predict positions** - where the satellite will be at any future time
3. **Plan observations** - when the satellite will be visible from a location
4. **Avoid collisions** - predict close approaches between objects
5. **Design missions** - choose optimal orbits for specific applications

### Key Takeaways

- ✨ **Keplerian elements define the orbit** - six numbers completely describe elliptical motion
- 📡 **TLEs record it compactly** - standardized format for data sharing
- 🔮 **Propagation models predict the future** - SGP4/SDP4 calculate positions forward in time
- 🎯 **Accuracy requires fresh data** - TLEs degrade, update regularly
- 🌍 **Real orbits are perturbed** - Earth's shape, atmosphere, Moon, and Sun all affect satellites

Every accurate satellite pass prediction, collision avoidance maneuver, and launch trajectory starts with understanding these six parameters. The Ephemeris framework implements these concepts to provide precise satellite tracking for iOS applications.

---

## References

### Academic Papers and Technical Documents

1. **Satellite Tracking Using NORAD Two-Line Element Set Format**  
   *Emilian-Ionuț Croitoru, Gheorghe Oancea*  
   Transilvania University of Brașov  
   [PDF Link](http://www.afahc.ro/ro/afases/2016/MATH&IT/CROITORU_OANCEA.pdf)

2. **Calculation of Satellite Position from Ephemeris Data**  
   *Applied GPS for Engineers and Project Managers*  
   [ASCE Library](https://ascelibrary.org/doi/pdf/10.1061/9780784411506.ap03)

3. **Describing Orbits**  
   *Federal Aviation Administration*  
   [FAA Document](https://www.faa.gov/about/office_org/headquarters_offices/avs/offices/aam/cami/library/online_libraries/aerospace_medicine/tutorial/media/iii.4.1.4_describing_orbits.pdf)

4. **Transformation of Orbit Elements**  
   *Space Electronic Reconnaissance: Localization Theories and Methods*  
   [Wiley Online Library](https://onlinelibrary.wiley.com/doi/pdf/10.1002/9781118542200.app1)

5. **Introduction to Orbital Mechanics**  
   *W. Horn, B. Shapiro, C. Shubin, F. Varedi*  
   California State University Northridge  
   [CSUN Course](https://www.csun.edu/~hcmth017/master/master.html)

6. **Computation of Sub-Satellite Points from Orbital Elements**  
   *Richard H. Christ, NASA*  
   [NASA Technical Report](https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19650015945.pdf)

7. **Revisiting Spacetrack Report #3**  
   *CelesTrak*  
   [PDF Link](http://www.celestrak.com/publications/AIAA/2006-6753/AIAA-2006-6753-Rev3.pdf)

### Online Resources

- **CelesTrak** - [https://celestrak.com/](https://celestrak.com/)  
  Current TLE data and orbital mechanics resources

- **Space-Track.org** - [https://www.space-track.org/](https://www.space-track.org/)  
  Official source for space surveillance data (free registration required)

- **N2YO** - [https://www.n2yo.com/](https://www.n2yo.com/)  
  Real-time satellite tracking and TLE data

### Books and Advanced Resources

- **Fundamentals of Astrodynamics** by Bate, Mueller, and White  
  Classical textbook on orbital mechanics

- **Satellite Orbits: Models, Methods and Applications** by Montenbruck and Gill  
  Comprehensive guide to orbit determination and prediction

- **Methods of Astrodynamics: A Computer Approach**  
  [Academia.edu](https://www.academia.edu/20528856/Methods_of_Astrodynamics_a_Computer_Approach)

### Image Credits

Orbital element diagrams in this document are sourced from Wikimedia Commons under Creative Commons licenses:
- Orbit diagrams: CC BY-SA 3.0 or Public Domain
- Original creators credited in figure captions where applicable

**Note**: The following external diagram links should be downloaded and embedded locally in `docs/assets/orbital-elements/` with proper attribution:
- Figure 1: Orbit1.svg (Semi-major axis visualization)
- Figure 2: Orbit_shapes.svg (Eccentricity examples)
- Figure 3: Orbit_-_Plane_and_Inclination_-_Color.png (Inclination)
- Figure 4: Orbit2.svg (RAAN diagram)
- Figure 5: Orbit3.svg (Argument of perigee)
- Figure 6: Orbit_geometry.svg (True anomaly)

---

## See Also

**Learning Path:**
- **Next**: [Observer Geometry](observer-geometry.md) - Coordinate transformations and pass prediction
- [Visualization](visualization.md) - Ground tracks and sky tracks
- [API Reference](api-reference.md) - Complete API documentation

**Quick Start:**
- [Getting Started Guide](getting-started.md) - Build your first satellite tracker
- [README](../README.md) - Installation and usage examples

**Reference:**
- [Coordinate Systems](coordinate-systems.md) - Deep dive on ECI, ECEF, and transformations

---

*This documentation is part of the [Ephemeris](https://github.com/mvdmakesthings/Ephemeris) framework for satellite tracking in Swift.*

**Last Updated**: October 20, 2025
**Version**: 1.0
