// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LookAway",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "LookAway",
            path: "Sources/LookAway",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("CoreGraphics"),
            ]
        )
    ]
)
