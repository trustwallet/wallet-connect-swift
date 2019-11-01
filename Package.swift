// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "WalletConnect",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
    ],
    products: [
        .library(name: "WalletConnect", targets: ["WalletConnect"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.1.0"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.8.0"),
        .package(url: "https://github.com/daltoniam/Starscream", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "WalletConnect",
            dependencies: ["CryptoSwift", "PromiseKit", "Starscream"],
            path: "WalletConnect"
        ),
    ]
)
