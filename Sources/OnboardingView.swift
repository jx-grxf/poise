import SwiftUI

struct OnboardingView: View {
    @Environment(PostureStore.self) private var store

    private enum Step: Int, CaseIterable {
        case welcome, connect, calibrate, done
    }

    @State private var step: Step = .welcome
    @State private var calibrationFinished = false

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 40)
                .padding(.top, 32)

            footer
                .padding(24)
        }
        .frame(width: 480, height: 560)
        .background(.background)
    }

    // MARK: - Steps

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome: welcome
        case .connect: connect
        case .calibrate: calibrate
        case .done: done
        }
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.stand")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(.tint)
                .padding(.top, 24)

            Text("Welcome to Poise")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Poise turns your AirPods into a posture coach.\nEverything runs locally on your Mac.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 14) {
                featureRow(symbol: "airpods", title: "Uses your AirPods", text: "The built-in motion sensors track your head position — no camera.")
                featureRow(symbol: "bell.badge", title: "Gentle nudges", text: "A quiet notification only when bad posture persists.")
                featureRow(symbol: "chart.bar.xaxis", title: "Daily insights", text: "A posture score and trends, right in your menu bar.")
            }
            .padding(.top, 8)
        }
    }

    private var connect: some View {
        VStack(spacing: 20) {
            Image(systemName: "airpods")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(store.connection == .tracking ? .green : .secondary)
                .padding(.top, 24)
                .animation(.default, value: store.connection)

            Text("Connect your AirPods")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text("Put your AirPods in your ears and make sure they're connected to this Mac — play any audio briefly if they don't switch over.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Group {
                switch store.connection {
                case .tracking:
                    Label("Receiving motion data", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .unavailable(let reason):
                    Label(reason, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                default:
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Waiting for AirPods…")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.system(size: 14, weight: .medium))
            .padding(.top, 12)

            Text("macOS may ask for permission to access motion data — allow it.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    private var calibrate: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 6)
                    .frame(width: 110, height: 110)
                Circle()
                    .trim(from: 0, to: store.calibrationProgress ?? (calibrationFinished ? 1 : 0))
                    .stroke(.tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: store.calibrationProgress)

                if calibrationFinished {
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(.tint)
                }
            }
            .padding(.top, 24)

            Text(calibrationFinished ? "Baseline set" : "Set your baseline")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text(calibrationFinished
                 ? "Poise now knows your upright posture. You can recalibrate anytime from the menu bar."
                 : "Sit the way you want to sit: upright, shoulders relaxed, eyes on the screen. Then hold still for three seconds.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if !calibrationFinished {
                Button {
                    store.beginGuidedCalibration(duration: 3) {
                        calibrationFinished = true
                    }
                } label: {
                    Text(store.calibrationProgress != nil ? "Hold still…" : "Start Calibration")
                        .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(store.connection != .tracking || store.calibrationProgress != nil)
                .padding(.top, 8)

                if store.connection != .tracking {
                    Text("Waiting for AirPods motion data…")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var done: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .padding(.top, 24)

            Text("You're all set")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Poise lives in your menu bar. The icon shows how you're sitting:\nit turns orange when you drift and red when you slouch.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                legend(color: .green, text: "Upright")
                legend(color: .orange, text: "Drifting")
                legend(color: .red, text: "Slouching")
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if step != .welcome && step != .done {
                Button("Back") {
                    withAnimation { step = Step(rawValue: step.rawValue - 1) ?? .welcome }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                advance()
            } label: {
                Text(nextButtonTitle)
                    .frame(minWidth: 100)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(step == .calibrate && !calibrationFinished && store.connection != .tracking && !canSkipCalibration)
        }
    }

    private var nextButtonTitle: String {
        switch step {
        case .welcome: "Get Started"
        case .connect: store.connection == .tracking ? "Continue" : "Skip for Now"
        case .calibrate: calibrationFinished ? "Continue" : "Skip for Now"
        case .done: "Start Sitting Tall"
        }
    }

    private var canSkipCalibration: Bool { true }

    private func advance() {
        switch step {
        case .done:
            store.hasCompletedOnboarding = true
            OnboardingWindowController.close()
        default:
            withAnimation { step = Step(rawValue: step.rawValue + 1) ?? .done }
        }
    }

    // MARK: - Building blocks

    private func featureRow(symbol: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func legend(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
