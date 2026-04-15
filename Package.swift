// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "mastra-swift",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "Mastra", targets: ["Mastra"]),
        .library(name: "MastraTestingSupport", targets: ["MastraTestingSupport"]),
    ],
    targets: [
        .target(
            name: "Mastra",
            path: "Sources/Mastra",
            exclude: ["TestingSupport"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .target(
            name: "MastraTestingSupport",
            dependencies: ["Mastra"],
            path: "Sources/Mastra/TestingSupport"
        ),
        .testTarget(
            name: "MastraTests",
            dependencies: ["Mastra", "MastraTestingSupport"],
            path: "Tests/MastraTests",
            resources: [.process("Fixtures")]
        ),
    ]
)
