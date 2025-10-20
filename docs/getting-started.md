# Getting Started with Ephemeris

> **Brief Description**: Build your first satellite tracker app in 30 minutes. This code-heavy guide gets you from zero to tracking the ISS with minimal theory.

## Overview

This guide is for Swift/iOS developers who want to start using Ephemeris **right now**. We'll build a working satellite tracker with minimal explanation, focusing on practical implementation. If you want to understand the orbital mechanics theory, see [Orbital Elements](orbital-elements.md) after completing this guide.

**What you'll build:**
- Parse TLE data and create an `Orbit`
- Calculate current satellite position
- Predict satellite passes from your location
- Display results in a simple iOS app

**Time required**: 30 minutes
**Prerequisites**: Basic Swift knowledge, Xcode installed

---

## Step 1: Install Ephemeris (2 minutes)

### Option A: Swift Package Manager (Recommended)

1. Open your Xcode project
2. **File → Add Packages...**
3. Enter: `https://github.com/mvdmakesthings/Ephemeris.git`
4. Select version and click **Add Package**

### Option B: Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/mvdmakesthings/Ephemeris.git", from: "1.0.0")
]
```

---

## Step 2: Parse Your First TLE (5 minutes)

TLE (Two-Line Element) data describes a satellite's orbit. Get fresh TLE data from [CelesTrak](https://celestrak.com/NORAD/elements/).

### Create a Playground or Swift File

```swift
import Ephemeris
import Foundation

// ISS TLE data (update from CelesTrak for current data)
let issТLE = """
ISS (ZARYA)
1 25544U 98067A   24291.51803472  .00006455  00000-0  12345-3 0  9993
2 25544  51.6435 132.8077 0009821  94.4121  44.3422 15.50338483 48571
"""

do {
    // Parse the TLE
    let tle = try TwoLineElement(from: issТLE)

    print("✅ TLE Parsed Successfully!")
    print("Satellite: \(tle.name)")
    print("Catalog #: \(tle.catalogNumber)")
    print("Inclination: \(tle.inclination)°")

} catch {
    print("❌ Error: \(error)")
}
```

**What just happened?**
- `TwoLineElement` parsed the 3-line TLE format
- Extracted orbital elements (inclination, eccentricity, etc.)
- Validated checksums automatically

---

## Step 3: Calculate Satellite Position (5 minutes)

Now let's find where the ISS is **right now**:

```swift
import Ephemeris
import Foundation

let issТLE = """
ISS (ZARYA)
1 25544U 98067A   24291.51803472  .00006455  00000-0  12345-3 0  9993
2 25544  51.6435 132.8077 0009821  94.4121  44.3422 15.50338483 48571
"""

do {
    let tle = try TwoLineElement(from: issТLE)
    let orbit = Orbit(from: tle)

    // Calculate current position
    let position = try orbit.calculatePosition(at: Date())

    print("\n🛰️ ISS Current Position")
    print("Latitude:  \(String(format: "%.2f", position.latitude))°")
    print("Longitude: \(String(format: "%.2f", position.longitude))°")
    print("Altitude:  \(String(format: "%.0f", position.altitude)) km")

} catch {
    print("❌ Error: \(error)")
}
```

**Sample Output:**
```
🛰️ ISS Current Position
Latitude:  23.45°
Longitude: -74.32°
Altitude:  420 km
```

**Behind the scenes:**
1. Created `Orbit` from TLE
2. Solved Kepler's equation for current time
3. Transformed coordinates from ECI → ECEF → Geodetic

---

## Step 4: Predict When You Can See It (10 minutes)

Let's find when the ISS will be visible from your location:

```swift
import Ephemeris
import Foundation

// ISS TLE
let issТLE = """
ISS (ZARYA)
1 25544U 98067A   24291.51803472  .00006455  00000-0  12345-3 0  9993
2 25544  51.6435 132.8077 0009821  94.4121  44.3422 15.50338483 48571
"""

do {
    let tle = try TwoLineElement(from: issТLE)
    let orbit = Orbit(from: tle)

    // Your location (Louisville, Kentucky in this example)
    // Replace with your coordinates!
    let observer = Observer(
        latitudeDeg: 38.2542,       // Your latitude
        longitudeDeg: -85.7594,     // Your longitude
        altitudeMeters: 140         // Your altitude above sea level
    )

    // Predict passes over next 24 hours
    let now = Date()
    let tomorrow = now.addingTimeInterval(24 * 3600)

    let passes = try orbit.predictPasses(
        for: observer,
        from: now,
        to: tomorrow,
        minElevationDeg: 10.0,  // Only passes above 10° elevation
        stepSeconds: 30          // Search every 30 seconds
    )

    print("\n🔭 ISS Passes in Next 24 Hours: \(passes.count)\n")

    // Display each pass
    let formatter = DateFormatter()
    formatter.timeStyle = .short

    for (i, pass) in passes.enumerated() {
        print("Pass #\(i + 1)")
        print("  AOS: \(formatter.string(from: pass.aos.time)) at \(String(format: "%.0f", pass.aos.azimuthDeg))° azimuth")
        print("  MAX: \(formatter.string(from: pass.max.time)) - \(String(format: "%.0f", pass.max.elevationDeg))° elevation")
        print("  LOS: \(formatter.string(from: pass.los.time)) at \(String(format: "%.0f", pass.los.azimuthDeg))° azimuth")
        print("  Duration: \(Int(pass.duration)) seconds\n")
    }

} catch {
    print("❌ Error: \(error)")
}
```

**Sample Output:**
```
🔭 ISS Passes in Next 24 Hours: 4

