// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MyFocus",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FocusCore",
            targets: ["FocusCore"]
        ),
        .executable(
            name: "MyFocusApp",
            targets: ["MyFocusApp"]
        ),
        .executable(
            name: "FocusHelper",
            targets: ["FocusHelper"]
        )
    ],
    targets: [
        .target(
            name: "FocusCore"
        ),
        .executableTarget(
            name: "MyFocusApp",
            dependencies: ["FocusCore"]
        ),
        .executableTarget(
            name: "FocusHelper",
            dependencies: ["FocusCore"]
        ),
        .testTarget(
            name: "FocusCoreTests",
            dependencies: ["FocusCore"]
        )
    ]
)
