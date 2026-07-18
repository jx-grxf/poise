import ServiceManagement
import SwiftUI

// MARK: - General

struct GeneralSettingsPane: View {
    @Environment(PostureStore.self) private var store
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        @Bindable var store = store
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { _, enable in
                        do {
                            if enable {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }

            Section("Menu Bar") {
                Toggle(isOn: $store.showScoreInMenuBar) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show posture score in menu bar")
                        Text("Displays today's score next to the status icon.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }

            Section("Alerts") {
                Toggle(isOn: $store.alertsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notify me when I slouch")
                        Text("Shows a notification once bad posture persists.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)

                Toggle("Play sound", isOn: $store.alertSoundEnabled)
                    .toggleStyle(.switch)
                    .disabled(!store.alertsEnabled)

                Picker("Remind me again after", selection: $store.alertCooldownSeconds) {
                    Text("30 seconds").tag(30.0)
                    Text("1 minute").tag(60.0)
                    Text("5 minutes").tag(300.0)
                    Text("15 minutes").tag(900.0)
                }
                .pickerStyle(.menu)
                .disabled(!store.alertsEnabled)

                Toggle(isOn: $store.pauseWhileMoving) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pause while moving")
                        Text("Suppresses alerts and tracking while you're walking or moving around.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
    }
}

// MARK: - Detection

struct DetectionSettingsPane: View {
    @Environment(PostureStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Form {
            Section("Forward slouch") {
                LabeledContent("Sensitivity") {
                    HStack(spacing: 12) {
                        Slider(value: $store.slouchThresholdDeg, in: 5...30, step: 1)
                            .frame(width: 180)
                        Text("\(Int(store.slouchThresholdDeg))°")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
                Text("Alert when your head drops this far forward from your calibrated baseline. Lower is stricter.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Side tilt") {
                Toggle("Detect side tilt", isOn: $store.tiltDetectionEnabled)
                    .toggleStyle(.switch)

                LabeledContent("Sensitivity") {
                    HStack(spacing: 12) {
                        Slider(value: $store.tiltThresholdDeg, in: 5...30, step: 1)
                            .frame(width: 180)
                        Text("\(Int(store.tiltThresholdDeg))°")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
                .disabled(!store.tiltDetectionEnabled)
            }

            Section("Timing") {
                LabeledContent("Grace period") {
                    HStack(spacing: 12) {
                        Slider(value: $store.graceSeconds, in: 3...60, step: 1)
                            .frame(width: 180)
                        Text("\(Int(store.graceSeconds))s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
                Text("How long bad posture must persist before it counts as slouching. Prevents alerts when you briefly look down.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Calibration") {
                HStack(spacing: 8) {
                    Button("Recalibrate Now") {
                        store.calibrate()
                    }
                    .controlSize(.small)
                    .disabled(store.connection != .tracking)

                    Button("Reset Calibration") {
                        store.resetCalibration()
                    }
                    .controlSize(.small)
                    .disabled(!store.isCalibrated)
                }
                if store.isCalibrated {
                    Text("Baseline is set. Recalibrate whenever you change your seating position.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No baseline set. Sit upright and press Calibrate in the menu bar panel.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
    }
}

// MARK: - About

struct AboutSettingsPane: View {
    @ObservedObject private var updaterManager = UpdaterManager.shared

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Poise")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text(AppVersion.displayString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("by Johannes Grof · MIT License")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                Text("Turns your AirPods into a posture coach. All motion analysis runs locally on your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Updates") {
                Toggle(isOn: Binding(
                    get: { updaterManager.automaticallyChecksForUpdates },
                    set: { updaterManager.automaticallyChecksForUpdates = $0 }
                )) {
                    Text("Automatically check for updates")
                }
                .toggleStyle(.switch)

                Button("Check for Updates…") {
                    updaterManager.checkForUpdates()
                }
                .controlSize(.small)
                .disabled(!updaterManager.canCheckForUpdates)
            }

            Section("Links") {
                Link("Source on GitHub", destination: URL(string: "https://github.com/jx-grxf/poise")!)
                Link("MIT License", destination: URL(string: "https://github.com/jx-grxf/poise/blob/main/LICENSE")!)
                Link("Report an Issue", destination: URL(string: "https://github.com/jx-grxf/poise/issues")!)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
    }
}
