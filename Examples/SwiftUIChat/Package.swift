// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SwiftUIChat",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .executable(name: "SwiftUIChat", targets: ["SwiftUIChat"]),
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "SwiftUIChat",
            dependencies: [
                .product(name: "Mastra", package: "mastra-swift"),
            ],
            path: "Sources/SwiftUIChat"
        ),
    ]
)
