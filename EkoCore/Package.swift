// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EkoCore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "EkoCore",
            targets: ["EkoCore"]
        ),
    ],
    targets: [
        .target(
            name: "EkoCore",
            dependencies: []
        ),
        .testTarget(
            name: "EkoCoreTests",
            dependencies: ["EkoCore"]
        ),
    ]
)
