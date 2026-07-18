import SwiftUI

struct MenuBarView: View {
    @Environment(PostureStore.self) private var store
    private let updateService = UpdateService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)

            switch store.connection {
            case .tracking:
                trackingContent
            case .waiting:
                infoBlock(
                    symbol: "airpods",
                    title: "Waiting for AirPods",
                    message: "Connect AirPods (Pro, Max or 3rd gen) to this Mac and put them in your ears."
                )
            case .paused:
                infoBlock(
                    symbol: "pause.circle",
                    title: "Paused",
                    message: "Posture tracking is paused."
                )
            case .unavailable(let reason):
                infoBlock(
                    symbol: "exclamationmark.triangle",
                    title: "Not available",
                    message: reason
                )
            }

            actionRow
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

            Divider()

            footer
        }
        .frame(width: 320)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            if let score = store.score {
                Text("\(score)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor(score))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(scoreColor(score).opacity(0.15), in: Capsule())
                    .help("Today's posture score")
            }
        }
    }

    private var statusColor: Color {
        switch store.connection {
        case .tracking:
            guard store.isCalibrated else { return .orange }
            switch store.level {
            case .good: return .green
            case .warning: return .orange
            case .bad: return .red
            }
        case .waiting: return .orange
        case .paused: return .secondary.opacity(0.5)
        case .unavailable: return .red
        }
    }

    private var statusText: String {
        switch store.connection {
        case .tracking:
            if store.calibrationProgress != nil { return "Calibrating…" }
            if !store.isCalibrated { return "Needs calibration" }
            if store.isMoving { return "Moving" }
            switch store.level {
            case .good: return "Good posture"
            case .warning: return "Drifting"
            case .bad: return "Slouching"
            }
        case .waiting: return "Waiting for AirPods"
        case .paused: return "Paused"
        case .unavailable: return "Unavailable"
        }
    }

    // MARK: - Tracking content

    @ViewBuilder
    private var trackingContent: some View {
        if store.isCalibrated {
            VStack(alignment: .leading, spacing: 10) {
                PostureGauge(
                    label: "Forward drift",
                    value: store.forwardDropDeg,
                    threshold: store.slouchThresholdDeg
                )
                if store.tiltDetectionEnabled {
                    PostureGauge(
                        label: "Side tilt",
                        value: store.sideTiltDeg,
                        threshold: store.tiltThresholdDeg
                    )
                }
                todayLine
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 4)
        } else {
            infoBlock(
                symbol: "scope",
                title: "Set your baseline",
                message: "Sit upright the way you want to sit, then press Calibrate."
            )
        }
    }

    private var todayLine: some View {
        HStack {
            Text("Today")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(formattedDuration(store.monitoredSeconds) + " tracked")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func infoBlock(symbol: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
    }

    // MARK: - Actions

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                store.beginGuidedCalibration()
            } label: {
                if let progress = store.calibrationProgress {
                    Label("Hold still…", systemImage: "scope")
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .bottom) {
                            ProgressView(value: progress)
                                .controlSize(.mini)
                                .offset(y: 6)
                        }
                } else {
                    Label(store.isCalibrated ? "Recalibrate" : "Calibrate", systemImage: "scope")
                        .frame(maxWidth: .infinity)
                }
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(store.isCalibrated ? .secondary : .accentColor)
            .disabled(store.connection != .tracking || store.calibrationProgress != nil)

            Button {
                if store.connection == .paused {
                    store.resume()
                } else {
                    store.pause()
                }
            } label: {
                Image(systemName: store.connection == .paused ? "play.fill" : "pause.fill")
                    .frame(width: 24)
            }
            .controlSize(.large)
            .buttonStyle(.bordered)
            .help(store.connection == .paused ? "Resume tracking" : "Pause tracking")
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            FooterButton(title: "Statistics…", shortcut: "s") {
                StatsWindowController.show()
            }
            FooterButton(title: "Settings…", shortcut: ",") {
                SettingsWindowController.show(tab: .general)
            }
            FooterButton(
                title: updateService.availableUpdateVersion.map { "Update to \($0)…" } ?? "Check for Updates…"
            ) {
                updateService.checkForUpdates()
            }
            FooterButton(title: "Quit Poise", shortcut: "q") {
                NSApp.terminate(nil)
            }
        }
        .padding(6)
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(total)s"
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case ..<60: return .red
        case ..<85: return .orange
        default: return .green
        }
    }
}

// MARK: - Gauge

private struct PostureGauge: View {
    let label: String
    let value: Double
    let threshold: Double

    private var ratio: Double {
        guard threshold > 0 else { return 0 }
        return min(max(value / threshold, 0), 1.25)
    }

    private var color: Color {
        switch ratio {
        case ..<0.6: return .green
        case ..<1.0: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f°", max(value, 0)))
                    .font(.caption)
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)
                    Capsule()
                        .fill(color)
                        .frame(width: max(4, geo.size.width * ratio / 1.25))
                    // Threshold marker
                    Rectangle()
                        .fill(.secondary)
                        .frame(width: 1.5)
                        .offset(x: geo.size.width / 1.25)
                }
            }
            .frame(height: 5)
            .animation(.easeOut(duration: 0.25), value: ratio)
        }
    }
}

// MARK: - Footer button

private struct FooterButton: View {
    let title: String
    var shortcut: KeyEquivalent?
    let action: () -> Void
    @State private var isHovered = false

    init(title: String, shortcut: KeyEquivalent? = nil, action: @escaping () -> Void) {
        self.title = title
        self.shortcut = shortcut
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovered ? Color.secondary.opacity(0.15) : .clear, in: RoundedRectangle(cornerRadius: 5))
        .onHover { isHovered = $0 }
        .applyShortcut(shortcut)
    }
}

private extension View {
    @ViewBuilder
    func applyShortcut(_ shortcut: KeyEquivalent?) -> some View {
        if let shortcut {
            keyboardShortcut(shortcut, modifiers: .command)
        } else {
            self
        }
    }
}
