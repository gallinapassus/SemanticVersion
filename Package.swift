// swift-tools-version:5.7

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
            dependencies: [],
            exclude: ["SemanticVersion.docc"]),
        .testTarget(
            name: "SemanticVersionTests",
            dependencies: ["SemanticVersion"]),
    ]
)
