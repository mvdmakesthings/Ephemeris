// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Ephemeris",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Ephemeris",
            targets: ["Ephemeris"]
        )
    ],
    dependencies: [
        // Add package dependencies here, if any.
    ],
    targets: [
        .target(
            name: "Ephemeris",
            path: "Ephemeris"
        ),
        .testTarget(
            name: "EphemerisTests",
            dependencies: ["Ephemeris"],
            path: "EphemerisTests"
        )
    ]
)
