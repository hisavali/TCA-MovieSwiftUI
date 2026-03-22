// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MovieKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: [
        .library(name: "Common", targets: ["Common"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "NetworkClient", targets: ["NetworkClient"]),
        .library(name: "HomeFeature", targets: ["HomeFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.25.2"),
        .package(url: "git@github.com:pointfreeco/swift-dependencies.git", from: "1.11.0"),
    ],
    targets: [
        .target(
            name: "Data",
            dependencies: []
        ),
        .target(
            name: "Common",
            dependencies: [],
            resources: [.process("Media.xcassets")]
        ),
        .target(
            name: "HomeFeature",
            dependencies: [
                "Common",
                "Data",
                "NetworkClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "NetworkClient",
            dependencies: [
                "Data",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "HomeFeatureTests",
            dependencies: ["HomeFeature"]
        ),
    ]
)
