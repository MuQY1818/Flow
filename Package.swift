// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TomatoClock",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "TomatoClock",
            path: "Sources/TomatoClock"
        )
    ]
)
