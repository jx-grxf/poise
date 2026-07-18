import Charts
import SwiftUI

struct StatsView: View {
    @Environment(PostureStore.self) private var store
    @Environment(HistoryStore.self) private var history

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryTiles
                todaySection
                trendSection
                sensorSection
            }
            .padding(20)
        }
        .frame(minWidth: 480, minHeight: 480)
        .background(.background.secondary)
        .onAppear { history.loadPastDays(14) }
    }

    // MARK: - Summary tiles

    private var summaryTiles: some View {
        HStack(spacing: 12) {
            StatTile(
                title: "Score",
                value: store.score.map { "\($0)" } ?? "–",
                unit: store.score != nil ? "%" : nil,
                color: store.score.map(scoreColor) ?? .secondary
            )
            StatTile(
                title: "Tracked",
                value: formattedDuration(store.monitoredSeconds),
                unit: nil,
                color: .primary
            )
            StatTile(
                title: "Upright",
                value: formattedDuration(store.goodSeconds),
                unit: nil,
                color: .green
            )
            StatTile(
                title: "Alerts",
                value: "\(store.alertsToday)",
                unit: nil,
                color: store.alertsToday == 0 ? .primary : .orange
            )
        }
    }

    // MARK: - Today timeline

    private var todaySection: some View {
        StatsCard(title: "Today", subtitle: "Slouch share per minute") {
            if history.todayMinutes.isEmpty {
                emptyChartPlaceholder("Data appears after your first tracked minutes.")
            } else {
                Chart(history.todayMinutes) { minute in
                    BarMark(
                        x: .value("Time", minute.start, unit: .minute),
                        y: .value("Slouching", minute.slouchFraction * 100),
                        width: .automatic
                    )
                    .foregroundStyle(barColor(for: minute.slouchFraction))
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) { Text("\(v)%") }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .frame(height: 140)
            }
        }
    }

    // MARK: - 14-day trend

    private var trendSection: some View {
        StatsCard(title: "Trend", subtitle: "Daily posture score") {
            let days = trendDays
            if days.isEmpty {
                emptyChartPlaceholder("Come back tomorrow for your first trend data.")
            } else {
                Chart(days) { day in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Score", day.score ?? 0)
                    )
                    .foregroundStyle(scoreColor(day.score ?? 0).gradient)
                    .cornerRadius(3)
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.day(), centered: true)
                    }
                }
                .frame(height: 120)
            }
        }
    }

    private var trendDays: [DaySummary] {
        var days = history.pastDays
        if store.monitoredSeconds > 0 {
            days.append(DaySummary(
                day: Calendar.current.startOfDay(for: Date()),
                goodSeconds: store.goodSeconds,
                badSeconds: store.badSeconds
            ))
        }
        return days
    }

    // MARK: - Live sensors

    private var sensorSection: some View {
        StatsCard(title: "Live Sensors", subtitle: "Raw data from your AirPods") {
            if let sample = store.lastSample, store.connection == .tracking {
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 6) {
                    GridRow {
                        sensorValue("Pitch", sample.pitchDeg, unit: "°")
                        sensorValue("Roll", sample.rollDeg, unit: "°")
                        sensorValue("Yaw", sample.yawDeg, unit: "°")
                    }
                    GridRow {
                        sensorValue("Rotation", sample.rotationDps, unit: "°/s")
                        sensorValue("Acceleration", sample.accelerationG, unit: "g", precision: 2)
                        sensorValue("Forward drift", store.forwardDropDeg, unit: "°")
                    }
                }
            } else {
                emptyChartPlaceholder("Connect AirPods to see live sensor data.")
            }
        }
    }

    private func sensorValue(_ label: String, _ value: Double, unit: String, precision: Int = 1) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "%.\(precision)f%@", value, unit))
                .font(.system(.body, design: .rounded, weight: .medium))
                .monospacedDigit()
        }
        .frame(minWidth: 110, alignment: .leading)
    }

    // MARK: - Helpers

    private func emptyChartPlaceholder(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 80)
    }

    private func barColor(for slouchFraction: Double) -> Color {
        switch slouchFraction {
        case ..<0.25: return .green
        case ..<0.6: return .orange
        default: return .red
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case ..<60: return .red
        case ..<85: return .orange
        default: return .green
        }
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(total)s"
    }
}

// MARK: - Building blocks

private struct StatTile: View {
    let title: String
    let value: String
    let unit: String?
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                if let unit {
                    Text(unit)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(color.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct StatsCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
}
