// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MovieKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "Common",targets: ["Common"]),
        .library(name: "Data",targets: ["Data"]),
        .library(name: "NetworkClient",targets: ["NetworkClient"]),
        .library(name: "HomeFeature",targets: ["HomeFeature"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.15.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged.git", from: "0.10.0"),
        .package(url: "https://github.com/tgrapperon/swift-dependencies-additions.git", from: "1.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .target(
            name: "Data",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions")
            ]
        ),
        .target(
            name: "Common",
            dependencies: [
            ]
        ),
        .target(
            name: "HomeFeature",
            dependencies: [
                "Common",
                "Data",
                "NetworkClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "NetworkClient",
            dependencies: [
                "Data",
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions")
            ]
        ),
        .testTarget(
            name: "HomeFeatureTests",
            dependencies: ["HomeFeature"]
        ),

    ]
)
