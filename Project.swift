import ProjectDescription

// Overridable from CI: TUIST_APP_VERSION / TUIST_BUILD_NUMBER
let appVersion = Environment.appVersion.getString(default: "0.1.0")
let buildNumber = Environment.buildNumber.getString(default: "1")

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
                "CFBundleShortVersionString": .string(appVersion),
                "CFBundleVersion": .string(buildNumber),
                "LSUIElement": true,
                "LSMinimumSystemVersion": "14.0",
                "NSMotionUsageDescription": "Poise uses your AirPods' motion sensors to track your head posture and remind you to sit upright.",
                "SUFeedURL": "https://github.com/jx-grxf/poise/releases/latest/download/appcast.xml",
                "SUPublicEDKey": "43WfpQK+dEMeXkjBQ/Q9oxPXvbnLiOPpRiUTAqZ+jCk=",
                "SUEnableInstallerLauncherService": true,
                "SUEnableAutomaticChecks": true,
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .external(name: "Sparkle")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "M45V83ZMD8",
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_STYLE": "Automatic",
                    "SWIFT_VERSION": "5.10",
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release", settings: [
                        "ENABLE_HARDENED_RUNTIME": "YES",
                        "CODE_SIGN_STYLE": "Manual",
                        "CODE_SIGN_IDENTITY": "Developer ID Application",
                        "PROVISIONING_PROFILE_SPECIFIER": "",
                        "CODE_SIGN_INJECT_BASE_ENTITLEMENTS": "NO",
                        "OTHER_CODE_SIGN_FLAGS": "--timestamp",
                    ]),
                ]
            )
        )
    ]
)
