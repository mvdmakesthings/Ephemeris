# Element Sets: TLE and OMM

> **Brief Description**: What a satellite's published orbit actually is, how the classic Two-Line Element format and the modern Orbit Mean-Elements Message encode it, why Ephemeris supports both, and which one to use.

## Overview

Every app that tracks satellites starts with the same thing: a small set of numbers describing each satellite's orbit at a moment in time. The U.S. Space Force builds these numbers from radar and optical observations and publishes them for over twenty thousand objects through [Space-Track.org](https://www.space-track.org), and [CelesTrak](https://celestrak.org) republishes them in convenient groups.

For decades those numbers came in one format, the **Two-Line Element set (TLE)**. Today the same data is also published as an **Orbit Mean-Elements Message (OMM)**, an international standard. This guide explains what is inside both, why the newer format exists, and how to use either one in Ephemeris.

**What you'll learn:**
- What an element set is, and why it only works with the SGP4 model
- How to read a TLE, and where the format runs out of room
- What an OMM is, and how its encodings (JSON, XML, KVN, CSV) relate
- How the two formats map to each other field by field
- Which one to choose, and how to load each in Swift

---

## Table of Contents

- [What Is an Element Set?](#what-is-an-element-set)
- [The Two-Line Element Format](#the-two-line-element-format)
- [Where TLEs Run Out of Room](#where-tles-run-out-of-room)
- [The Orbit Mean-Elements Message](#the-orbit-mean-elements-message)
- [Field-by-Field Comparison](#field-by-field-comparison)
- [Which Should I Use?](#which-should-i-use)
- [Using Element Sets in Ephemeris](#using-element-sets-in-ephemeris)
- [A Warning About SGP4-XP](#a-warning-about-sgp4-xp)
- [References](#references)

---

## What Is an Element Set?

An element set is a snapshot of an orbit: the six classical orbital elements (size, shape, tilt, orientation and position, covered in [Orbital Elements](orbital-elements.md)) at a moment called the **epoch**, plus a drag term.

There is an important subtlety. The published numbers are **mean elements**, not the satellite's true instantaneous orbit. The Earth's bulge, the atmosphere, the Moon and the Sun keep nudging a satellite, so its real orbit wobbles constantly. To publish something compact, the Space Force fits observations with a model called **SGP4** (Simplified General Perturbations 4) and publishes the model's averaged ("mean") inputs. That is why Space-Track and CelesTrak call this **GP data**: General Perturbations element sets.

The practical consequence:

> An element set is only accurate when it is fed back into the same model that produced it. Use `SGP4` to propagate it.

Feeding the same numbers into a simple two-body (Keplerian) calculation gives a satellite that drifts hundreds of kilometers off within a day, because the effects SGP4 averaged out are never added back.

TLE and OMM are two **text formats for the same element set**. Neither is more accurate in itself; they carry the same physics.

---

## The Two-Line Element Format

The TLE format was designed by NORAD in the 1960s, when orbits were exchanged on 80-column punched cards. Each satellite takes two fixed-width lines of 69 characters, usually preceded by a name line:

```
ISS (ZARYA)
1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
```

Every value lives in fixed columns, so the format is read by position, not by name:

| Line | Columns | Value in the example | Meaning |
|------|---------|----------------------|---------|
| 1 | 3-7 | `25544` | Catalog number |
| 1 | 8 | `U` | Classification (unclassified) |
| 1 | 10-17 | `98067A` | International designator: 1998, launch 67, piece A |
| 1 | 19-20 | `20` | Epoch year (2-digit) |
| 1 | 21-32 | `097.82871450` | Epoch day of year with fraction (April 6, 19:53:20.93 UTC) |
| 1 | 34-43 | `.00000874` | First derivative of mean motion ÷ 2 |
| 1 | 45-52 | `00000-0` | Second derivative of mean motion ÷ 6 |
| 1 | 54-61 | `24271-4` | B* drag term: 0.24271 × 10⁻⁴ |
| 1 | 63 | `0` | Ephemeris type (0 = SGP4) |
| 1 | 65-68 | `999` | Element set number |
| 2 | 9-16 | `51.6465` | Inclination (°) |
| 2 | 18-25 | `341.5807` | Right ascension of the ascending node (°) |
| 2 | 27-33 | `0003880` | Eccentricity with an assumed leading decimal point: 0.000388 |
| 2 | 35-42 | `94.4223` | Argument of perigee (°) |
| 2 | 44-51 | `26.1197` | Mean anomaly (°) |
| 2 | 53-63 | `15.48685836` | Mean motion (revolutions per day) |
| 2 | 64-68 | `22095` | Revolution number at epoch |
| 1, 2 | 69 | `2`, `8` | Checksum: sum of digits (minus signs count as 1), mod 10 |

TLEs are compact, human-readable once you know the columns, and supported by essentially every tracking program ever written. That universality is why they are still everywhere.

---

## Where TLEs Run Out of Room

The fixed columns that made sense for punched cards cause real problems today.

**Catalog numbers.** Every tracked object gets a NORAD catalog number, and the TLE has exactly five characters for it. Plain digits stop at 99999. With large constellations and more debris being tracked, the catalog is reaching that limit. The "Alpha-5" workaround replaces the first digit with a letter (`A0001` = 100001, skipping I and O), which stretches the field to 339999, but older software doesn't understand it and the field is still finite.

**Two-digit years.** Years 57-99 mean 1957-1999 and 00-56 mean 2000-2056 (Sputnik launched in 1957). In 2057 the scheme stops working.

**Precision.** The epoch is a day fraction with 8 decimal places, which resolves about 0.86 milliseconds. Other fields are similarly truncated to fit their columns.

**Implicit assumptions.** A TLE never says which reference frame, time system or model its numbers belong to. Everyone simply knows the answers are TEME, UTC and SGP4. That works until a different model is used (see [SGP4-XP](#a-warning-about-sgp4-xp)).

**Fragile notation.** Values like `24271-4` (meaning 0.24271 × 10⁻⁴) and `0003880` (meaning 0.000388) are easy to misread, and a single shifted space corrupts a field.

---

## The Orbit Mean-Elements Message

The **Orbit Mean-Elements Message (OMM)** is part of the Orbit Data Messages standard, CCSDS 502.0-B, published by the Consultative Committee for Space Data Systems. That is the body through which NASA, ESA and other agencies agree on how to exchange space data.

Instead of fixed columns, an OMM is a set of **named keywords**: `EPOCH`, `MEAN_MOTION`, `INCLINATION`, and so on. It carries the same SGP4 mean elements as a TLE, plus metadata that says exactly what they are:

| Keyword | Typical value | What it states |
|---------|---------------|----------------|
| `CENTER_NAME` | `EARTH` | The body being orbited |
| `REF_FRAME` | `TEME` | The reference frame of the elements |
| `TIME_SYSTEM` | `UTC` | The time scale of the epoch |
| `MEAN_ELEMENT_THEORY` | `SGP4` | The model the elements are fitted to |

### One Message, Several Encodings

The standard defines the keywords, and the same keywords can be written in different text encodings. Space-Track and CelesTrak serve all of these, and Ephemeris reads all of them:

**JSON** (the most common choice for apps):
```json
[{"OBJECT_NAME": "ISS (ZARYA)", "OBJECT_ID": "1998-067A",
  "EPOCH": "2020-04-06T19:53:20.932800", "MEAN_MOTION": 15.48685836,
  "ECCENTRICITY": 0.000388, "INCLINATION": 51.6465, "RA_OF_ASC_NODE": 341.5807,
  "ARG_OF_PERICENTER": 94.4223, "MEAN_ANOMALY": 26.1197, "EPHEMERIS_TYPE": 0,
  "CLASSIFICATION_TYPE": "U", "NORAD_CAT_ID": 25544, "ELEMENT_SET_NO": 999,
  "REV_AT_EPOCH": 22095, "BSTAR": 2.4271e-5, "MEAN_MOTION_DOT": 8.74e-6,
  "MEAN_MOTION_DDOT": 0}]
```

**KVN** (CCSDS "keyword = value" text):
```
CCSDS_OMM_VERS = 2.0
OBJECT_NAME = ISS (ZARYA)
OBJECT_ID = 1998-067A
CENTER_NAME = EARTH
REF_FRAME = TEME
TIME_SYSTEM = UTC
MEAN_ELEMENT_THEORY = SGP4
EPOCH = 2020-04-06T19:53:20.932800
MEAN_MOTION = 15.48685836
...
```

**XML** (the CCSDS NDM/XML schema, nested as `segment › metadata` and `segment › data › meanElements / tleParameters`) and **CSV** (a header row of keywords, then one row per satellite) carry the same fields.

### What OMM Fixes

- **No catalog number limit.** `NORAD_CAT_ID` is an ordinary integer.
- **Full dates.** `EPOCH` is an ISO 8601 timestamp with microseconds, so there is no 2056 cliff and no rounding to a millisecond.
- **Readable numbers.** `0.000388` instead of `0003880`, `2.4271e-5` instead of `24271-4`.
- **Self-describing.** The frame, time system and model are stated, so software can refuse data it cannot handle instead of silently misusing it.
- **Robust parsing.** Fields are found by name, so formatting differences don't shift values into the wrong field.

CelesTrak recommends that new software use OMM, and objects whose catalog numbers do not fit a TLE are only available that way.

---

## Field-by-Field Comparison

Both formats map onto the same Swift properties, which is what lets `SGP4` treat them interchangeably.

| Meaning | TLE (line, columns) | OMM keyword | Ephemeris property |
|---------|---------------------|-------------|--------------------|
| Name | line 0 | `OBJECT_NAME` | `name` |
| Catalog number | 1, 3-7 | `NORAD_CAT_ID` | `catalogNumber` |
| International designator | 1, 10-17 (`98067A`) | `OBJECT_ID` (`1998-067A`) | `internationalDesignator` |
| Classification | 1, 8 | `CLASSIFICATION_TYPE` | `classification` |
| Epoch | 1, 19-32 | `EPOCH` | `epoch` (`Date`) |
| ṅ/2 | 1, 34-43 | `MEAN_MOTION_DOT` | `meanMotionFirstDerivative` |
| n̈/6 | 1, 45-52 | `MEAN_MOTION_DDOT` | `meanMotionSecondDerivative` |
| B* drag term | 1, 54-61 | `BSTAR` | `bstarDragTerm` |
| Ephemeris type | 1, 63 | `EPHEMERIS_TYPE` | `ephemerisType` |
| Element set number | 1, 65-68 | `ELEMENT_SET_NO` | `elementSetNumber` |
| Inclination | 2, 9-16 | `INCLINATION` | `inclination` |
| Right ascension of ascending node | 2, 18-25 | `RA_OF_ASC_NODE` | `rightAscensionOfAscendingNode` |
| Eccentricity | 2, 27-33 | `ECCENTRICITY` | `eccentricity` |
| Argument of perigee | 2, 35-42 | `ARG_OF_PERICENTER` | `argumentOfPerigee` |
| Mean anomaly | 2, 44-51 | `MEAN_ANOMALY` | `meanAnomaly` |
| Mean motion | 2, 53-63 | `MEAN_MOTION` | `meanMotion` |
| Revolution number | 2, 64-68 | `REV_AT_EPOCH` | `revolutionNumberAtEpoch` |
| Frame, time system, model | (assumed) | `REF_FRAME`, `TIME_SYSTEM`, `MEAN_ELEMENT_THEORY` | `referenceFrame`, `timeSystem`, `meanElementTheory` (OMM only) |

At a glance:

| | TLE | OMM |
|---|-----|-----|
| Standard | De facto (NORAD, 1960s) | CCSDS 502.0-B |
| Layout | Fixed columns | Named keywords |
| Encodings | One | JSON, XML, KVN, CSV |
| Catalog numbers | Up to 99999 (339999 with Alpha-5) | Unlimited |
| Epoch | 2-digit year, ~1 ms resolution | ISO 8601, microseconds |
| States its frame and model | No | Yes |
| Software support | Universal | Growing; standard in modern tools |
| Accuracy when propagated with SGP4 | Same | Same |

---

## Which Should I Use?

- **Building something new?** Use OMM, and JSON is the easiest encoding to download and parse. It will keep working as catalog numbers grow.
- **Need to paste an orbit by hand, or work with older tools?** TLEs are compact and every tracking program understands them.
- **Both available?** For the same element set the predictions are identical. Ephemeris' test suite checks that an OMM and its equivalent TLE produce the same positions to within a millimeter.

---

## Using Element Sets in Ephemeris

Both `TwoLineElement` and `OrbitMeanElementsMessage` conform to the `MeanElementSet` protocol, and `SGP4` accepts either.

### From a TLE

```swift
import Ephemeris

let tle = try TwoLineElement(from: """
    ISS (ZARYA)
    1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
    2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
    """)
let sgp4 = try SGP4(elements: tle)          // or SGP4(tle: tle)
```

### From an OMM

`OrbitMeanElementsMessage.parse` detects the encoding and returns one message per satellite:

```swift
import Ephemeris

let json = """
    [{"OBJECT_NAME": "ISS (ZARYA)", "OBJECT_ID": "1998-067A",
      "EPOCH": "2020-04-06T19:53:20.932800", "MEAN_MOTION": 15.48685836,
      "ECCENTRICITY": 0.000388, "INCLINATION": 51.6465, "RA_OF_ASC_NODE": 341.5807,
      "ARG_OF_PERICENTER": 94.4223, "MEAN_ANOMALY": 26.1197, "EPHEMERIS_TYPE": 0,
      "CLASSIFICATION_TYPE": "U", "NORAD_CAT_ID": 25544, "ELEMENT_SET_NO": 999,
      "REV_AT_EPOCH": 22095, "BSTAR": 2.4271e-5, "MEAN_MOTION_DOT": 8.74e-6,
      "MEAN_MOTION_DDOT": 0}]
    """
let satellites = try OrbitMeanElementsMessage.parse(json)
let iss = satellites[0]
print("\(iss.name) #\(iss.catalogNumber), epoch \(iss.epoch), frame \(iss.referenceFrame)")

let sgp4 = try SGP4(elements: iss)
let position = try sgp4.calculatePosition(at: iss.epoch)
```

To pick the encoding explicitly, pass `format:` (`.json`, `.xml`, `.kvn` or `.csv`).

### Downloading from CelesTrak

CelesTrak's GP query returns OMM for a satellite or a whole group. Ask for `FORMAT=JSON`:

```swift
import Foundation
import Ephemeris

func fetchStations() async throws -> [SGP4] {
    let url = URL(string: "https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=JSON")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try OrbitMeanElementsMessage.parse(data, format: .json).map { try SGP4(elements: $0) }
}
```

CelesTrak updates element sets several times a day and asks clients not to download the same data more often than that. Cache what you fetch.

### Writing Code That Accepts Either

Generic code can take any element set:

```swift
import Foundation
import Ephemeris

func describe(_ elements: some MeanElementSet) -> String {
    let periodMinutes = 1440.0 / elements.meanMotion
    return "#\(elements.catalogNumber): \(String(format: "%.1f", periodMinutes)) min orbit, "
        + "inclination \(elements.inclination)°"
}
```

---

## A Warning About SGP4-XP

The Space Force has started publishing some element sets fitted with **SGP4-XP**, an extended model that is more accurate over longer spans. These sets look like normal element sets, but they are marked with `EPHEMERIS_TYPE = 4` (or `MEAN_ELEMENT_THEORY = SGP4-XP` in an OMM). Their numbers only make sense to the SGP4-XP model.

Standard SGP4 would happily run on them and produce positions that are simply wrong. To prevent that, `SGP4` refuses them with `SGP4Error.unsupportedEphemerisType(4)`. This is one of the places where OMM's explicit metadata helps: the model is stated, not assumed.

Ordinary element sets (`EPHEMERIS_TYPE = 0`) are what CelesTrak's standard GP queries return.

---

## References

- CCSDS 502.0-B-3, "Orbit Data Messages", Consultative Committee for Space Data Systems
- CelesTrak, "GP Data Formats": https://celestrak.org/NORAD/documentation/gp-data-formats.php
- CelesTrak, "NORAD Two-Line Element Set Format": https://celestrak.org/columns/v04n03/
- Vallado, Crawford, Hujsak, Kelso, "Revisiting Spacetrack Report #3", AIAA 2006-6753
- Hoots and Roehrich, "Spacetrack Report #3: Models for Propagation of NORAD Element Sets" (1980)
