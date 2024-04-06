// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "avtools",
  platforms: [.macOS(.v13)],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    .package(url: "https://github.com/skyfe79/CMTimeUtils.git", from: "0.0.1"),
  ],
  targets: [
    .executableTarget(
      name: "avtools",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "CMTimeUtils", package: "CMTimeUtils"),
      ],
      path: "Sources"
    ),
  ]
)
