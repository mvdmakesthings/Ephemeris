// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ephemeris",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Ephemeris",
            targets: ["Ephemeris"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // No external dependencies currently
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Ephemeris",
            dependencies: [],
            path: "Ephemeris"
        ),
        .testTarget(
            name: "EphemerisTests",
            dependencies: ["Ephemeris"],
            path: "EphemerisTests"
        )
    ]
)
