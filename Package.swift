// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "swift-color",
    platforms: [
        // Value generics and InlineArray ship in the OS standard library, so on
        // Apple platforms they require the 2025-era releases.
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        // The directory / repo is `swift-color`, but the importable module is `Color`.
        .library(name: "Color", targets: ["Color"]),
    ],
    targets: [
        .target(name: "Color"),
        .testTarget(
            name: "ColorTests",
            dependencies: ["Color"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
