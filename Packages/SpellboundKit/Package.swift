// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SpellboundKit",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "SpellboundCore", targets: ["SpellboundCore"]),
        .library(name: "SpellboundUI", targets: ["SpellboundUI"]),
        .library(name: "SpellboundMacIntegration", targets: ["SpellboundMacIntegration"]),
        .executable(name: "spellbound-probe", targets: ["SpellboundProbe"]),
    ],
    targets: [
        .target(name: "SpellboundCore"),
        .target(name: "SpellboundUI", dependencies: ["SpellboundCore"]),
        .target(name: "SpellboundMacIntegration", dependencies: ["SpellboundCore"]),
        .executableTarget(name: "SpellboundProbe", dependencies: ["SpellboundMacIntegration"]),
        .testTarget(name: "SpellboundCoreTests", dependencies: ["SpellboundCore"]),
    ]
)
