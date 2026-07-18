import ProjectDescription

let project = Project(
    name: "Poise",
    targets: [
        .target(
            name: "Poise",
            destinations: .macOS,
            product: .app,
            bundleId: "com.johannesgrof.Poise",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "0.1.0",
                "CFBundleVersion": "1",
                "LSUIElement": true,
                "LSMinimumSystemVersion": "14.0",
                "NSMotionUsageDescription": "Poise uses your AirPods' motion sensors to track your head posture and remind you to sit upright.",
                "SUFeedURL": "https://raw.githubusercontent.com/jx-grxf/poise/main/appcast.xml",
                "SUPublicEDKey": "43WfpQK+dEMeXkjBQ/Q9oxPXvbnLiOPpRiUTAqZ+jCk=",
                "SUEnableInstallerLauncherService": true,
            ]),
            sources: ["Sources/**"],
            dependencies: [
                .external(name: "Sparkle")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "M45V83ZMD8",
                    "CODE_SIGN_STYLE": "Automatic",
                    "SWIFT_VERSION": "5.10",
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release", settings: [
                        "ENABLE_HARDENED_RUNTIME": "YES",
                        "CODE_SIGN_IDENTITY": "Developer ID Application",
                    ]),
                ]
            )
        )
    ]
)
