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
        .library(
            name: "SwiftCalcParser",
            targets: ["SwiftCalcParser"]),
        .executable(
            name: "swift-calc-demo",
            targets: ["SwiftCalcDemo"]),
    ],
    targets: [
        .target(
            name: "SwiftCalcTokenizer"),
        .target(
            name: "SwiftCalcParser",
            dependencies: ["SwiftCalcTokenizer"]),
        .executableTarget(
            name: "SwiftCalcDemo",
            dependencies: ["SwiftCalcTokenizer", "SwiftCalcParser"]),
        .testTarget(
            name: "SwiftCalcTokenizerTests",
            dependencies: ["SwiftCalcTokenizer"]),
        .testTarget(
            name: "SwiftCalcParserTests",
            dependencies: ["SwiftCalcParser", "SwiftCalcTokenizer"]),
    ]
)