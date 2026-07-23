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
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "ProfilePilot",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/ProfilePilot",
            exclude: [
                "Resources/Info.plist",
                "Resources/ProfilePilot.entitlements"
            ],
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
