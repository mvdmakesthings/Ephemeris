# Doppler Tuning and Radio Control

> **Brief Description**: Why a satellite's signal slides in frequency during a pass, how to compute that shift, and how to keep an SDR program (SDR++, GQRX) or a Hamlib-controlled radio tuned to it automatically.

## Overview

Tune an SDR to a satellite's published downlink frequency and wait for a pass. When the satellite rises, its signal isn't where you tuned: it's a few kHz higher. As the pass goes on, the signal slides down through the published frequency and ends a few kHz lower. This is the Doppler effect, and for narrow signals it moves them right out of the receiver's filter within a minute.

Ephemeris computes the shift exactly from the satellite's motion, and the optional `EphemerisRadio` library retunes your SDR to follow it.

**What you'll learn:**
- Where the shift comes from and how big it gets
- The shape of a Doppler curve, and what it tells you about a pass
- How to compute the received frequency with Ephemeris
- How to connect to SDR++, GQRX or Hamlib, and let `DopplerTuningSession` do the tuning
- How to correct for your SDR's crystal error

---

## Table of Contents

- [The Physics](#the-physics)
- [The Shape of a Pass](#the-shape-of-a-pass)
- [Computing Doppler with Ephemeris](#computing-doppler-with-ephemeris)
- [Controlling an SDR](#controlling-an-sdr)
- [Automatic Doppler Tuning](#automatic-doppler-tuning)
- [Accuracy](#accuracy)
- [References](#references)

---

## The Physics

A radio signal is a train of wave crests sent at a steady rate, the frequency `f`. If the transmitter moves toward you, each crest is sent from a little closer than the one before, so it has less distance to travel and arrives a little sooner. Crests arrive more often than they were sent: you hear a higher frequency. Moving away, they arrive less often: you hear a lower one.

Only motion **along the line of sight** counts. Sideways motion doesn't change the distance, so it doesn't change the frequency. The line-of-sight speed is the **range rate** `ṙ`, the rate at which the distance between you and the satellite changes (positive when it is growing). `Topocentric.rangeRateKmPerSec` gives it directly.

```
f_received = f · (1 − ṙ / c)          c = 299,792.458 km/s
Δf         = −f · ṙ / c
```

A low Earth orbit satellite moves at about 7.5 km/s, so `ṙ` runs from about −7 km/s as it rises to +7 km/s as it sets. The shift is proportional to frequency:

| Downlink | Example | Shift at rise and set |
|----------|---------|-----------------------|
| 137.1 MHz | NOAA 19 APT | about ±3.0 kHz (higher orbit, slower range rate) |
| 145.8 MHz | ISS FM voice | about ±3.4 kHz |
| 437.8 MHz | CubeSat telemetry | about ±10 kHz |
| 2.4 GHz | S-band | about ±56 kHz |

For an FM voice channel (about 15 kHz wide) at 145.8 MHz, the shift barely matters. For a 437 MHz CubeSat sending 1200 baud packets in a few kHz, or a CW beacon in a few hundred Hz, it decides whether you hear anything at all.

### Transmitting

For an uplink, the satellite is the moving receiver. It hears `f_tx · (1 − ṙ / c)`, so to land exactly on its receive frequency `f` you transmit at `f / (1 − ṙ / c)`. `Doppler.uplinkFrequency(nominalHz:rangeRateKmPerSec:)` does this. Receive-only stations don't need it.

---

## The Shape of a Pass

Plot the received frequency over a pass and you get a backwards S:

```
 +3 kHz ─╮
         ╰──╮
            ╰╮
  0 ────────·┼·──────────    ← closest approach: the satellite moves across your line of sight
             ╰╮
              ╰──╮
 −3 kHz          ╰──────
        rise        set
```

- **At rise and set**, the satellite is far away and moving almost straight toward or away from you, so the shift is near its maximum and changes slowly.
- **At closest approach**, it moves across your line of sight, so the shift passes through zero, and it changes fastest there.

How fast? At closest approach the range acceleration is about `v² / d`, where `v` is the satellite's speed relative to you and `d` is the closest distance. So the Doppler **rate** at that moment is about

```
df/dt ≈ −f · v² / (c · d)
```

For the ISS (v ≈ 7.1 km/s) passing 472 km away, at 145.8 MHz: −145.8 MHz × 7.1² / (299,792 × 472) ≈ **−52 Hz/s**. An overhead pass (d ≈ 420 km) is steeper; a low pass far away is gentle. That makes the curve a fingerprint: the zero crossing tells you **when** the satellite was closest, and the slope there tells you **how close** it came. Ephemeris' future identification feature uses exactly this.

---

## Computing Doppler with Ephemeris

These live in the core `Ephemeris` library; no radio needed.

```swift
import Ephemeris

let iss = try SGP4(tle: issTLE)
let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

// Right now
let now = try iss.doppler(at: Date(), for: observer, nominalFrequencyHz: 145_800_000)
print("Tune to \(now.frequencyHz) Hz (\(now.shiftHz) Hz shift, drifting \(now.rateHzPerSec) Hz/s)")

// A whole pass, one point every 10 seconds
if let pass = try iss.predictPasses(for: observer, from: Date(), to: Date().addingTimeInterval(86400)).first {
    let curve = try iss.dopplerCurve(for: observer, nominalFrequencyHz: 145_800_000,
                                     from: pass.aos.time, to: pass.los.time)
    for point in curve {
        print(point.time, point.shiftHz, point.topocentric.elevationDeg)
    }
}
```

`DopplerPoint.rateHzPerSec` comes from differentiating the formula: `df/dt = −f · r̈ / c`. The range acceleration `r̈` is found from the range rate half a second either side, which agrees with Skyfield to within 0.003 Hz/s in the test suite.

---

## Controlling an SDR

SDR programs and Hamlib share a simple text protocol called **rigctl**: one command per line over TCP. `RigctlClient` (in `EphemerisRadio`) speaks the four commands they all support:

| Command | Meaning | Reply |
|---------|---------|-------|
| `F 145800000` | Set frequency (Hz) | `RPRT 0` |
| `f` | Get frequency | `145800000` |
| `M FM 15000` | Set mode and filter width (Hz) | `RPRT 0` |
| `m` | Get mode and filter width | `FM`, then `15000` |

`RPRT 0` means success; any other code is an error, which the client throws as `RigControlError.rejected`.

### Setting Up Your SDR Program

| Program | How to enable | Default port |
|---------|---------------|--------------|
| **SDR++** | Module Manager → add a *Rigctl Server* module → press Start in its panel | 4532 (`RigctlClient.rigctldPort`) |
| **GQRX** | Tools → Remote Control. In Remote control settings, allow the IP address of the device running your app | 7356 (`RigctlClient.gqrxPort`) |
| **Hamlib rigctld** (hardware radio) | `rigctld -m <model number> -r <serial port>` | 4532 |

```swift
import EphemerisRadio

let sdr = RigctlClient(host: "127.0.0.1", port: RigctlClient.gqrxPort)
try await sdr.setMode(.fm, passbandHz: 15_000)
try await sdr.setFrequency(145_800_000)
print(try await sdr.frequency())
```

The client connects on the first command, reconnects by itself if the program restarts, and sends commands from several tasks one at a time so replies never get mixed up.

**On iOS**, connecting to a Mac running SDR++ or GQRX is a *local network* connection. Add `NSLocalNetworkUsageDescription` to your app's Info.plist with a sentence explaining why (for example, "Tunes your SDR software to follow satellites"). iOS asks the user once.

### Typical Modes and Filter Widths

| Signal | Mode | Filter width |
|--------|------|--------------|
| FM voice, APRS, FM packet | `.fm` | 12,500 to 15,000 Hz |
| NOAA APT weather images | `.wfm` | about 40,000 Hz |
| CW beacons | `.cw` | 500 Hz |
| SSB, linear transponders | `.usb` | 2,400 Hz |

---

## Automatic Doppler Tuning

`DopplerTuningSession` does the work once a second: it computes the shifted frequency and retunes the SDR when it has moved enough.

```swift
import Ephemeris
import EphemerisRadio

let sdr = RigctlClient(port: RigctlClient.rigctldPort)   // SDR++ on this computer
let session = DopplerTuningSession(
    propagator: try SGP4(tle: issTLE),
    observer: Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140),
    radio: sdr,
    configuration: .init(nominalFrequencyHz: 145_800_000, mode: .fm, passbandHz: 15_000)
)

let tuning = Task { await session.run() }
for await update in session.updates {
    switch update {
    case .tuned(let point, let sentHz):
        print("Tuned to \(sentHz) Hz, elevation \(point.topocentric.elevationDeg)°")
    case .holding(let point, _):
        print("On frequency, shift \(point.shiftHz) Hz")
    case .belowHorizon:
        print("Waiting for the satellite to rise")
    case .radioUnavailable(let error):
        print("SDR not reachable: \(error)")
    case .propagationFailed(let reason):
        print("Can't compute the orbit: \(reason)")
    }
}
// To stop: tuning.cancel()
```

Each second the session:
1. Computes look angles and the received frequency.
2. Below the minimum elevation, sends nothing.
3. Above it, sends a new frequency only if it has moved by at least the **tuning step** since the last one sent. Early and late in a pass the shift changes by a few Hz per second, so most seconds need no command; near closest approach it changes by 50 Hz/s or more, and every second gets one. Over the ISS pass in the test suite, the radio is never more than one step off.
4. If the SDR can't be reached, waits `reconnectInterval` (5 s) before trying again, and selects the mode again once it is back, since the program may have restarted.

| Setting | Default | Notes |
|---------|---------|-------|
| `tuningStepHz` | 10 Hz | 10 Hz suits CW and SSB; FM is fine with 100 Hz or more |
| `updateInterval` | 1 s | Never less than 0.1 s |
| `minElevationDeg` | 0° | Raise it if trees or buildings block your horizon |
| `mode`, `passbandHz` | not set, 15,000 Hz | Selected once when tuning starts |

### Correcting Your SDR's Crystal

The frequency an SDR displays is only as good as its crystal oscillator. A typical RTL-SDR is off by 0.5 to 20 ppm, which at 437 MHz is 200 Hz to 9 kHz. That error is larger than anything in the Doppler math, and it doesn't change during a pass.

Watch the waterfall when the satellite is up. If the signal sits 1.2 kHz above the middle of the passband, tell the session:

```swift
await session.setCorrection(hertz: 1200)
```

It is added to every frequency sent, and the SDR is retuned on the next step. Most SDR programs also have their own PPM setting; either works, but don't use both at once.

---

## Accuracy

| Source | Size at 437 MHz | Notes |
|--------|-----------------|-------|
| SDR crystal error | 200 Hz to 9 kHz | Constant; fix with `setCorrection` or the program's PPM setting |
| Element set age | about 20 Hz per day of age near closest approach | 1 km along-track error ≈ 0.13 s of timing error at ~150 Hz/s |
| Tuning step | up to `tuningStepHz` | By design |
| Relativistic terms | about 0.1 Hz | β²/2 ≈ 3 × 10⁻¹⁰ of the frequency; 3 Hz even at 10 GHz |
| UT1 − UTC | well under 1 Hz | Ephemeris uses UTC for Earth rotation |

The first-order formula is the right tool: the next correction is hundreds of times smaller than a typical SDR's crystal error. Keep element sets fresh (see [Working With Whole Catalogs](./catalogs.md)) and correct the crystal once, and the signal stays centered.

---

## References

- Davidoff, "The Radio Amateur's Satellite Handbook" (ARRL): Doppler shift and satellite station operation
- Maral, Bousquet and Sun, "Satellite Communications Systems" (Wiley): Doppler effect on satellite links
- Hamlib, rigctld manual page: the rigctl network protocol (https://hamlib.github.io/)
- Vallado, "Fundamentals of Astrodynamics and Applications" (4th ed.), Section 4.4: range and range rate from the observer
