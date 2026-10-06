import ProjectDescription

let project = Project(
    name: "Spellbound",
    packages: [.local(path: "Packages/SpellboundKit")],
    settings: .settings(base: ["SWIFT_VERSION": "6.0"]),
    targets: [
        .target(
            name: "SpellboundFixture",
            destinations: .macOS,
            product: .app,
            bundleId: "dev.spellbound.fixture",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["Apps/SpellboundFixture/Sources/**"]
        ),
        .target(
            name: "SpellboundMac",
            destinations: .macOS,
            product: .app,
            bundleId: "dev.spellbound.mac",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Spellbound",
                "CFBundleIconFile": "Spellbound",
                "LSUIElement": true,
                "LSApplicationCategoryType": "public.app-category.education",
            ]),
            sources: ["Apps/SpellboundMac/Sources/**"],
            resources: ["Apps/SpellboundMac/Resources/**"],
            dependencies: [
                .package(product: "SpellboundCore"),
                .package(product: "SpellboundUI"),
                .package(product: "SpellboundMacIntegration"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "SpellboundMac",
            shared: true,
            buildAction: .buildAction(targets: ["SpellboundMac"]),
            runAction: .runAction(configuration: .debug, executable: "SpellboundMac")
        ),
    ]
)
