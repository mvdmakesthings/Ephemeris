// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Ephemeris",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Ephemeris",
            targets: ["Ephemeris"]
        ),
        // Optional: downloads and caches catalogs from CelesTrak. Kept separate so the core
        // library never touches the network.
        .library(
            name: "EphemerisCatalog",
            targets: ["EphemerisCatalog"]
        ),
        // Optional: Doppler tuning of SDR programs and radios over rigctl (local network)
        .library(
            name: "EphemerisRadio",
            targets: ["EphemerisRadio"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Ephemeris"
        ),
        .target(
            name: "EphemerisCatalog",
            dependencies: ["Ephemeris"]
        ),
        .target(
            name: "EphemerisRadio",
            dependencies: ["Ephemeris"]
        ),
        .testTarget(
            name: "EphemerisTests",
            dependencies: ["Ephemeris"],
            resources: [
                // Vallado's SGP4 verification element sets and reference output
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "EphemerisCatalogTests",
            dependencies: ["EphemerisCatalog", "Ephemeris"]
        ),
        .testTarget(
            name: "EphemerisRadioTests",
            dependencies: ["EphemerisRadio", "Ephemeris"]
        )
    ]
)
