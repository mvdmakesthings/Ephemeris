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
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Ephemeris"
        ),
        .testTarget(
            name: "EphemerisTests",
            dependencies: ["Ephemeris"]
        )
    ]
)
