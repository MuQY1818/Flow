// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Flow",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Flow",
            path: "Sources/Flow"
        )
    ]
)
