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
        // Tool used by the plugin to generate a Swift file with the embedded tool path
        .executableTarget(
            name: "lp-path-gen",
            path: "Tools/lp-path-gen"
        ),
        // Plugin that discovers the artifact tool path and generates Swift code
        .plugin(
            name: "LilyPondPathPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "lp-path-gen"),
                .target(name: "LilyPondBinaries")
            ]
        ),
        .target(
            name: "LilyPondKit",
            dependencies: [
                // Keep the dependency so consumers get embedded artifacts in releases
                .target(name: "LilyPondBinaries", condition: .when(platforms: [.macOS, .linux]))
            ],
            resources: [
                .process("Resources")
            ],
            plugins: ["LilyPondPathPlugin"]
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
