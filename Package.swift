// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "Ephemeris",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
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
            path: "Ephemeris",
            exclude: ["Info.plist", "Ephemeris.h"]
        ),
        .testTarget(
            name: "EphemerisTests",
            dependencies: ["Ephemeris"],
            path: "EphemerisTests",
            exclude: ["Info.plist"]
        )
    ]
)
