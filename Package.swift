// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftCalcTokenizer",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SwiftCalcTokenizer",
            targets: ["SwiftCalcTokenizer"]),
    ],
    targets: [
        .target(
            name: "SwiftCalcTokenizer"),
        .testTarget(
            name: "SwiftCalcTokenizerTests",
            dependencies: ["SwiftCalcTokenizer"]),
    ]
)