// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "runnerctl",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "runnerctl", targets: ["RunnerctlCLI"])
    ],
    targets: [
        .target(
            name: "RunnerctlCore"
        ),
        .executableTarget(
            name: "RunnerctlCLI",
            dependencies: ["RunnerctlCore"]
        ),
        .testTarget(
            name: "RunnerctlTests",
            dependencies: ["RunnerctlCore"]
        )
    ]
)
