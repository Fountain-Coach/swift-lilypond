// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-lilypond",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "LilyPondKit", targets: ["LilyPondKit"]),
        .executable(name: "lpkit", targets: ["lpkit"])
    ],
    targets: [
        // Stubbed binary artifact bundle; release engineering will replace contents per tag.
        .binaryTarget(
            name: "LilyPondBinaries",
            path: "Binaries/LilyPondBinaries.artifactbundle"
        ),
        .target(
            name: "LilyPondKit",
            dependencies: [
                // Keep the dependency so consumers get embedded artifacts in releases
                .target(name: "LilyPondBinaries", condition: .when(platforms: [.macOS]))
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "lpkit",
            dependencies: ["LilyPondKit"]
        ),
        .testTarget(
            name: "LilyPondKitTests",
            dependencies: ["LilyPondKit"]
        )
    ]
)

