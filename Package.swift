// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "mtlswift",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mtlswift",
                    targets: ["mtlswift"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser",
                 from: "1.2.2"),
        .package(url: "https://github.com/JohnSundell/Files",
                 from: "4.3.0")
    ],
    targets: [
        .executableTarget(
            name: "mtlswift",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Files"
            ]
        )
    ]
)
