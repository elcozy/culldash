// swift-tools-version: 6.0
import PackageDescription

// WinnowCore holds everything that touches files (scanning, previews, XMP),
// with no UI, so it can be tested on its own. Winnow is the SwiftUI app.
let package = Package(
    name: "Winnow",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "WinnowCore"),
        .executableTarget(name: "Winnow", dependencies: ["WinnowCore"]),
        .testTarget(name: "WinnowCoreTests", dependencies: ["WinnowCore"]),
    ]
)
