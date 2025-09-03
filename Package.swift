// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Linea",
    platforms: [
        .iOS(.v17), .macOS(.v13)
    ],
    products: [
        .library(name: "Linea", targets: ["Linea"]),
    ],
    targets: [
        .target(
            name: "Linea",
            path: "Sources/Linea"
        ),
        .testTarget(
            name: "LineaTests",
            dependencies: ["Linea"],
            path: "Tests/LineaTests"
        ),
    ]
)