Pass #1
  AOS: 2:30 PM at 315° azimuth
  MAX: 2:35 PM - 45° elevation
  LOS: 2:40 PM at 135° azimuth
  Duration: 600 seconds

Pass #2
  AOS: 10:15 PM at 25° azimuth
  MAX: 10:20 PM - 78° elevation
  LOS: 10:25 PM at 205° azimuth
  Duration: 540 seconds
```

**What's happening:**
- `Observer` represents your ground location
- `predictPasses()` searches for when satellite rises above horizon
- AOS = Acquisition of Signal (rises above 10°)
- MAX = Maximum elevation point
- LOS = Loss of Signal (drops below 10°)

---

## Step 5: Build a Simple iOS App (8 minutes)

Let's put it all together in a SwiftUI app:

```swift
import SwiftUI
import Ephemeris

@main
struct ISSTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var issPosition: Orbit.Position?
    @State private var passes: [Orbit.PassWindow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isLoading {
                        ProgressView("Loading...")
                    } else if let error = errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    } else {
                        // Current Position
                        if let position = issPosition {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Position")
                                    .font(.headline)
                                Text("Lat: \(String(format: "%.2f", position.latitude))°")
                                Text("Lon: \(String(format: "%.2f", position.longitude))°")
                                Text("Alt: \(String(format: "%.0f", position.altitude)) km")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Upcoming Passes
                        Text("Upcoming Passes")
                            .font(.headline)

                        if passes.isEmpty {
                            Text("No passes in next 24 hours")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(Array(passes.enumerated()), id: \.offset) { index, pass in
                                PassView(passNumber: index + 1, pass: pass)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("ISS Tracker")
            .onAppear {
                loadData()
            }
            .onReceive(timer) { _ in
                updatePosition()
            }
        }
    }

    func loadData() {
        let issТLE = """
        ISS (ZARYA)
        1 25544U 98067A   24291.51803472  .00006455  00000-0  12345-3 0  9993
        2 25544  51.6435 132.8077 0009821  94.4121  44.3422 15.50338483 48571
        """

        do {
            let tle = try TwoLineElement(from: issТLE)
            let orbit = Orbit(from: tle)

            // Update position
            issPosition = try orbit.calculatePosition(at: Date())

            // Predict passes
            let observer = Observer(
                latitudeDeg: 38.2542,      // Your coordinates
                longitudeDeg: -85.7594,
                altitudeMeters: 140
            )

            let now = Date()
            let tomorrow = now.addingTimeInterval(24 * 3600)

            passes = try orbit.predictPasses(
                for: observer,
                from: now,
                to: tomorrow,
                minElevationDeg: 10.0,
                stepSeconds: 30
            )

            isLoading = false

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func updatePosition() {
        let issТLE = """
        ISS (ZARYA)
        1 25544U 98067A   24291.51803472  .00006455  00000-0  12345-3 0  9993
        2 25544  51.6435 132.8077 0009821  94.4121  44.3422 15.50338483 48571
        """

        guard let tle = try? TwoLineElement(from: issТLE) else { return }
        let orbit = Orbit(from: tle)
        issPosition = try? orbit.calculatePosition(at: Date())
    }
}

struct PassView: View {
    let passNumber: Int
    let pass: Orbit.PassWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pass #\(passNumber)")
                .font(.subheadline)
                .bold()

            HStack {
                Text("Max Elevation:")
                Spacer()
                Text("\(String(format: "%.0f", pass.max.elevationDeg))°")
                    .bold()
            }

            HStack {
                Text("Duration:")
                Spacer()
                Text("\(Int(pass.duration))s")
            }

            let formatter = DateFormatter()
            let _ = formatter.timeStyle = .short

            HStack {
                Text("Time:")
                Spacer()
                Text(formatter.string(from: pass.aos.time))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
```

**Run the app!** You now have a real-time ISS tracker that updates every 10 seconds.

---

## What You've Learned

In 30 minutes, you've:
- ✅ Installed Ephemeris
- ✅ Parsed TLE data
- ✅ Calculated satellite positions
- ✅ Predicted visible passes
- ✅ Built a simple iOS app

## Next Steps

### Level Up Your App

Add these features (each takes 10-15 minutes):

1. **Ground Track Visualization**
   - See [Visualization Guide](visualization.md)
   - Plot satellite path on a map

2. **Multiple Satellites**
   - Fetch TLEs from CelesTrak API
   - Track Hubble, Starlink, GPS satellites

3. **Notifications**
   - Alert user before visible passes
   - Use local notifications

4. **Compass Integration**
   - Show direction to point antenna/telescope
   - Use Core Location + Core Motion

### Understand the Science

Now that you have working code, learn the orbital mechanics:

1. **[Orbital Elements](orbital-elements.md)** - What do those TLE numbers mean?
2. **[Observer Geometry](observer-geometry.md)** - How does pass prediction work?
3. **[Coordinate Systems](coordinate-systems.md)** - Deep dive into transformations

### Production Checklist

Before shipping your app:

- [ ] Fetch fresh TLEs from CelesTrak or Space-Track
- [ ] Handle TLE fetch failures gracefully
- [ ] Cache TLEs (update every 1-3 days)
- [ ] Add user location selection
- [ ] Test with different satellites
- [ ] Handle edge cases (polar regions, date changes)
- [ ] Add error handling for all calculations

---

## Common Issues

### "TLE parsing failed"
- Check TLE format (must be exactly 3 lines)
- Verify checksums match
- Get fresh TLE from CelesTrak

### "No passes found"
- Satellite may not pass over your location (check inclination)
- Try longer time window (48-72 hours)
- Lower `minElevationDeg` to 0°

### "Position seems wrong"
- TLE may be outdated (get fresh data)
- Verify observer coordinates
- Check device date/time settings

---

## Resources

**TLE Data Sources:**
- [CelesTrak](https://celestrak.com/NORAD/elements/) - Free, updated frequently
- [Space-Track.org](https://www.space-track.org/) - Official source (requires free account)
- [N2YO.com](https://www.n2yo.com/) - Real-time tracking

**Further Reading:**
- [API Reference](api-reference.md) - Complete method documentation
- [Orbital Elements](orbital-elements.md) - Theory behind the calculations
- [Visualization](visualization.md) - Add charts and maps

---

## Complete Working Example

Here's the entire code from this guide in one file you can copy-paste:

```swift
import SwiftUI
import Ephemeris

@main
struct ISSTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var issPosition: Orbit.Position?
    @State private var passes: [Orbit.PassWindow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isLoading {
                        ProgressView("Loading...")
                    } else if let error = errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    } else {
                        if let position = issPosition {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Position")
                                    .font(.headline)
                                Text("Lat: \(String(format: "%.2f", position.latitude))°")
                                Text("Lon: \(String(format: "%.2f", position.longitude))°")
                                Text("Alt: \(String(format: "%.0f", position.altitude)) km")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }

                        Text("Upcoming Passes")
                            .font(.headline)

                        if passes.isEmpty {
                            Text("No passes in next 24 hours")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(Array(passes.enumerated()), id: \.offset) { index, pass in
                                PassView(passNumber: index + 1, pass: pass)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("ISS Tracker")
            .onAppear { loadData() }
            .onReceive(timer) { _ in updatePosition() }
        }
    }

    func loadData() {
        let issТLE = """
        ISS (ZARYA)
        1 25544U 98067A   24291.51803472  .00006455  00000-0  12345-3 0  9993
        2 25544  51.6435 132.8077 0009821  94.4121  44.3422 15.50338483 48571
        """

        do {
            let tle = try TwoLineElement(from: issТLE)
            let orbit = Orbit(from: tle)

            issPosition = try orbit.calculatePosition(at: Date())

            let observer = Observer(
                latitudeDeg: 38.2542,
                longitudeDeg: -85.7594,
                altitudeMeters: 140
            )

            let now = Date()
            let tomorrow = now.addingTimeInterval(24 * 3600)

            passes = try orbit.predictPasses(
                for: observer,
                from: now,
                to: tomorrow,
                minElevationDeg: 10.0,
                stepSeconds: 30
            )

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func updatePosition() {
        let issТLE = """
        ISS (ZARYA)
        1 25544U 98067A   24291.51803472  .00006455  00000-0  12345-3 0  9993
        2 25544  51.6435 132.8077 0009821  94.4121  44.3422 15.50338483 48571
        """
        guard let tle = try? TwoLineElement(from: issТLE) else { return }
        let orbit = Orbit(from: tle)
        issPosition = try? orbit.calculatePosition(at: Date())
    }
}

struct PassView: View {
    let passNumber: Int
    let pass: Orbit.PassWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pass #\(passNumber)")
                .font(.subheadline)
                .bold()

            HStack {
                Text("Max Elevation:")
                Spacer()
                Text("\(String(format: "%.0f", pass.max.elevationDeg))°")
                    .bold()
            }

            HStack {
                Text("Duration:")
                Spacer()
                Text("\(Int(pass.duration))s")
            }

            let formatter = DateFormatter()
            let _ = formatter.timeStyle = .short

            HStack {
                Text("Time:")
                Spacer()
                Text(formatter.string(from: pass.aos.time))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
```

**Congratulations!** You've built your first satellite tracker. Now go make it amazing! 🚀

---

*This guide is part of the [Ephemeris](https://github.com/mvdmakesthings/Ephemeris) framework documentation.*

**Last Updated**: October 20, 2025
