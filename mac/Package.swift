// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PufferPal",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PufferPal", targets: ["PufferPal"]),
        .library(name: "PufferCore", targets: ["PufferCore"]),
    ],
    targets: [
        .target(name: "PufferCore"),
        .executableTarget(
            name: "PufferPal",
            dependencies: ["PufferCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "PufferCoreTests",
            dependencies: ["PufferCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
