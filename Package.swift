// swift-tools-version: 5.9
import PackageDescription
let package = Package(
  name: "Tetris",
  platforms: [.iOS(.v17)],
  products: [
    .executable(name: "Tetris", targets: ["Tetris"])
  ],
  targets: [
    .executableTarget(name: "Tetris", path: "Sources")
  ]
)
