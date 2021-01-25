// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SemanticVersion",
    products: [
        .library(
            name: "SemanticVersion",
            targets: ["SemanticVersion"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SemanticVersion",
            dependencies: []),
        .testTarget(
            name: "SemanticVersionTests",
            dependencies: ["SemanticVersion"]),
    ]
)
