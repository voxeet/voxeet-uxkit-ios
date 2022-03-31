// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "VoxeetUXKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "VoxeetUXKit", targets: ["VoxeetUXKit"])
    ],
    dependencies: [
      .package(
        name: "VoxeetSDK",
        url: "https://github.com/voxeet/voxeet-sdk-ios.git",
        from: "3.3.3"
      ),
      .package(
        name: "Kingfisher",
        url: "https://github.com/onevcat/Kingfisher.git",
        from: "7.1.0"
      )
    ],
    targets:
        [
        .target(
            name: "VoxeetUXKit",
            dependencies: [
                Target.Dependency.byName(name: "VoxeetSDK"),
                Target.Dependency.byName(name: "Kingfisher")
            ],
            path: "VoxeetUXKit",
            resources: [
                .process("Assets"),
                .process("Other")
            ])
    ]
)
