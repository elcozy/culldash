// swift-tools-version: 6.0
import PackageDescription

// CullDashCore holds everything that touches files (scanning, previews, XMP),
// with no UI, so it can be tested on its own. CullDash is the SwiftUI app.
let package = Package(
    name: "CullDash",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "CullDashCore"),
        .executableTarget(name: "CullDash", dependencies: ["CullDashCore"]),
        .testTarget(name: "CullDashCoreTests", dependencies: ["CullDashCore"]),
    ]
)
