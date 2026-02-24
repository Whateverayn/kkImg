// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "kkImgCore",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "kkImgCore",
            type: .dynamic,
            targets: ["kkImgCore"]
        ),
        .executable(
            name: "kkImgCoreCLI",
            targets: ["kkImgCoreCLI"]
        ),
    ],
    targets: [
        .target(
            name: "kkImgCore",
            path: "Sources/kkImgCore"
        ),
        .executableTarget(
            name: "kkImgCoreCLI",
            dependencies: ["kkImgCore"],
            path: "Sources/kkImgCoreCLI"
        ),
        .testTarget(
            name: "kkImgCoreTests",
            dependencies: ["kkImgCore"],
            path: "Tests/kkImgCoreTests"
        ),
    ]
)
