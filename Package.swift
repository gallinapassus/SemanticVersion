// swift-tools-version:5.4

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
