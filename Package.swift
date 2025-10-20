// swift-tools-version:5.9
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
        ),
        .executable(
            name: "EphemerisTests",
            targets: ["EphemerisTests"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/Spectre.git", from: "0.10.1")
    ],
    targets: [
        .target(
            name: "Ephemeris",
            path: "Ephemeris"
        ),
        .executableTarget(
            name: "EphemerisTests",
            dependencies: [
                "Ephemeris",
                .product(name: "Spectre", package: "Spectre")
            ],
            path: "EphemerisTests"
        )
    ]
)
