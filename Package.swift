// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "swift-mini-redux",
    platforms: [
      .iOS(.v17),
      .macOS(.v10_15),
      .tvOS(.v13),
      .watchOS(.v6),
    ],
    products: [
        .library(
            name: "MiniRedux",
            targets: ["MiniRedux"]),
    ],
    targets: [
        .target(name: "MiniRedux"),
        .testTarget(
            name: "MiniReduxTests",
            dependencies: ["MiniRedux"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
