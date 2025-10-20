# Time Systems for Coordinate Transformations

> **Brief Description**: Learn about time scales, Julian Day Number, and Greenwich Mean Sidereal Time (GMST) calculations essential for ECI ↔ ECEF transformations in satellite tracking.

## Overview

Time is fundamental to satellite tracking. The transformation between inertial (ECI) and Earth-fixed (ECEF) coordinate frames requires precise knowledge of **Earth's rotation angle**, which depends on time. This document covers the time systems and calculations used in satellite orbital mechanics.

**Theory-First Approach**: We begin with the mathematical definition of time scales, derive the Julian Day Number calculation, explain Greenwich Mean Sidereal Time in detail, and show how these concepts enable coordinate transformations.

**What You'll Learn:**
- Different time scales (UTC, UT1, TT, TAI) and their relationships
- Julian Day Number calculation and the J2000.0 epoch
- Julian centuries and their use in polynomial approximations
- Greenwich Mean Sidereal Time (GMST) complete derivation
- Sidereal day vs solar day
- GMST calculation from calendar date
- Applications in ECI ↔ ECEF transformation
- How Ephemeris implements time calculations

---

## Table of Contents

- [Time Scales](#time-scales)
- [Universal Time (UT1)](#universal-time-ut1)
- [Coordinated Universal Time (UTC)](#coordinated-universal-time-utc)
- [Terrestrial Time (TT)](#terrestrial-time-tt)
- [International Atomic Time (TAI)](#international-atomic-time-tai)
- [Time Scale Relationships](#time-scale-relationships)
- [Julian Day Number](#julian-day-number)
- [J2000.0 Epoch](#j20000-epoch)
- [Julian Centuries](#julian-centuries)
- [Sidereal Time Fundamentals](#sidereal-time-fundamentals)
- [Greenwich Mean Sidereal Time (GMST)](#greenwich-mean-sidereal-time-gmst)
- [GMST Calculation](#gmst-calculation)
- [Applications in Satellite Tracking](#applications-in-satellite-tracking)
- [Ephemeris Implementation](#ephemeris-implementation)
- [See Also](#see-also)
- [References](#references)

---

## Time Scales

### Why Multiple Time Scales?

Different applications require different definitions of "time":

**Astronomy/Navigation**: Needs time based on Earth's rotation
**Physics/Engineering**: Needs uniform time not affected by Earth's irregular rotation
**Civil life**: Needs time synchronized with day/night cycle

### The Challenge

**Earth's rotation is not uniform**:
- Slowing down due to tidal friction (~2 milliseconds per century)
- Irregular variations from atmospheric/oceanic effects
- Unpredictable at precision < 1 second

**Solution**: Define multiple time scales for different purposes.

---

## Universal Time (UT1)

### Definition

**Universal Time 1 (UT1)** is a time scale based on Earth's actual rotation angle.

**Physical meaning**: UT1 is defined so that the **mean solar day** lasts exactly 24 hours on average.

**Determination**: Measured by observing stars with respect to Earth's meridians (Very Long Baseline Interferometry - VLBI).

### Relationship to Earth Rotation

UT1 is directly proportional to **Earth Rotation Angle** (ERA):

$$
\text{ERA} = 2\pi(0.7790572732640 + 1.00273781191135448 \times T_{UT1})
$$

where $T_{UT1}$ is days since J2000.0 in UT1.

### Problems with UT1

**Not uniform**: Earth's rotation rate varies
- Cannot use as fundamental time standard for physics
- Cannot predict future values precisely

**Solution**: Use atomic time for uniform timekeeping, keep UT1 for astronomical purposes.

---

## Coordinated Universal Time (UTC)

### Definition

**Coordinated Universal Time (UTC)** is the civil time scale used worldwide.

**Based on**: International Atomic Time (TAI) with **leap seconds** added to stay close to UT1.

**Requirement**: $|UTC - UT1| < 0.9$ seconds

### Leap Seconds

**Leap seconds** are occasional 1-second adjustments to keep UTC synchronized with Earth's rotation:

**When added**: Typically June 30 or December 31 at 23:59:60 UTC

**Frequency**: Irregular, determined by IERS (International Earth Rotation Service)
- Historically: ~1 per 18 months on average
- Recent years: Less frequent as Earth's rotation rate varies

**Example**:
```
Normal day: 23:59:58, 23:59:59, 00:00:00
Leap second: 23:59:58, 23:59:59, 23:59:60, 00:00:00
```

### UTC vs UT1

**Relationship**:
$$
UT1 - UTC = \text{DUT1}
$$

where DUT1 (Delta UT1) is published by IERS and varies between -0.9 and +0.9 seconds.

**For satellite tracking**: Often approximate $UT1 \approx UTC$ (error < 1 second acceptable for most applications).

---

## Terrestrial Time (TT)

### Definition

**Terrestrial Time (TT)** is a uniform time scale used for calculations in the solar system.

**Based on**: Atomic time, designed to be continuous and uniform
**No leap seconds**: Unlike UTC, TT flows continuously

### Relationship to TAI

$$
TT = TAI + 32.184 \text{ seconds}
$$

The 32.184-second offset is historical, chosen so that TT matches the old Ephemeris Time (ET) at January 1, 1977.

### Use in Astrodynamics

**TT is preferred** for:
- Orbital mechanics calculations
- Ephemeris computations
- High-precision astronomy

**J2000.0 epoch** is defined in TT:
$$
\text{J2000.0} = \text{January 1, 2000, 12:00:00 TT}
$$

---

## International Atomic Time (TAI)

### Definition

**International Atomic Time (TAI)** is the fundamental uniform time scale based on atomic clocks.

**Basis**: Average of ~450 atomic clocks worldwide
**Accuracy**: ~1 nanosecond per day
**No leap seconds**: Continuous, uniform flow

### Relationship to UTC

$$
TAI = UTC + (\text{leap seconds})
$$

**As of 2017**: TAI - UTC = 37 seconds (37 leap seconds since 1972)

**Future values**: Cannot be predicted (depends on Earth's rotation)

### Standard: SI Second

The **SI second** is defined as:
> The duration of 9,192,631,770 periods of the radiation corresponding to the transition between two hyperfine levels of the ground state of the caesium-133 atom.

TAI uses this definition.

---

## Time Scale Relationships

### Summary Diagram

```
TAI (atomic, uniform, no leap seconds)
 ↓ +32.184 s
TT (uniform, for ephemeris calculations)

UTC (civil time, with leap seconds)
 ↓ ±0.9 s (DUT1)
UT1 (Earth rotation angle)
 ↓ (used for GMST)
Earth Rotation → ECI/ECEF transformation
```

### Conversion Formulas

**TAI ↔ TT**:
$$
TT = TAI + 32.184 \text{ s}
$$

**TAI ↔ UTC**:
$$
TAI = UTC + (\text{number of leap seconds since 1972})
$$

**UTC ↔ UT1**:
$$
UT1 = UTC + DUT1
$$
where DUT1 is published by IERS (typically |DUT1| < 0.9 s).

**TT ↔ UT1** (approximate):
$$
TT \approx UT1 + 32.184 + (\text{leap seconds}) \approx UT1 + 69.184 \text{ s (as of 2024)}
$$

### Practical Simplification

**For satellite tracking** (sub-kilometer accuracy):
- Use UTC for time input
- Approximate $UT1 \approx UTC$ (ignore DUT1)
- Calculate GMST using UTC

**For high precision** (mission operations, laser ranging):
- Use TT for ephemeris
- Obtain precise UT1 from IERS Bulletin A
- Apply UT1-UTC correction

---

## Julian Day Number

### Definition

The **Julian Day Number (JD)** is a continuous count of days since a reference epoch.

**Epoch**: January 1, 4713 BCE, 12:00 Universal Time (proleptic Julian calendar)

**Current JD**: ~2,460,000 (as of 2024)

### Why Julian Day?

**Advantages**:
1. **Continuous**: No months, years, or leap year complications
2. **Simple arithmetic**: Time difference = JD2 - JD1
3. **Unambiguous**: One number specifies date and time
4. **Widely used**: Standard in astronomy and astrodynamics

### Calculation from Calendar Date

**Given**: Year $Y$, Month $M$, Day $D$, Hour $H$, Minute $m$, Second $s$

**Formula** (for dates after March 1, 1900):

**Step 1**: Adjust month
$$
\begin{aligned}
a &= \lfloor \frac{14 - M}{12} \rfloor \\
y &= Y + 4800 - a \\
m &= M + 12a - 3
\end{aligned}
$$

**Step 2**: Calculate JD (integer part)
$$
JD_{int} = D + \lfloor \frac{153m + 2}{5} \rfloor + 365y + \lfloor \frac{y}{4} \rfloor - \lfloor \frac{y}{100} \rfloor + \lfloor \frac{y}{400} \rfloor - 32045
$$

**Step 3**: Add fractional day
$$
JD = JD_{int} + \frac{H - 12}{24} + \frac{m}{1440} + \frac{s}{86400}
$$

**Note**: JD is defined to change at **noon** (12:00), not midnight. This is historical convention from astronomy (observations at night span same JD).

### Simplified Formula (Meeus)

Jean Meeus provides an alternative formulation:

For dates in Gregorian calendar (after October 15, 1582):

$$
JD = 367Y - \lfloor \frac{7(Y + \lfloor \frac{M+9}{12} \rfloor)}{4} \rfloor + \lfloor \frac{275M}{9} \rfloor + D + 1721013.5 + \frac{UT}{24}
$$

where $UT$ is Universal Time in hours (fractional).

### Example

**Date**: January 1, 2000, 12:00:00 UTC

**Calculation**:
- $Y = 2000$, $M = 1$, $D = 1$
- $H = 12$, $m = 0$, $s = 0$

Using Meeus formula:
$$
JD = 367(2000) - \lfloor \frac{7(2000 + 1)}{4} \rfloor + \lfloor \frac{275(1)}{9} \rfloor + 1 + 1721013.5 + \frac{12}{24}
$$
$$
JD = 734000 - 3502 + 30 + 1 + 1721013.5 + 0.5 = 2451545.0
$$

**Result**: JD = 2451545.0 (this is the J2000.0 epoch!)

### Modified Julian Day (MJD)

To reduce the size of the number:

$$
MJD = JD - 2400000.5
$$

**MJD 0**: November 17, 1858, 00:00 UT

**Usage**: Convenient for modern dates (5-digit number instead of 7-digit)

---

## J2000.0 Epoch

### Definition

**J2000.0** is the standard reference epoch for modern astrodynamics:

$$
\text{J2000.0} = \text{JD } 2451545.0 = \text{January 1, 2000, 12:00:00 TT}
$$

**"J"** denotes Julian epoch (not Besselian "B" used for older epochs like B1950.0).

### Significance

**Reference point for**:
- ECI coordinate system orientation
- Orbital element epoch
- Precession calculations
- Polynomial approximations of time-varying quantities

**Why 2000?**: Nice round number near turn of millennium, international agreement.

### Julian Date of J2000.0

$$
JD_{J2000} = 2451545.0
$$

**In MJD**:
$$
MJD_{J2000} = 51544.5
$$

---

## Julian Centuries

### Definition

A **Julian century** is exactly 36,525 days.

**Time since J2000.0** in Julian centuries:

$$
T = \frac{JD - 2451545.0}{36525}
$$

where $JD$ is the Julian Day Number.

### Why Julian Centuries?

**Polynomial approximations**: Many astronomical quantities vary slowly over time and can be approximated by polynomials in $T$:

$$
X(T) = X_0 + X_1 T + X_2 T^2 + X_3 T^3 + \ldots
$$

**Examples**:
- Precession angles
- Nutation terms
- Greenwich Mean Sidereal Time
- Mean orbital elements

### Time Scales

**Choice of JD**: Use appropriate time scale for calculation
- **For GMST**: Use UT1 (or approximate with UTC)
- **For orbital elements**: Use TT
- **For precession**: Use TT

---

## Sidereal Time Fundamentals

### Sidereal Day

A **sidereal day** is the time Earth takes to rotate 360° relative to distant stars.

**Duration**:
$$
T_{sidereal} = 23^h 56^m 4.0905^s = 86164.0905 \text{ seconds}
$$

### Solar Day

A **solar day** is the time between successive solar noons (Sun at highest point).

**Duration**:
$$
T_{solar} = 24^h 00^m 00^s = 86400 \text{ seconds}
$$

### Why the Difference?

**Earth orbits the Sun**: In one day, Earth rotates ~360° but also moves ~1° along its orbit.

**Extra rotation**: Earth must rotate an additional ~1° to bring Sun back to same position.

**Calculation**:
$$
\text{Extra angle per day} = \frac{360°}{365.25 \text{ days}} \approx 0.9856° \text{ per day}
$$

**Time for extra rotation**:
$$
\Delta t = \frac{0.9856°}{360°} \times 86400 \text{ s} \approx 236 \text{ s} \approx 3^m 56^s
$$

**Image Placeholder**:
```markdown
![Sidereal vs Solar Day](../assets/time-systems/sidereal-solar-day.png)
*Figure 1: Difference between sidereal day (Earth rotation relative to stars)
and solar day (Earth rotation relative to Sun). Earth must rotate ~361° for
Sun to return to same position due to orbital motion.
Source: [To be added - diagram explaining sidereal vs solar day]*
```

### Angular Velocity

**Sidereal rotation rate**:
$$
\omega_{sidereal} = \frac{2\pi}{86164.0905} = 7.2921159 \times 10^{-5} \text{ rad/s}
$$

**Degrees per day** (solar day):
$$
\omega_{degrees} = \frac{360°}{86164.0905} \times 86400 = 360.9856° \text{ per solar day}
$$

The extra 0.9856° per solar day accumulates as GMST advances relative to UTC.

---

## Greenwich Mean Sidereal Time (GMST)

### Definition

**Greenwich Mean Sidereal Time (GMST)** is the hour angle of the **mean vernal equinox** as measured from the Greenwich meridian.

**Physical meaning**: The angle Earth has rotated since the vernal equinox last crossed the Greenwich meridian.

**Range**: 0 to 24 hours (or 0° to 360°)

### Relationship to ECI/ECEF

**GMST is the rotation angle** between ECI and ECEF coordinate systems:

$$
\mathbf{r}_{ECEF} = \mathbf{R}_z(\theta_{GMST}) \mathbf{r}_{ECI}
$$

where $\theta_{GMST}$ is GMST converted to radians.

### Mean vs Apparent

**Mean Sidereal Time**: Based on mean vernal equinox (averages out nutation)

**Apparent Sidereal Time (GAST)**: Includes nutation (~9 arcseconds variation)

**For satellite tracking**: GMST (mean) is sufficient. GAST used for sub-arcsecond astronomy.

---

## GMST Calculation

### The IAU 1982 Formula

The standard formula from Aoki et al. (1982), adopted by IAU:

**GMST at 0h UT1** (midnight):

$$
GMST_0 = 24110.54841 + 8640184.812866 \cdot T_u + 0.093104 \cdot T_u^2 - 6.2 \times 10^{-6} \cdot T_u^3
$$

where:
- $GMST_0$ is in **seconds**
- $T_u$ is Julian centuries from J2000.0 in UT1:
  $$
  T_u = \frac{JD_{UT1} - 2451545.0}{36525}
  $$

### Terms Explained

**Constant term** (24110.54841 s):
- GMST at J2000.0 epoch (noon, not midnight)
- Corresponds to ~6h 41m 50.5s
- The vernal equinox's position at J2000.0

**Linear term** (8640184.812866 s/century):
- Earth's mean sidereal rotation rate
- Dominant term (grows linearly with time)
- Accounts for extra 0.9856°/day compared to UTC

**Quadratic term** (0.093104 s/century²):
- Long-term precession effect
- Earth's rotation axis precesses with 26,000-year period
- Changes the vernal equinox direction slowly

**Cubic term** (-6.2×10⁻⁶ s/century³):
- Very long-term variation
- Secular change in Earth's rotation rate
- Negligible for time spans < 100 years

### GMST at Arbitrary Time

For a time that's not exactly 0h UT1:

**Step 1**: Calculate JD in UT1

**Step 2**: Split into integer and fractional parts:
$$
JD_{UT1} = JD_{int} + JD_{frac}
$$
where $JD_{frac}$ is the fractional day (0 to 1).

**Step 3**: Calculate $T_u$ using $JD_{int} + 0.5$ (corresponding to 0h UT1):
$$
T_u = \frac{(JD_{int} + 0.5) - 2451545.0}{36525}
$$

**Step 4**: Calculate GMST at 0h UT1:
$$
GMST_0 = 24110.54841 + 8640184.812866 T_u + 0.093104 T_u^2 - 6.2 \times 10^{-6} T_u^3
$$

**Step 5**: Add contribution from time of day:
$$
GMST = GMST_0 + 1.00273790935 \times 86400 \times JD_{frac}
$$

The factor 1.00273790935 accounts for the sidereal day being shorter than solar day.

**Step 6**: Reduce to range [0, 86400) seconds:
$$
GMST = GMST \mod 86400
$$

### Conversion to Radians

For use in rotation matrices:
$$
\theta_{GMST} = GMST \times \frac{2\pi}{86400} \text{ radians}
$$

or equivalently:
$$
\theta_{GMST} = GMST \times \frac{\pi}{43200} \text{ radians}
$$

### Simplified Formula (Low Precision)

For applications not requiring sub-second accuracy, omit $T^2$ and $T^3$ terms:

$$
GMST \approx 24110.54841 + 8640184.812866 T_u + 1.00273790935 \times 86400 \times JD_{frac}
$$

**Accuracy**: ~0.1 second over range 1900-2100.

### Example Calculation

**Date**: January 1, 2000, 18:00:00 UTC

**Step 1**: JD calculation
$$
JD_{UTC} = 2451545.25 \quad \text{(J2000.0 is at noon, 18:00 is 6 hours later)}
$$

Assume $UT1 \approx UTC$, so $JD_{UT1} = 2451545.25$

**Step 2**: Split JD
$$
JD_{int} = 2451545, \quad JD_{frac} = 0.25
$$

**Step 3**: Calculate $T_u$
$$
T_u = \frac{(2451545 + 0.5) - 2451545.0}{36525} = \frac{0.5}{36525} \approx 1.37 \times 10^{-5}
$$

**Step 4**: GMST at 0h UT1 (approximately at J2000.0)
$$
GMST_0 \approx 24110.54841 + 8640184.812866 \times 1.37 \times 10^{-5} \approx 24110.54841 + 118.37 \approx 24228.9 \text{ s}
$$

**Step 5**: Add time of day contribution
$$
GMST = 24228.9 + 1.00273790935 \times 86400 \times 0.25 \approx 24228.9 + 21659.4 \approx 45888.3 \text{ s}
$$

**Step 6**: Reduce to [0, 86400)
$$
GMST = 45888.3 \mod 86400 = 45888.3 \text{ s} \approx 12^h 44^m 48^s
$$

**Convert to degrees**:
$$
\theta_{GMST} = 45888.3 \times \frac{360°}{86400} \approx 191.2°
$$

This is the rotation angle of Earth at 18:00 on J2000.0.

---

## Applications in Satellite Tracking

### ECI to ECEF Transformation

**Primary use**: Rotate satellite position from inertial frame to Earth-fixed frame:

$$
\begin{bmatrix} X_{ECEF} \\ Y_{ECEF} \\ Z_{ECEF} \end{bmatrix} = \begin{bmatrix}
\cos\theta & \sin\theta & 0 \\
-\sin\theta & \cos\theta & 0 \\
0 & 0 & 1
\end{bmatrix}
\begin{bmatrix} X_{ECI} \\ Y_{ECI} \\ Z_{ECI} \end{bmatrix}
$$

where $\theta = \theta_{GMST}$ in radians.

### Ground Track Generation

**Calculate sub-satellite point**:

1. Propagate orbit → Position in ECI
2. Calculate GMST for current time
3. Rotate to ECEF using GMST
4. Convert ECEF → Geodetic (lat, lon, alt)
5. Plot (lat, lon) on map

**Each time step** requires recalculating GMST as Earth rotates.

### Pass Prediction Timing

**Accurate timing** of AOS (Acquisition of Signal) and LOS (Loss of Signal):

- Must account for Earth's rotation to determine when satellite rises above horizon
- GMST connects time to Earth orientation
- Bisection algorithm refines crossing times to ~1 second accuracy

### Satellite Velocity in ECEF

**Velocity transformation** includes Earth's rotation:

$$
\mathbf{v}_{ECEF} = \mathbf{R}_z(\theta_{GMST}) \mathbf{v}_{ECI} + \boldsymbol{\omega}_\oplus \times \mathbf{r}_{ECEF}
$$

where $\boldsymbol{\omega}_\oplus = (0, 0, 7.2921159 \times 10^{-5})$ rad/s.

---

## Ephemeris Implementation

### Date Extensions

Ephemeris provides extensions to Swift's `Date` type for time calculations:

```swift
import Foundation

extension Date {
    /// Calculate Julian Day Number from Date
    public func julianDay() -> Double {
        // Implementation converts Date to JD
        // Assumes Date is in UTC
    }

    /// Calculate Greenwich Mean Sidereal Time
    public func greenwichSiderealTime() -> Double {
        // Returns GMST in radians
        // Uses IAU 1982 formula
    }
}
```

### Julian Day Calculation

```swift
let date = Date()  // Current time in UTC
let jd = date.julianDay()

print("Julian Day: \(jd)")
// Example output: Julian Day: 2460311.75
```

### GMST Calculation

```swift
let date = Date()
let gmst = date.greenwichSiderealTime()  // Radians

// Convert to degrees for display
let gmstDegrees = gmst * 180.0 / .pi

print("GMST: \(gmstDegrees)°")
// Example output: GMST: 245.6°
```

### Usage in Coordinate Transform

```swift
import Ephemeris

let tle = try TwoLineElement(from: tleString)
let orbit = Orbit(from: tle)

// Calculate position at specific time
let time = Date()
let position = try orbit.calculatePosition(at: time)

// Internally, this:
// 1. Calculates JD from time
// 2. Propagates orbit in ECI
// 3. Calculates GMST using JD
// 4. Rotates ECI → ECEF using GMST
// 5. Converts ECEF → Geodetic

print("Lat: \(position.latitude)°, Lon: \(position.longitude)°")
```

### Precision Trade-offs

**Ephemeris simplifications**:
- Uses UTC as approximation for UT1 (ignores DUT1)
- Uses simplified GMST formula (omits high-order terms for recent dates)
- Accuracy: ~1-2 arcseconds in Earth rotation angle
- Position error: ~50-100 m for LEO satellites

**Acceptable for**:
- Hobbyist satellite tracking
- Amateur radio communications
- Educational demonstrations

**Not suitable for**:
- Mission operations (use full IERS conventions)
- Laser ranging (requires millimeter accuracy)
- High-precision orbit determination

---

## See Also

**Learning Path**:
- **Previous**: [Coordinate Transformations](coordinate-transformations.md) - Rotation matrices and transformation mathematics

**Related Coordinate Systems**:
- [Inertial Frames](inertial-frames.md) - ECI system and J2000.0 epoch
- [Earth-Fixed Frames](earth-fixed-frames.md) - ECEF and geodetic coordinates
- [Observer Frames](observer-frames.md) - ENU and horizontal coordinates

**Practical Guides**:
- [Observer Geometry](observer-geometry.md) - Swift implementation with examples
- [Orbital Elements](orbital-elements.md) - Using time in orbital propagation
- [Getting Started](getting-started.md) - Build satellite tracker app

---

## References

1. **Aoki, S., Guinot, B., Kaplan, G.H., Kinoshita, H., McCarthy, D.D., and Seidelmann, P.K.** (1982). "The New Definition of Universal Time." *Astronomy and Astrophysics*, 105, 359-361.
   - Original IAU 1982 GMST formula
   - Fundamental reference for sidereal time

2. **Meeus, Jean.** (1998). *Astronomical Algorithms* (2nd Edition). Willmann-Bell, Inc.
   - Chapter 7: Julian Day
   - Chapter 12: Sidereal Time
   - Practical computational algorithms

3. **Vallado, David A.** (2013). *Fundamentals of Astrodynamics and Applications* (4th Edition). Microcosm Press.
   - Section 3.4: Time Systems
   - Section 3.5: Sidereal Time calculations
   - Complete treatment of all time scales

4. **Seidelmann, P. Kenneth (ed.).** (1992). *Explanatory Supplement to the Astronomical Almanac*. University Science Books.
   - Chapter 2: Time
   - Definitive reference for astronomical time systems

5. **McCarthy, Dennis D., and Seidelmann, P. Kenneth.** (2009). *TIME: From Earth Rotation to Atomic Physics*. Wiley-VCH.
   - Comprehensive history and theory of time systems
   - TAI, UTC, UT1 relationships

6. **IERS Conventions (2010).** Petit, G., and Luzum, B. (eds.), IERS Technical Note No. 36.
   - Modern standards for time transformations
   - DUT1, leap seconds, high-precision GMST
   - Available: https://www.iers.org/IERS/EN/Publications/TechnicalNotes/tn36.html

7. **USNO Circular 179.** Kaplan, G.H. (2005). "The IAU Resolutions on Astronomical Reference Systems, Time Scales, and Earth Rotation Models."
   - Explanation of IAU resolutions
   - Practical guidance on time systems

8. **BIPM (Bureau International des Poids et Mesures).** "Time Department."
   - TAI and UTC official definitions
   - Leap second announcements
   - Available: https://www.bipm.org/en/time-frequency

### Diagrams

![Sidereal vs Solar Day](https://upload.wikimedia.org/wikipedia/commons/8/8b/Sidereal_day_%28prograde%29.svg)
*Figure 1: Comparison of sidereal day and solar day for a prograde planet like Earth. The diagram shows Earth's rotation relative to distant stars (sidereal day = 23h 56m 04s) versus rotation relative to the Sun (solar day = 24h 00m 00s). The ~4 minute difference arises from Earth's orbital motion around the Sun - after one complete rotation relative to the stars, Earth must rotate slightly more to bring the Sun back to the same position. Source: Gdr/Chris828, [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Sidereal_day_(prograde).svg), licensed under [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).*

---

*This documentation is part of the [Ephemeris](https://github.com/mvdmakesthings/Ephemeris) framework for satellite tracking in Swift.*

**Last Updated**: October 20, 2025
**Version**: 1.0
