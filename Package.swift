// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Burnline",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Burnline", targets: ["Burnline"])
    ],
    targets: [
        .target(name: "BurnlineCore"),
        .executableTarget(
            name: "Burnline",
            dependencies: ["BurnlineCore"]
        ),
        .testTarget(
            name: "BurnlineCoreTests",
            dependencies: ["BurnlineCore"]
        )
    ]
)
