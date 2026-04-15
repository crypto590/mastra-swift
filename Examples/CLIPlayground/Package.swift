// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CLIPlayground",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "mastra-play", targets: ["CLIPlayground"]),
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "CLIPlayground",
            dependencies: [
                .product(name: "Mastra", package: "mastra-swift"),
            ],
            path: "Sources/CLIPlayground"
        ),
    ]
)
