// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_local_device_discovery_darwin",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15"),
    ],
    products: [
        .library(
            name: "flutter-local-device-discovery-darwin",
            targets: ["flutter_local_device_discovery_darwin"]
        ),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "flutter_local_device_discovery_darwin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            path: "Sources/flutter_local_device_discovery_darwin"
        ),
    ]
)