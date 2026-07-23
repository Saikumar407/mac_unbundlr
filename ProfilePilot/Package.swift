// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ProfilePilot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ProfilePilot", targets: ["ProfilePilot"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ProfilePilot",
            path: "Sources/ProfilePilot",
            exclude: ["Resources/Info.plist", "Resources/ProfilePilot.entitlements"],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "ProfilePilotTests",
            dependencies: ["ProfilePilot"],
            path: "Tests/ProfilePilotTests"
        )
    ]
)
