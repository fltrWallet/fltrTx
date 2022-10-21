// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "fltrTx",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "fltrTx",
            targets: ["fltrTx"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio", from: "2.0.0"),
        .package(url: "https://github.com/fltrWallet/bech32", branch: "main"),
        .package(url: "https://github.com/fltrWallet/fltrECC", branch: "main"),
        .package(url: "https://github.com/fltrWallet/HaByLo", branch: "main"),
    ],
    targets: [
        .target(
            name: "fltrTx",
            dependencies: [ .product(name: "NIOCore", package: "swift-nio"),
                            "bech32",
                            "fltrECC",
                            "HaByLo", ]),
        .testTarget(
            name: "fltrTxTests",
            dependencies: [ "fltrTx",
                            .product(name: "fltrECCTesting", package: "fltrECC"),
                            .product(name: "NIOCore", package: "swift-nio"), ],
            resources: [ .process("Resources"), ] ),
    ]
)
