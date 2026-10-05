# Working With Whole Catalogs

> **Brief Description**: Load thousands of satellites at once, ask "where is everything?" and "what is overhead?", find every pass over an observer, and understand the geometry and concurrency that make it fast.

## Overview

Tracking one satellite is a matter of building an `SGP4` propagator and asking it questions. Real apps often need the opposite: start from *everything* and narrow down. Which satellites are above my horizon right now? What passes over my antenna in the next hour? Where should every dot go on a world map?

`SatelliteCatalog` answers those questions for thousands of satellites at once, using every CPU core. This guide covers how to load one, what each query does, the geometric filter that skips satellites you could never see, and how to get catalog data without abusing the public servers that provide it.

**What you'll learn:**
- Loading a catalog from TLE or OMM documents, and what happens to bad entries
- Whole-catalog queries: positions, look angles and passes
- Why some satellites can never rise for an observer, and how to test that cheaply
- How the work is spread across CPU cores without changing the results
- How fast it is, and how to fetch data responsibly

---

## Table of Contents

- [Loading a Catalog](#loading-a-catalog)
- [Whole-Catalog Queries](#whole-catalog-queries)
- [Which Satellites Can Ever Rise?](#which-satellites-can-ever-rise)
- [How the Work Is Spread Across Cores](#how-the-work-is-spread-across-cores)
- [Data Freshness](#data-freshness)
- [Performance](#performance)
- [Getting Catalog Data Responsibly](#getting-catalog-data-responsibly)
- [References](#references)

---

## Loading a Catalog

A catalog can be built from a TLE document, an OMM document in any encoding, or element sets you already have:

```swift
import Ephemeris

// A document of many TLEs, such as a CelesTrak group file (name lines optional)
let fromTLEs = SatelliteCatalog(tleText: tleDocument)

// An OMM document: JSON, XML, KVN or CSV (the encoding is detected)
let fromOMM = try SatelliteCatalog(omm: ommDocument)

// Element sets you already parsed
let mixed = SatelliteCatalog(elementSets: [issTLE, someOMM])
```

Every satellite gets its own `SGP4` propagator, so anything you can do with one satellite works on a catalog entry too:

```swift
if let iss = catalog[catalogNumber: 25544] {
    let lookAngles = try iss.propagator.topocentric(at: Date(), for: observer)
}
```

### Bad Entries Don't Stop the Load

A catalog of thousands of element sets will occasionally contain one that can't be used: a corrupted checksum, a decayed object, an SGP4-XP element set, or the same satellite twice. None of these are fatal. The usable satellites load normally, and the rest are listed in `rejections` with a reason:

```swift
for rejection in catalog.rejections {
    print(rejection.catalogNumber ?? 0, rejection.reason)
}
```

| Reason | Meaning |
|--------|---------|
| `.invalidTLE` / `.invalidOMM` | The text could not be parsed |
| `.cannotPropagate` | SGP4 refused the elements (invalid, already decayed, or SGP4-XP) |
| `.superseded(byEpoch:)` | The same catalog number appeared again with a newer epoch, which was kept |

### Finding Satellites

```swift
let iss = catalog[catalogNumber: 25544]
let sameISS = catalog.satellite(internationalDesignator: "1998-067A")   // or "98067A"
let weather = catalog.satellites(named: "noaa")                          // case-insensitive
let geostationary = catalog.filter { $0.regime == .geosynchronous }
```

Each entry knows its broad orbit class (`regime`):

| Regime | Rule | Examples |
|--------|------|----------|
| `.lowEarth` | Apogee below 2,000 km | ISS, Starlink, weather satellites |
| `.mediumEarth` | Between low Earth orbit and geosynchronous | GPS, Galileo |
| `.geosynchronous` | About one revolution per sidereal day | Geostationary communications |
| `.highlyElliptical` | Eccentricity of 0.25 or more | Molniya, transfer orbits |
| `.highEarth` | Near circular, above geosynchronous | Graveyard orbits |

---

## Whole-Catalog Queries

All queries are `async`, because they run on every CPU core. Each one leaves out satellites that SGP4 cannot propagate to the requested time (for example, objects that would have decayed by then).

### Where Is Everything?

```swift
let positions = await catalog.positions(at: Date())
for item in positions {
    plot(item.position.latitudeDeg, item.position.longitudeDeg)   // your map code
}
```

`stateVectors(at:)` returns the raw TEME position and velocity instead.

### What Is Overhead?

```swift
let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
let overhead = await catalog.lookAngles(from: observer, at: Date(), minElevationDeg: 10)
for item in overhead {   // highest first
    print(item.satellite.name, item.topocentric.azimuthDeg, item.topocentric.elevationDeg)
}
```

### What Passes Over Me?

```swift
let now = Date()
let passes = await catalog.passes(for: observer, from: now, to: now.addingTimeInterval(3600),
                                  minElevationDeg: 10)
for item in passes {   // in order of rise time
    print(item.satellite.name, item.pass.aos.time, item.pass.culmination.elevationDeg)
}
```

Each result carries the full `PassWindow`, including the flags for passes cut off by the search window.

---

## Which Satellites Can Ever Rise?

Most of the cost of a pass search is propagating satellites over and over. Before doing that, `passes` and `lookAngles` ask a cheap geometric question: *could this orbit ever put the satellite above the minimum elevation for this observer?* If not, the satellite is skipped without propagating it at all.

### The Geometry

Two facts decide it.

**1. How far from the equator the satellite travels.** A satellite's ground track (the point directly beneath it) never goes farther north or south than the orbit's inclination `i`. For a retrograde orbit (`i > 90°`) the limit is `180° − i`. An equatorial orbit (`i ≈ 0°`) stays over the equator forever.

**2. How far the satellite can be seen from.** From altitude `h`, a satellite is above elevation `ε` for every observer within a certain distance of the point beneath it. Measured as an angle at Earth's center, that "visibility circle" has radius

```
λ = arccos( R⊕ · cos ε / (R⊕ + h) ) − ε
```

This comes from the triangle formed by Earth's center, the observer and the satellite: the line of sight leaves the observer at angle `ε` above the horizon, and the law of sines relates the angle at the satellite to `R⊕ / (R⊕ + h)`. Higher satellites have larger circles. A geostationary satellite (h ≈ 35,786 km) can be seen above the horizon within about 81° of the point beneath it, while the ISS (h ≈ 420 km) only covers about 20°.

Put together: an observer at latitude `φ` can only ever see the satellite if

```
|φ| ≤ i + λ
```

### Staying Safe

The filter must never skip a satellite that really can rise, so every choice leans toward keeping satellites:
- `λ` is computed at **apogee**, the highest point, where the visibility circle is largest
- Earth's **polar radius** is used, which makes `λ` slightly larger than with the equatorial radius
- A **1° margin** covers the difference between geodetic and geocentric latitude, small variations in the elements, and the observer's height
- For a **negative** minimum elevation the filter is switched off, because the circle keeps growing below the horizon

The test suite checks this directly: for hundreds of satellites and observers from the equator to 85°, every satellite the filter rejected is propagated for a full day, and none ever reaches the minimum elevation.

### When It Helps

The filter does the most for observers at high latitudes and for low-inclination orbits. Near the equator, or at mid latitudes where most orbits are inclined more than the observer's latitude, it keeps nearly everything. At 38° N, for example, it keeps about 98% of a typical catalog. It costs a few multiplications per satellite, so it never hurts.

---

## How the Work Is Spread Across Cores

Each whole-catalog query does the same independent calculation for every satellite, which makes it a natural fit for parallel work. Ephemeris uses Swift's structured concurrency (a task group).

A single SGP4 call takes around a microsecond, so creating one task per satellite would spend more time managing tasks than computing. Instead, the satellites are split into a few chunks per CPU core, and each task works through one chunk. The results are reassembled in chunk order, so the output is in catalog order and identical to a simple serial loop. The tests compare the two exactly.

This is safe because everything involved is an immutable value type marked `Sendable`: the catalog, each `SGP4` propagator, the observer and the results. No locks are needed.

---

## Data Freshness

SGP4 predictions get worse as you move away from the element set's epoch, by roughly 1-3 km per day in low Earth orbit. Each satellite reports how old its element set is:

```swift
let hours = satellite.age(at: Date()) / 3600
```

For antenna pointing, drop anything too old to trust:

```swift
let fresh = catalog.excludingStale(olderThan: 3 * 86400, at: Date())
```

---

## Performance

Measured on a synthetic 15,000-satellite catalog with a realistic mix of orbits, in a release build on 4 CPU cores:

| Operation | Time |
|-----------|------|
| Load catalog (15,000 SGP4 initializations) | 0.06 s |
| Positions of every satellite at one instant | 0.02 s |
| Look angles at one instant ("what's up") | 0.01 s |
| Every pass over one observer in 24 h (about 54,000 passes) | 4.1 s |

Instant queries are fast enough to run every frame of an animation. A full day of passes for the whole catalog takes a few seconds, so for interactive use, search a shorter window or a filtered catalog. A larger `stepSeconds` also helps: passes shorter than the step are still found.

To reproduce these numbers:

```bash
EPHEMERIS_BENCHMARK=1 swift test -c release --filter CatalogBenchmarkTests
```

---

## Getting Catalog Data Responsibly

`SatelliteCatalog` never downloads anything; you give it data. When your app does download element sets, remember that CelesTrak and Space-Track are run as a public service, and both block clients that download too much.

- **Download a group, not one satellite at a time.** One request for a group such as `GROUP=active` replaces thousands of single-satellite requests.
- **Download each group at most once per update cycle.** The data only changes a few times a day. Re-downloading unchanged data is the most common reason clients get blocked. An interval of a couple of hours is a sensible minimum.
- **Cache what you download** and load from the cache on every launch. Check the cache's age before going to the network.
- **Never download in a loop, on every screen refresh, or from tests.** Ephemeris' own tests use only local data: the verification files in the repository and a generated synthetic catalog.
- **For Space-Track,** follow its published usage policy and rate limits, and reuse a logged-in session instead of logging in per request.

```swift
import Foundation
import Ephemeris

/// Loads the active-satellite catalog, downloading at most once every two hours.
func loadCatalog(cacheURL: URL) async throws -> SatelliteCatalog {
    let maximumCacheAge: TimeInterval = 2 * 3600
    if let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
       let modified = attributes[.modificationDate] as? Date,
       Date().timeIntervalSince(modified) < maximumCacheAge,
       let cached = try? Data(contentsOf: cacheURL) {
        return try SatelliteCatalog(ommData: cached, format: .json)
    }

    let url = URL(string: "https://celestrak.org/NORAD/elements/gp.php?GROUP=active&FORMAT=JSON")!
    let (data, _) = try await URLSession.shared.data(from: url)
    try data.write(to: cacheURL)
    return try SatelliteCatalog(ommData: data, format: .json)
}
```

---

## References

- Wertz, Everett and Puschell (eds.), "Space Mission Engineering: The New SMAD" (2011), and Wertz and Larson, "Space Mission Analysis and Design" (3rd ed.), Section 5.2: Earth geometry viewed from space
- Vallado, "Fundamentals of Astrodynamics and Applications" (4th ed.), Section 11.2: site visibility
- CelesTrak, "GP Data Formats": https://celestrak.org/NORAD/documentation/gp-data-formats.php
- Space-Track.org, API usage policy: https://www.space-track.org/documentation
