// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CircleFlagsKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CircleFlagsKit",
            targets: ["CircleFlagsKit"]
        ),
    ],
    dependencies: [
        // Snapshot Tests
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.18.7"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CircleFlagsKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CircleFlagsKitTests",
            dependencies: [
                "CircleFlagsKit",
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                )
            ]
        ),
    ]
)
