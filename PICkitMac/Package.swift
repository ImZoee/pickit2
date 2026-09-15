// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PICkitMac",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "PICkitMac", targets: ["PICkitMac"])
    ],
    targets: [
        .executableTarget(
            name: "PICkitMac",
            path: "Sources/PICkitMac"
        )
    ],
    swiftLanguageVersions: [.v5]
)
