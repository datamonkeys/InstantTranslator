// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InstantTranslator",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "InstantTranslator",
            path: "Sources/InstantTranslator",
            linkerSettings: [
                .linkedFramework("Carbon"),
            ]
        )
    ]
)
