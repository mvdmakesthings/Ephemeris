# Coordinate Transformation Mathematics

> **Brief Description**: Complete mathematical treatment of coordinate transformations for satellite tracking, including rotation matrices, derivations, and the full transformation pipeline from orbital elements to observer coordinates.

## Overview

This document provides the **mathematical foundation** for all coordinate transformations used in satellite tracking. While other documents explain individual coordinate systems, this reference shows how to transform between them using rotation matrices and provides complete derivations.

**Math-Heavy Approach**: This is the most mathematical document in the Ephemeris documentation suite. We derive transformation matrices from first principles, provide complete algorithms, and discuss numerical considerations.

**What You'll Learn:**
- 3D rotation matrix theory and properties
- Elementary rotations (Rx, Ry, Rz) with full derivations
- Complete transformation chain: Orbital Plane → ECI → ECEF → ENU → Horizontal
- Geodetic coordinate conversion algorithms
- Velocity transformations in rotating frames
- Numerical stability and precision requirements
- Matrix composition and optimization

---

## Table of Contents

- [Rotation Matrix Fundamentals](#rotation-matrix-fundamentals)
- [Elementary Rotations](#elementary-rotations)
- [Matrix Composition](#matrix-composition)
- [Orbital Plane to ECI](#orbital-plane-to-eci)
- [ECI to ECEF Transformation](#eci-to-ecef-transformation)
- [ECEF to Geodetic Conversion](#ecef-to-geodetic-conversion)
- [ECEF to ENU Transformation](#ecef-to-enu-transformation)
- [ENU to Horizontal Coordinates](#enu-to-horizontal-coordinates)
- [Complete Transformation Pipeline](#complete-transformation-pipeline)
- [Velocity Transformations](#velocity-transformations)
- [Numerical Considerations](#numerical-considerations)
- [See Also](#see-also)
- [References](#references)

---

## Rotation Matrix Fundamentals

### Definition

A **rotation matrix** $\mathbf{R}$ is a linear transformation that rotates vectors in 3D space while preserving:
- Vector lengths (magnitudes)
- Angles between vectors
- Orientation (right-handedness)

**Mathematical definition**: $\mathbf{R}$ rotates vector $\mathbf{v}$ to $\mathbf{v}'$:
$$
\mathbf{v}' = \mathbf{R}\mathbf{v}
$$

### Properties

**1. Orthogonality**:
$$
\mathbf{R}^T \mathbf{R} = \mathbf{R} \mathbf{R}^T = \mathbf{I}
$$

where $\mathbf{R}^T$ is the transpose and $\mathbf{I}$ is the identity matrix.

**2. Inverse = Transpose**:
$$
\mathbf{R}^{-1} = \mathbf{R}^T
$$

This makes inverse rotations computationally cheap (just transpose).

**3. Determinant = +1**:
$$
\det(\mathbf{R}) = +1
$$

This ensures the rotation preserves orientation (right-handed → right-handed).

**4. Preserve Dot Product**:
$$
(\mathbf{R}\mathbf{u}) \cdot (\mathbf{R}\mathbf{v}) = \mathbf{u} \cdot \mathbf{v}
$$

**5. Preserve Cross Product**:
$$
\mathbf{R}(\mathbf{u} \times \mathbf{v}) = (\mathbf{R}\mathbf{u}) \times (\mathbf{R}\mathbf{v})
$$

### Geometric Interpretation

A rotation can be specified by:
- **Axis of rotation**: Unit vector $\hat{\mathbf{n}}$
- **Angle of rotation**: $\theta$ (radians), using right-hand rule

**Positive rotation**: If thumb points along axis, fingers curl in positive rotation direction.

---

## Elementary Rotations

### Rotation About X-Axis

Rotates vectors in the YZ-plane by angle $\theta$:

$$
\mathbf{R}_x(\theta) = \begin{bmatrix}
1 & 0 & 0 \\
0 & \cos(\theta) & \sin(\theta) \\
0 & -\sin(\theta) & \cos(\theta)
\end{bmatrix}
$$

**Derivation**:
- X-component unchanged
- Y and Z components rotate in YZ-plane
- Counterclockwise rotation when looking from positive X toward origin

**Example** ($\theta = 90°$):
$$
\mathbf{R}_x(90°) = \begin{bmatrix}
1 & 0 & 0 \\
0 & 0 & 1 \\
0 & -1 & 0
\end{bmatrix}
$$

This maps: $(1,0,0) \to (1,0,0)$, $(0,1,0) \to (0,0,-1)$, $(0,0,1) \to (0,1,0)$

### Rotation About Y-Axis

Rotates vectors in the ZX-plane by angle $\theta$:

$$
\mathbf{R}_y(\theta) = \begin{bmatrix}
\cos(\theta) & 0 & -\sin(\theta) \\
0 & 1 & 0 \\
\sin(\theta) & 0 & \cos(\theta)
\end{bmatrix}
$$

**Note**: The sign pattern differs from $\mathbf{R}_x$ and $\mathbf{R}_z$ due to right-hand rule and cyclic permutation.

**Derivation**:
- Y-component unchanged
- X and Z components rotate in ZX-plane
- Counterclockwise rotation when looking from positive Y toward origin

### Rotation About Z-Axis

Rotates vectors in the XY-plane by angle $\theta$:

$$
\mathbf{R}_z(\theta) = \begin{bmatrix}
\cos(\theta) & \sin(\theta) & 0 \\
-\sin(\theta) & \cos(\theta) & 0 \\
0 & 0 & 1
\end{bmatrix}
$$

**Derivation**:
- Z-component unchanged
- X and Y components rotate in XY-plane
- Counterclockwise rotation when looking from positive Z toward origin

**Example** ($\theta = 45°$):
$$
\mathbf{R}_z(45°) = \begin{bmatrix}
0.7071 & 0.7071 & 0 \\
-0.7071 & 0.7071 & 0 \\
0 & 0 & 1
\end{bmatrix}
$$

### Sign Conventions

**IMPORTANT**: Different fields use different conventions:

**Aerospace** (used in Ephemeris):
- Positive rotation = right-hand rule about axis
- Matrices as shown above

**Some geodesy texts**:
- May use opposite sign convention
- May define rotation of coordinate system (passive) vs rotation of vector (active)

**Always verify convention** when comparing with other sources.

---

## Matrix Composition

### Sequential Rotations

**Order matters**: Rotations do not commute
$$
\mathbf{R}_x(\alpha) \mathbf{R}_y(\beta) \neq \mathbf{R}_y(\beta) \mathbf{R}_x(\alpha)
$$

**Composition**: To apply rotation $\mathbf{R}_1$ followed by $\mathbf{R}_2$:
$$
\mathbf{v}'' = \mathbf{R}_2(\mathbf{R}_1 \mathbf{v}) = (\mathbf{R}_2 \mathbf{R}_1) \mathbf{v}
$$

**Combined matrix**:
$$
\mathbf{R}_{combined} = \mathbf{R}_2 \mathbf{R}_1
$$

**Read right-to-left**: First apply $\mathbf{R}_1$, then $\mathbf{R}_2$

### Example: Two Z-Rotations

Rotate by $\alpha$ then $\beta$ about Z:
$$
\mathbf{R}_z(\beta) \mathbf{R}_z(\alpha) = \mathbf{R}_z(\alpha + \beta)
$$

**Proof**:
$$
\begin{bmatrix}
\cos\beta & \sin\beta & 0 \\
-\sin\beta & \cos\beta & 0 \\
0 & 0 & 1
\end{bmatrix}
\begin{bmatrix}
\cos\alpha & \sin\alpha & 0 \\
-\sin\alpha & \cos\alpha & 0 \\
0 & 0 & 1
\end{bmatrix}
=
\begin{bmatrix}
\cos(\alpha+\beta) & \sin(\alpha+\beta) & 0 \\
-\sin(\alpha+\beta) & \cos(\alpha+\beta) & 0 \\
0 & 0 & 1
\end{bmatrix}
$$

This is a special property of rotations about the **same axis**.

### Euler Angles

**Euler angles** describe any 3D rotation as three sequential rotations about specified axes.

**Common sequences**:
- **ZYZ**: Aerospace (α, β, γ)
- **ZYX**: Robotics (yaw, pitch, roll)
- **XYZ**: Some geodesy applications

For satellite tracking, we use specific sequences for each transformation (not general Euler angles).

---

## Orbital Plane to ECI

### The Problem

**Given**: Satellite position in its orbital plane (using true anomaly $\nu$ and radius $r$)

**Find**: Position vector in ECI coordinates

**Orbital elements**:
- $i$ = inclination
- $\Omega$ = right ascension of ascending node (RAAN)
- $\omega$ = argument of perigee

### Position in Orbital Plane

In the orbital plane coordinate system (perifocal frame):
- X-axis points toward perigee
- Z-axis perpendicular to orbital plane (along angular momentum)

**Position**:
$$
\mathbf{r}_{orbital} = \begin{bmatrix} r\cos\nu \\ r\sin\nu \\ 0 \end{bmatrix}
$$

where:
$$
r = \frac{a(1-e^2)}{1 + e\cos\nu}
$$

### Transformation Sequence

Transform orbital plane to ECI via three rotations:

**Step 1**: Rotate by $\omega$ about Z-axis (align perigee)

**Step 2**: Rotate by $i$ about X-axis (tilt orbital plane)

**Step 3**: Rotate by $\Omega$ about Z-axis (orient ascending node)

### Combined Rotation Matrix

$$
\mathbf{R}_{orbital \to ECI} = \mathbf{R}_z(\Omega) \cdot \mathbf{R}_x(i) \cdot \mathbf{R}_z(\omega)
$$

**Full expansion**:
$$
\mathbf{R} = \begin{bmatrix}
\cos\Omega\cos\omega - \sin\Omega\sin\omega\cos i & -\cos\Omega\sin\omega - \sin\Omega\cos\omega\cos i & \sin\Omega\sin i \\
\sin\Omega\cos\omega + \cos\Omega\sin\omega\cos i & -\sin\Omega\sin\omega + \cos\Omega\cos\omega\cos i & -\cos\Omega\sin i \\
\sin\omega\sin i & \cos\omega\sin i & \cos i
\end{bmatrix}
$$

### ECI Position Vector

$$
\mathbf{r}_{ECI} = \mathbf{R}_{orbital \to ECI} \cdot \mathbf{r}_{orbital}
$$

Expanded:
$$
\mathbf{r}_{ECI} = \begin{bmatrix}
r[\cos\Omega(\cos\omega\cos\nu - \sin\omega\sin\nu) - \sin\Omega(\sin\omega\cos\nu + \cos\omega\sin\nu)\cos i] \\
r[\sin\Omega(\cos\omega\cos\nu - \sin\omega\sin\nu) + \cos\Omega(\sin\omega\cos\nu + \cos\omega\sin\nu)\cos i] \\
r(\sin\omega\cos\nu + \cos\omega\sin\nu)\sin i
\end{bmatrix}
$$

**Simplified using** $u = \omega + \nu$ (argument of latitude):
$$
\mathbf{r}_{ECI} = r \begin{bmatrix}
\cos\Omega\cos u - \sin\Omega\sin u\cos i \\
\sin\Omega\cos u + \cos\Omega\sin u\cos i \\
\sin u\sin i
\end{bmatrix}
$$

---

## ECI to ECEF Transformation

### The Rotation

The ECEF frame rotates with Earth. The transformation is a **single rotation about the Z-axis** by the Greenwich Mean Sidereal Time (GMST):

$$
\mathbf{r}_{ECEF} = \mathbf{R}_z(\theta_{GMST}) \cdot \mathbf{r}_{ECI}
$$

### Rotation Matrix

$$
\mathbf{R}_{ECI \to ECEF} = \mathbf{R}_z(\theta_{GMST}) = \begin{bmatrix}
\cos\theta_{GMST} & \sin\theta_{GMST} & 0 \\
-\sin\theta_{GMST} & \cos\theta_{GMST} & 0 \\
0 & 0 & 1
\end{bmatrix}
$$

where $\theta_{GMST}$ is the Greenwich Mean Sidereal Time angle (see [Time Systems](time-systems.md) for calculation).

### Expanded Transformation

$$
\begin{bmatrix} X_{ECEF} \\ Y_{ECEF} \\ Z_{ECEF} \end{bmatrix} = \begin{bmatrix}
\cos\theta & \sin\theta & 0 \\
-\sin\theta & \cos\theta & 0 \\
0 & 0 & 1
\end{bmatrix}
\begin{bmatrix} X_{ECI} \\ Y_{ECI} \\ Z_{ECI} \end{bmatrix}
$$

Result:
$$
X_{ECEF} = X_{ECI}\cos\theta + Y_{ECI}\sin\theta
$$
$$
Y_{ECEF} = -X_{ECI}\sin\theta + Y_{ECI}\cos\theta
$$
$$
Z_{ECEF} = Z_{ECI}
$$

**Physical interpretation**: The Z-axes coincide (both point to North Pole). The X and Y axes rotate as Earth spins.

### Inverse Transformation

To go from ECEF back to ECI, use the inverse (transpose):

$$
\mathbf{r}_{ECI} = \mathbf{R}_{ECI \to ECEF}^T \cdot \mathbf{r}_{ECEF} = \mathbf{R}_z(-\theta_{GMST}) \cdot \mathbf{r}_{ECEF}
$$

---

## ECEF to Geodetic Conversion

### Forward: Geodetic → ECEF

**Given**: $(\phi, \lambda, h)$ = (latitude, longitude, height)

**Find**: $(X, Y, Z)$ in ECEF

**Closed-form solution** (see [Earth-Fixed Frames](earth-fixed-frames.md)):

**Step 1**: Calculate radius of curvature
$$
N(\phi) = \frac{a}{\sqrt{1 - e^2\sin^2\phi}}
$$

**Step 2**: Apply formulas
$$
X = (N(\phi) + h)\cos\phi\cos\lambda
$$
$$
Y = (N(\phi) + h)\cos\phi\sin\lambda
$$
$$
Z = (N(\phi)(1-e^2) + h)\sin\phi
$$

### Inverse: ECEF → Geodetic

**Given**: $(X, Y, Z)$ in ECEF

**Find**: $(\phi, \lambda, h)$

**No closed-form solution** – requires iteration.

### Bowring's Algorithm (1976)

**Most efficient iterative method**:

**Step 1**: Longitude (direct)
$$
\lambda = \arctan2(Y, X)
$$

**Step 2**: Calculate auxiliary values
$$
p = \sqrt{X^2 + Y^2}
$$
$$
\theta = \arctan\left(\frac{Za}{pb}\right)
$$

**Step 3**: Initial latitude estimate
$$
\phi = \arctan\left(\frac{Z + e'^2 b\sin^3\theta}{p - e^2 a\cos^3\theta}\right)
$$

where:
- $e^2 = \frac{a^2 - b^2}{a^2}$ (first eccentricity squared)
- $e'^2 = \frac{a^2 - b^2}{b^2}$ (second eccentricity squared)
- $a = 6378137$ m (WGS-84 semi-major axis)
- $b = 6356752.314245$ m (WGS-84 semi-minor axis)

**Step 4**: Calculate radius of curvature
$$
N(\phi) = \frac{a}{\sqrt{1 - e^2\sin^2\phi}}
$$

**Step 5**: Calculate height
$$
h = \frac{p}{\cos\phi} - N(\phi)
$$

**Convergence**: Typically accurate to < 1 mm in **one iteration**.

### Alternative: Fixed-Point Iteration

More iterations but simpler:

**Initialize**:
$$
\phi_0 = \arctan\left(\frac{Z}{p(1-e^2)}\right)
$$

**Iterate** until $|\phi_{n+1} - \phi_n| < \epsilon$:
$$
N_n = \frac{a}{\sqrt{1-e^2\sin^2\phi_n}}
$$
$$
h_n = \frac{p}{\cos\phi_n} - N_n
$$
$$
\phi_{n+1} = \arctan\left(\frac{Z}{p\left(1 - \frac{e^2 N_n}{N_n + h_n}\right)}\right)
$$

**Convergence**: 2-3 iterations for $\epsilon = 10^{-12}$ radians (< 1 mm).

---

## ECEF to ENU Transformation

### Relative Position

**First**, compute relative position (satellite - observer):

$$
\Delta\mathbf{r} = \mathbf{r}_{sat} - \mathbf{r}_{obs} = \begin{bmatrix} \Delta X \\ \Delta Y \\ \Delta Z \end{bmatrix}_{ECEF}
$$

### Two-Step Rotation

Transform to ENU via two rotations:

**Step 1**: Rotate by $-\lambda$ about Z (align with meridian)

**Step 2**: Rotate by $(90° - \phi)$ about Y (align with local vertical)

### Combined Matrix

$$
\mathbf{R}_{ECEF \to ENU} = \mathbf{R}_y(90° - \phi) \cdot \mathbf{R}_z(-\lambda)
$$

**Expanded**:
$$
\mathbf{R}_{ECEF \to ENU} = \begin{bmatrix}
-\sin\lambda & \cos\lambda & 0 \\
-\sin\phi\cos\lambda & -\sin\phi\sin\lambda & \cos\phi \\
\cos\phi\cos\lambda & \cos\phi\sin\lambda & \sin\phi
\end{bmatrix}
$$

### ENU Coordinates

$$
\begin{bmatrix} E \\ N \\ U \end{bmatrix} = \mathbf{R}_{ECEF \to ENU} \begin{bmatrix} \Delta X \\ \Delta Y \\ \Delta Z \end{bmatrix}
$$

**Expanded**:
$$
E = -\Delta X\sin\lambda + \Delta Y\cos\lambda
$$
$$
N = -\Delta X\sin\phi\cos\lambda - \Delta Y\sin\phi\sin\lambda + \Delta Z\cos\phi
$$
$$
U = \Delta X\cos\phi\cos\lambda + \Delta Y\cos\phi\sin\lambda + \Delta Z\sin\phi
$$

### Derivation Detail

**Step 1**: $\mathbf{R}_z(-\lambda)$ rotates about Z-axis to align X-axis with local meridian

After this rotation:
- X-axis points through observer's meridian
- Y-axis points 90° east
- Z-axis unchanged

**Step 2**: $\mathbf{R}_y(90° - \phi)$ rotates about (new) Y-axis to align Z-axis with local vertical

After this rotation:
- X-axis points east (perpendicular to meridian)
- Y-axis unchanged (points north)
- Z-axis points up (local zenith)

But we want E-N-U order, so we permute rows to get final matrix.

---

## ENU to Horizontal Coordinates

### Spherical Transformation

Convert Cartesian ENU to spherical (azimuth, elevation, range):

**Range**:
$$
\rho = \sqrt{E^2 + N^2 + U^2}
$$

**Azimuth** (from north, clockwise):
$$
A = \arctan2(E, N)
$$

Convert to $[0°, 360°)$ if needed:
$$
A = \begin{cases}
\arctan2(E, N) & \text{if } \arctan2(E, N) \geq 0 \\
\arctan2(E, N) + 360° & \text{if } \arctan2(E, N) < 0
\end{cases}
$$

**Elevation** (angle above horizon):
$$
El = \arcsin\left(\frac{U}{\rho}\right)
$$

Alternatively:
$$
El = \arctan\left(\frac{U}{\sqrt{E^2 + N^2}}\right)
$$

### Zenith Angle

Alternative to elevation:
$$
z = 90° - El = \arccos\left(\frac{U}{\rho}\right)
$$

### Inverse: Horizontal → ENU

Given $(A, El, \rho)$, recover ENU:

$$
E = \rho \cos(El) \sin(A)
$$
$$
N = \rho \cos(El) \cos(A)
$$
$$
U = \rho \sin(El)
$$

---

## Complete Transformation Pipeline

### Satellite Position: TLE → Observer Horizontal

**Full pipeline** for calculating where to point an antenna:

**Input**: TLE data, observer location, time

**Output**: Azimuth, elevation, range

### Step-by-Step

**1. Parse TLE** → Orbital elements $(a, e, i, \Omega, \omega, M_0, n)$

**2. Propagate mean anomaly**:
$$
M(t) = M_0 + n(t - t_0)
$$

**3. Solve Kepler's equation** for eccentric anomaly $E$:
$$
E - e\sin E = M
$$
(Newton-Raphson iteration)

**4. Calculate true anomaly** $\nu$:
$$
\nu = 2\arctan\left(\sqrt{\frac{1+e}{1-e}}\tan\frac{E}{2}\right)
$$

**5. Calculate radius**:
$$
r = \frac{a(1-e^2)}{1 + e\cos\nu}
$$

**6. Position in orbital plane**:
$$
\mathbf{r}_{orbital} = \begin{bmatrix} r\cos\nu \\ r\sin\nu \\ 0 \end{bmatrix}
$$

**7. Transform to ECI**:
$$
\mathbf{r}_{ECI} = \mathbf{R}_z(\Omega) \mathbf{R}_x(i) \mathbf{R}_z(\omega) \mathbf{r}_{orbital}
$$

**8. Calculate GMST** $\theta(t)$ (see [Time Systems](time-systems.md))

**9. Transform to ECEF**:
$$
\mathbf{r}_{sat,ECEF} = \mathbf{R}_z(\theta) \mathbf{r}_{ECI}
$$

**10. Observer position in ECEF**:
$$
\mathbf{r}_{obs,ECEF} = \text{GeodeticToECEF}(\phi_{obs}, \lambda_{obs}, h_{obs})
$$

**11. Relative position**:
$$
\Delta\mathbf{r}_{ECEF} = \mathbf{r}_{sat,ECEF} - \mathbf{r}_{obs,ECEF}
$$

**12. Transform to ENU**:
$$
\begin{bmatrix} E \\ N \\ U \end{bmatrix} = \mathbf{R}_{ECEF \to ENU}(\phi_{obs}, \lambda_{obs}) \Delta\mathbf{r}_{ECEF}
$$

**13. Calculate horizontal coordinates**:
$$
A = \arctan2(E, N), \quad El = \arcsin(U/\rho), \quad \rho = \sqrt{E^2+N^2+U^2}
$$

### Matrix Pre-Computation

For **real-time tracking**, pre-compute time-independent matrices:

**Pre-compute once**:
- $\mathbf{R}_{orbital \to ECI} = \mathbf{R}_z(\Omega) \mathbf{R}_x(i) \mathbf{R}_z(\omega)$ (depends on orbital elements)
- $\mathbf{R}_{ECEF \to ENU} = f(\phi_{obs}, \lambda_{obs})$ (depends on observer)

**Update each time step**:
- $\mathbf{R}_{ECI \to ECEF} = \mathbf{R}_z(\theta_{GMST}(t))$ (depends on time)

**Combine**:
$$
\mathbf{r}_{ENU} = \mathbf{R}_{ECEF \to ENU} \cdot \mathbf{R}_{ECI \to ECEF}(t) \cdot \mathbf{R}_{orbital \to ECI} \cdot \mathbf{r}_{orbital}(\nu(t)) - \mathbf{r}_{obs,ENU}
$$

---

## Velocity Transformations

### Rotating Frame Dynamics

In a **rotating frame** (like ECEF), velocity transformations require additional terms:

$$
\mathbf{v}_{ECEF} = \mathbf{R}_{ECI \to ECEF} \mathbf{v}_{ECI} + \boldsymbol{\omega}_\oplus \times \mathbf{r}_{ECEF}
$$

where $\boldsymbol{\omega}_\oplus = (0, 0, \omega_\oplus)$ is Earth's angular velocity vector.

### Earth's Angular Velocity

$$
\omega_\oplus = 7.2921159 \times 10^{-5} \text{ rad/s}
$$

### Cross Product Term

The term $\boldsymbol{\omega}_\oplus \times \mathbf{r}_{ECEF}$ accounts for the motion of the ECEF frame itself:

$$
\boldsymbol{\omega}_\oplus \times \mathbf{r}_{ECEF} = \begin{vmatrix}
\hat{\mathbf{i}} & \hat{\mathbf{j}} & \hat{\mathbf{k}} \\
0 & 0 & \omega_\oplus \\
X & Y & Z
\end{vmatrix} = \begin{bmatrix} -\omega_\oplus Y \\ \omega_\oplus X \\ 0 \end{bmatrix}
$$

### Complete Velocity Transformation

**ECI → ECEF**:
$$
\mathbf{v}_{ECEF} = \mathbf{R}_z(\theta_{GMST}) \mathbf{v}_{ECI} + \begin{bmatrix} -\omega_\oplus Y_{ECEF} \\ \omega_\oplus X_{ECEF} \\ 0 \end{bmatrix}
$$

**ECEF → ECI**:
$$
\mathbf{v}_{ECI} = \mathbf{R}_z(-\theta_{GMST}) \left(\mathbf{v}_{ECEF} - \begin{bmatrix} -\omega_\oplus Y_{ECEF} \\ \omega_\oplus X_{ECEF} \\ 0 \end{bmatrix}\right)
$$

### Range Rate Calculation

**Range rate** (radial velocity) from observer to satellite:

$$
\dot{\rho} = \frac{\Delta\mathbf{r} \cdot \Delta\mathbf{v}}{|\Delta\mathbf{r}|}
$$

where:
- $\Delta\mathbf{r} = \mathbf{r}_{sat} - \mathbf{r}_{obs}$ (relative position)
- $\Delta\mathbf{v} = \mathbf{v}_{sat} - \mathbf{v}_{obs}$ (relative velocity)

Both must be in the **same coordinate frame** (typically ECEF).

---

## Numerical Considerations

### Floating-Point Precision

**Use double precision** (64-bit) for all calculations:
- Single precision (32-bit) insufficient for sub-meter accuracy
- Positions: ±6,378,137 m requires ~23 bits just for integer part
- Need ~10 decimal digits for millimeter accuracy

### Angle Representation

**Internal**: Use **radians** for all calculations

**I/O**: Convert to/from degrees for user input/output

**Conversion**:
$$
\text{radians} = \text{degrees} \times \frac{\pi}{180}
$$

### Small Angle Approximations

**Avoid** small angle approximations unless:
- Performance is critical
- Error bounds are proven acceptable

**Example**: $\sin\theta \approx \theta$ is accurate to 1% for $\theta < 14°$, but breaks down for larger angles.

### Matrix Singularities

**Gimbal lock**: Occurs when two rotation axes align

**For orbital mechanics**:
- Equatorial orbits ($i \approx 0°$): RAAN undefined
- Circular orbits ($e \approx 0$): Argument of perigee undefined

**Solution**: Use Cartesian state vectors when near singularities

### Iterative Convergence

**Kepler's equation** (Newton-Raphson):
- Tolerance: $10^{-12}$ radians (~10 nm in position)
- Maximum iterations: 50 (safety limit)
- Typical: 3-5 iterations for $e < 0.1$

**ECEF → Geodetic** (Bowring):
- Usually converges in **1 iteration** to < 1 mm
- For safety, allow up to 5 iterations

### Avoiding Catastrophic Cancellation

**Example**: $\sqrt{1 - e^2}$ for near-circular orbits

**Problem**: If $e$ is very small, $1 - e^2 \approx 1$ loses precision

**Solution**: Use Taylor series or reformulate:
$$
\sqrt{1-e^2} = \sqrt{(1-e)(1+e)}
$$

### Quaternions vs Rotation Matrices

**Rotation matrices**:
- ✅ Intuitive, easy to derive
- ✅ Direct composition via multiplication
- ❌ 9 numbers (6 redundant due to orthogonality)
- ❌ Accumulation of numerical errors in composition

**Quaternions**:
- ✅ 4 numbers (more compact)
- ✅ More numerically stable for long chains
- ❌ Less intuitive
- ❌ Requires normalization

**For satellite tracking**: Rotation matrices are sufficient. Quaternions are overkill unless composing 100s of rotations.

---

## See Also

**Learning Path**:
- **Previous**: [Observer Frames](observer-frames.md) - ENU and horizontal coordinates
- **Next**: [Time Systems](time-systems.md) - GMST and Julian Day calculations

**Coordinate Systems**:
- [Inertial Frames](inertial-frames.md) - ECI system definition
- [Earth-Fixed Frames](earth-fixed-frames.md) - ECEF and geodetic coordinates

**Practical Implementation**:
- [Observer Geometry](observer-geometry.md) - Swift implementation with code examples
- [Orbital Elements](orbital-elements.md) - Kepler's equation and orbital mechanics

---

## References

1. **Vallado, David A.** (2013). *Fundamentals of Astrodynamics and Applications* (4th Edition). Microcosm Press.
   - Chapter 3: Coordinate and Time Systems
   - Section 3.7: Coordinate System Transformations
   - Complete derivations of all transformation matrices

2. **Montenbruck, Oliver, and Gill, Eberhard.** (2000). *Satellite Orbits: Models, Methods and Applications*. Springer.
   - Section 2.2: Coordinate Systems
   - Section 5.4: Topocentric Coordinates

3. **Koks, Don.** (2006). "Using Rotations to Build Aerospace Coordinate Systems." Defence Science and Technology Organisation, DTIC Document ADA484864.
   - Detailed treatment of rotation matrices
   - Aerospace coordinate system construction
   - Available: https://apps.dtic.mil/sti/tr/pdf/ADA484864.pdf

4. **Bowring, B.R.** (1976). "Transformation from spatial to geographical coordinates." *Survey Review*, 23(181), 323-327.
   - Original Bowring algorithm
   - ECEF to geodetic conversion

5. **ESA Navipedia.** (2024). "Transformations between ECEF and ENU coordinates."
   - Detailed ENU transformation formulas
   - Available: https://gssc.esa.int/navipedia/

6. **Shuster, Malcolm D.** (1993). "A Survey of Attitude Representations." *The Journal of the Astronautical Sciences*, 41(4), 439-517.
   - Comprehensive review of rotation representations
   - Rotation matrices, Euler angles, quaternions

7. **Zhu, J.** (1994). "Conversion of Earth-centered Earth-fixed coordinates to geodetic coordinates." *IEEE Transactions on Aerospace and Electronic Systems*, 30(3), 957-961.
   - Alternative closed-form methods for ECEF → Geodetic
   - Accuracy comparisons

### Diagrams

**Coordinate Transformation Pipeline:**

The complete transformation sequence from orbital elements to observer horizontal coordinates:

```
TLE Data
   ↓
Orbital Elements (a, e, i, Ω, ω, M₀, n)
   ↓
[Kepler's Equation] → Eccentric Anomaly (E) → True Anomaly (ν)
   ↓
Position in Orbital Plane (r, ν)
   ↓
[R_z(Ω) · R_x(i) · R_z(ω)] → ECI Coordinates (X_ECI, Y_ECI, Z_ECI)
   ↓
[R_z(GMST)] → ECEF Coordinates (X_ECEF, Y_ECEF, Z_ECEF)
   ↓
[Iterative Algorithm] → Geodetic Coordinates (φ, λ, h)
   ├─→ Display on map (latitude, longitude, altitude)
   └─→ [R_ECEF→ENU(φ_obs, λ_obs)] → ENU Coordinates (E, N, U)
        ↓
   [Spherical Conversion] → Horizontal Coordinates (Az, El, Range)
        ↓
   Antenna pointing / Pass prediction
```

*Each transformation step uses the mathematical formulas detailed in the sections above. See [Observer Geometry](observer-geometry.md) for the Swift implementation of this complete pipeline.*

---

*This documentation is part of the [Ephemeris](https://github.com/mvdmakesthings/Ephemeris) framework for satellite tracking in Swift.*

**Last Updated**: October 20, 2025
**Version**: 1.0
