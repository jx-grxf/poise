import Foundation
import Observation

/// One minute of aggregated posture data.
struct MinuteSample: Codable, Identifiable {
    let start: Date
    var goodSeconds: Double
    var badSeconds: Double
    var avgDropDeg: Double

    var id: Date { start }

    var slouchFraction: Double {
        let total = goodSeconds + badSeconds
        guard total > 0 else { return 0 }
        return badSeconds / total
    }
}

/// Aggregated posture data for one calendar day.
struct DaySummary: Identifiable {
    let day: Date
    let goodSeconds: Double
    let badSeconds: Double

    var id: Date { day }

    var monitoredSeconds: Double { goodSeconds + badSeconds }

    var score: Int? {
        guard monitoredSeconds > 0 else { return nil }
        return Int((goodSeconds / monitoredSeconds * 100).rounded())
    }
}

/// Persists per-minute posture history as one JSON file per day in
/// ~/Library/Application Support/Poise/History/.
@MainActor
@Observable
final class HistoryStore {
    static let shared = HistoryStore()

    private(set) var todayMinutes: [MinuteSample] = []
    private(set) var pastDays: [DaySummary] = []

    private var currentDay: Date
    private let directory: URL

    private init() {
        currentDay = Calendar.current.startOfDay(for: Date())
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        directory = support.appendingPathComponent("Poise/History", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        todayMinutes = load(day: currentDay)
    }

    func append(_ sample: MinuteSample) {
        let sampleDay = Calendar.current.startOfDay(for: sample.start)
        if sampleDay != currentDay {
            currentDay = sampleDay
            todayMinutes = load(day: sampleDay)
        }
        todayMinutes.append(sample)
        save(todayMinutes, day: sampleDay)
    }

    func todayTotals() -> (good: Double, bad: Double) {
        todayMinutes.reduce(into: (0.0, 0.0)) { totals, sample in
            totals.0 += sample.goodSeconds
            totals.1 += sample.badSeconds
        }
    }

    /// Loads summaries for the last `count` days (excluding today) into `pastDays`.
    func loadPastDays(_ count: Int = 14) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var summaries: [DaySummary] = []
        for offset in 1...count {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let minutes = load(day: day)
            guard !minutes.isEmpty else { continue }
            summaries.append(DaySummary(
                day: day,
                goodSeconds: minutes.reduce(0) { $0 + $1.goodSeconds },
                badSeconds: minutes.reduce(0) { $0 + $1.badSeconds }
            ))
        }
        pastDays = summaries.sorted { $0.day < $1.day }
    }

    // MARK: - File I/O

    private func fileURL(day: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return directory.appendingPathComponent("\(formatter.string(from: day)).json")
    }

    private func load(day: Date) -> [MinuteSample] {
        guard let data = try? Data(contentsOf: fileURL(day: day)) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([MinuteSample].self, from: data)) ?? []
    }

    private func save(_ samples: [MinuteSample], day: Date) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(samples) else { return }
        try? data.write(to: fileURL(day: day), options: .atomic)
    }
}
