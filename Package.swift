// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "VoxeetUXKit",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "VoxeetUXKit", targets: ["VoxeetUXKit"])
    ],
    targets: [
        .target(name: "VoxeetUXKit", dependencies: []),
        .testTarget(name: "VoxeetUXKitTests", dependencies: ["VoxeetUXKit"])
    ]
)
