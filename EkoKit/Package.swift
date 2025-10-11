// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EkoKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "EkoKit",
            targets: ["EkoKit"]
        ),
    ],
    dependencies: [
        // EkoKit depends on EkoCore for shared models
        .package(path: "../EkoCore")
    ],
    targets: [
        .target(
            name: "EkoKit",
            dependencies: ["EkoCore"]
        ),
        .testTarget(
            name: "EkoKitTests",
            dependencies: ["EkoKit"]
        ),
    ]
)
