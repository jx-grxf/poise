import AppKit
import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class PostureStore {
    static let shared = PostureStore()

    enum ConnectionState: Equatable {
        case waiting      // monitoring, no AirPods delivering data yet
        case tracking
        case paused
        case unavailable(String)
    }

    enum PostureLevel {
        case good, warning, bad
    }

    // MARK: - Live state

    private(set) var connection: ConnectionState = .waiting
    private(set) var pitchDeg: Double = 0
    private(set) var rollDeg: Double = 0
    private(set) var lastSample: MotionSample?
    private(set) var isSlouching = false
    private(set) var isMoving = false
    private(set) var lastSampleAt: Date?

    /// Throttled display state for the menu bar label: only mutated when the
    /// value actually changes, so the label doesn't re-render per sensor sample.
    private(set) var level: PostureLevel = .good
    private(set) var displayScore: Int?

    /// 0...1 progress while a guided calibration is running, nil otherwise.
    private(set) var calibrationProgress: Double?

    // MARK: - Calibration (persisted)

    private(set) var baselinePitchDeg: Double?
    private(set) var baselineRollDeg: Double?

    var isCalibrated: Bool { baselinePitchDeg != nil }

    // MARK: - Today stats

    private(set) var goodSeconds: TimeInterval = 0
    private(set) var badSeconds: TimeInterval = 0
    private(set) var alertsToday = 0
    private var statsDay = Calendar.current.startOfDay(for: Date())

    var monitoredSeconds: TimeInterval { goodSeconds + badSeconds }

    /// 0...100, or nil before any data.
    var score: Int? {
        guard monitoredSeconds > 0 else { return nil }
        return Int((goodSeconds / monitoredSeconds * 100).rounded())
    }

    // MARK: - Settings (persisted)

    var slouchThresholdDeg: Double { didSet { defaults.set(slouchThresholdDeg, forKey: Keys.slouchThreshold) } }
    var tiltThresholdDeg: Double { didSet { defaults.set(tiltThresholdDeg, forKey: Keys.tiltThreshold) } }
    var tiltDetectionEnabled: Bool { didSet { defaults.set(tiltDetectionEnabled, forKey: Keys.tiltEnabled) } }
    var graceSeconds: Double { didSet { defaults.set(graceSeconds, forKey: Keys.grace) } }
    var alertCooldownSeconds: Double { didSet { defaults.set(alertCooldownSeconds, forKey: Keys.cooldown) } }
    var alertsEnabled: Bool { didSet { defaults.set(alertsEnabled, forKey: Keys.alertsEnabled) } }
    var alertSoundEnabled: Bool { didSet { defaults.set(alertSoundEnabled, forKey: Keys.soundEnabled) } }
    var pauseWhileMoving: Bool { didSet { defaults.set(pauseWhileMoving, forKey: Keys.pauseWhileMoving) } }
    var showScoreInMenuBar: Bool { didSet { defaults.set(showScoreInMenuBar, forKey: Keys.showScore) } }

    var hasCompletedOnboarding: Bool { didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.onboarded) } }

    // MARK: - Derived posture values

    /// Degrees the head has dropped forward relative to the calibrated baseline.
    var forwardDropDeg: Double {
        guard let baseline = baselinePitchDeg else { return 0 }
        return baseline - pitchDeg
    }

    /// Absolute side-tilt deviation from baseline.
    var sideTiltDeg: Double {
        guard let baseline = baselineRollDeg else { return 0 }
        return abs(rollDeg - baseline)
    }

    /// Worst deviation as a fraction of its threshold (1.0 = at the limit).
    var deviationRatio: Double {
        guard isCalibrated else { return 0 }
        var ratio = forwardDropDeg / max(slouchThresholdDeg, 1)
        if tiltDetectionEnabled {
            ratio = max(ratio, sideTiltDeg / max(tiltThresholdDeg, 1))
        }
        return max(ratio, 0)
    }

    var isBadPosture: Bool {
        guard isCalibrated, connection == .tracking else { return false }
        return deviationRatio >= 1
    }

    var postureLevel: PostureLevel {
        if isSlouching || isBadPosture { return .bad }
        return deviationRatio >= 0.6 ? .warning : .good
    }

    // MARK: - Private

    private let client = HeadphoneMotionClient()
    private let defaults = UserDefaults.standard
    private var badSince: Date?
    private var lastAlertAt: Date?
    private let smoothingAlpha = 0.15
    private var hasSample = false

    // Movement detection (EMA over acceleration + rotation)
    private var movementLevel: Double = 0
    private var movingSince: Date?

    // Guided calibration
    private var calibrationSamples: [(pitch: Double, roll: Double)] = []
    private var calibrationStart: Date?
    private var calibrationDuration: TimeInterval = 3
    private var calibrationCompletion: (() -> Void)?

    // Minute bucketing for history
    private var minuteStart: Date?
    private var minuteGood: TimeInterval = 0
    private var minuteBad: TimeInterval = 0
    private var minuteDropSum: Double = 0
    private var minuteSampleCount = 0

    private enum Keys {
        static let baselinePitch = "baselinePitchDeg"
        static let baselineRoll = "baselineRollDeg"
        static let slouchThreshold = "slouchThresholdDeg"
        static let tiltThreshold = "tiltThresholdDeg"
        static let tiltEnabled = "tiltDetectionEnabled"
        static let grace = "graceSeconds"
        static let cooldown = "alertCooldownSeconds"
        static let alertsEnabled = "alertsEnabled"
        static let soundEnabled = "alertSoundEnabled"
        static let pauseWhileMoving = "pauseWhileMoving"
        static let showScore = "showScoreInMenuBar"
        static let onboarded = "hasCompletedOnboarding"
        static let alertsToday = "alertsTodayCount"
        static let alertsTodayDay = "alertsTodayDay"
    }

    private init() {
        slouchThresholdDeg = defaults.object(forKey: Keys.slouchThreshold) as? Double ?? 15
        tiltThresholdDeg = defaults.object(forKey: Keys.tiltThreshold) as? Double ?? 12
        tiltDetectionEnabled = defaults.object(forKey: Keys.tiltEnabled) as? Bool ?? true
        graceSeconds = defaults.object(forKey: Keys.grace) as? Double ?? 10
        alertCooldownSeconds = defaults.object(forKey: Keys.cooldown) as? Double ?? 60
        alertsEnabled = defaults.object(forKey: Keys.alertsEnabled) as? Bool ?? true
        alertSoundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        pauseWhileMoving = defaults.object(forKey: Keys.pauseWhileMoving) as? Bool ?? true
        showScoreInMenuBar = defaults.object(forKey: Keys.showScore) as? Bool ?? true
        hasCompletedOnboarding = defaults.object(forKey: Keys.onboarded) as? Bool ?? false
        baselinePitchDeg = defaults.object(forKey: Keys.baselinePitch) as? Double
        baselineRollDeg = defaults.object(forKey: Keys.baselineRoll) as? Double

        // Restore today's totals from persisted history.
        let todayTotals = HistoryStore.shared.todayTotals()
        goodSeconds = todayTotals.good
        badSeconds = todayTotals.bad
        if defaults.string(forKey: Keys.alertsTodayDay) == Self.dayKey(for: Date()) {
            alertsToday = defaults.integer(forKey: Keys.alertsToday)
        }

        client.onEvent = { [weak self] event in
            self?.handle(event)
        }
    }

    // MARK: - Lifecycle

    func startMonitoring() {
        if client.isDenied {
            connection = .unavailable("Motion access denied in System Settings → Privacy & Security.")
            return
        }
        requestNotificationPermission()
        connection = .waiting
        client.start()
    }

    func pause() {
        client.stop()
        connection = .paused
        resetSlouchTracking()
        hasSample = false
    }

    func resume() {
        connection = .waiting
        client.start()
    }

    // MARK: - Calibration

    /// Snapshot calibration from the current smoothed values.
    func calibrate() {
        guard connection == .tracking else { return }
        setBaseline(pitch: pitchDeg, roll: rollDeg)
    }

    /// Guided calibration: averages samples over `duration` seconds.
    func beginGuidedCalibration(duration: TimeInterval = 3, completion: (() -> Void)? = nil) {
        guard connection == .tracking, calibrationProgress == nil else { return }
        calibrationSamples = []
        calibrationStart = Date()
        calibrationDuration = duration
        calibrationCompletion = completion
        calibrationProgress = 0
    }

    func cancelGuidedCalibration() {
        calibrationProgress = nil
        calibrationSamples = []
        calibrationStart = nil
        calibrationCompletion = nil
    }

    func resetCalibration() {
        baselinePitchDeg = nil
        baselineRollDeg = nil
        defaults.removeObject(forKey: Keys.baselinePitch)
        defaults.removeObject(forKey: Keys.baselineRoll)
        resetSlouchTracking()
    }

    private func setBaseline(pitch: Double, roll: Double) {
        baselinePitchDeg = pitch
        baselineRollDeg = roll
        defaults.set(pitch, forKey: Keys.baselinePitch)
        defaults.set(roll, forKey: Keys.baselineRoll)
        resetSlouchTracking()
    }

    private func resetSlouchTracking() {
        badSince = nil
        isSlouching = false
    }

    // MARK: - Event handling

    private func handle(_ event: HeadphoneMotionClient.Event) {
        switch event {
        case .connected:
            if connection != .paused { connection = .waiting }
        case .disconnected:
            if connection == .tracking { connection = .waiting }
            resetSlouchTracking()
            hasSample = false
            flushMinuteBucket()
        case .failed(let message):
            connection = .unavailable(message)
        case .motion(let sample):
            guard connection != .paused else { return }
            process(sample)
        }
    }

    private func process(_ sample: MotionSample) {
        connection = .tracking
        rollOverDayIfNeeded()
        lastSample = sample

        if hasSample {
            pitchDeg += smoothingAlpha * (sample.pitchDeg - pitchDeg)
            rollDeg += smoothingAlpha * (sample.rollDeg - rollDeg)
        } else {
            pitchDeg = sample.pitchDeg
            rollDeg = sample.rollDeg
            hasSample = true
        }

        let now = Date()
        updateMovement(sample, now: now)
        updateCalibration(now: now)

        // Accumulate stats using wall-clock delta, capped so gaps
        // (AirPods out of ear, machine sleep) don't inflate the numbers.
        if isCalibrated, calibrationProgress == nil, !isMoving, let last = lastSampleAt {
            let dt = min(now.timeIntervalSince(last), 1.0)
            let bad = deviationRatio >= 1
            if bad { badSeconds += dt; minuteBad += dt } else { goodSeconds += dt; minuteGood += dt }
            minuteDropSum += max(forwardDropDeg, 0)
            minuteSampleCount += 1
            bucketMinute(now: now)
        }
        lastSampleAt = now

        updateSlouchState(now: now)
        updateDisplayState()
    }

    private func updateDisplayState() {
        let newLevel = postureLevel
        if newLevel != level { level = newLevel }
        let newScore = score
        if newScore != displayScore { displayScore = newScore }
    }

    private func updateMovement(_ sample: MotionSample, now: Date) {
        // Walking/talking produces sustained acceleration + rotation.
        let instant = sample.accelerationG * 4 + sample.rotationDps / 100
        movementLevel += 0.08 * (instant - movementLevel)
        let moving = pauseWhileMoving && movementLevel > 0.6
        if moving {
            if movingSince == nil { movingSince = now }
        } else {
            movingSince = nil
        }
        // Require a bit of sustained movement before suppressing.
        isMoving = moving && (now.timeIntervalSince(movingSince ?? now) > 1.5)
        if isMoving { resetSlouchTracking() }
    }

    private func updateCalibration(now: Date) {
        guard let start = calibrationStart, calibrationProgress != nil else { return }
        calibrationSamples.append((pitchDeg, rollDeg))
        let elapsed = now.timeIntervalSince(start)
        calibrationProgress = min(elapsed / calibrationDuration, 1)
        if elapsed >= calibrationDuration {
            let count = Double(calibrationSamples.count)
            let avgPitch = calibrationSamples.reduce(0) { $0 + $1.pitch } / count
            let avgRoll = calibrationSamples.reduce(0) { $0 + $1.roll } / count
            setBaseline(pitch: avgPitch, roll: avgRoll)
            let completion = calibrationCompletion
            cancelGuidedCalibration()
            completion?()
        }
    }

    private func updateSlouchState(now: Date) {
        guard isBadPosture, !isMoving, calibrationProgress == nil else {
            resetSlouchTracking()
            return
        }
        if badSince == nil { badSince = now }
        guard let since = badSince, now.timeIntervalSince(since) >= graceSeconds else { return }

        let wasSlouching = isSlouching
        isSlouching = true

        let cooldownPassed = lastAlertAt.map { now.timeIntervalSince($0) >= alertCooldownSeconds } ?? true
        if (!wasSlouching || cooldownPassed) && alertsEnabled {
            lastAlertAt = now
            alertsToday += 1
            defaults.set(alertsToday, forKey: Keys.alertsToday)
            defaults.set(Self.dayKey(for: now), forKey: Keys.alertsTodayDay)
            sendAlert()
        }
    }

    // MARK: - History bucketing

    private func bucketMinute(now: Date) {
        let currentMinute = Self.minuteFloor(now)
        if minuteStart == nil { minuteStart = currentMinute }
        guard let start = minuteStart, start != currentMinute else { return }
        flushMinuteBucket()
        minuteStart = currentMinute
    }

    private func flushMinuteBucket() {
        guard let start = minuteStart, minuteSampleCount > 0 else {
            minuteStart = nil
            return
        }
        let sample = MinuteSample(
            start: start,
            goodSeconds: minuteGood,
            badSeconds: minuteBad,
            avgDropDeg: minuteDropSum / Double(minuteSampleCount)
        )
        HistoryStore.shared.append(sample)
        minuteGood = 0
        minuteBad = 0
        minuteDropSum = 0
        minuteSampleCount = 0
        minuteStart = nil
    }

    private func rollOverDayIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        if today != statsDay {
            flushMinuteBucket()
            statsDay = today
            goodSeconds = 0
            badSeconds = 0
            alertsToday = 0
        }
    }

    private static func minuteFloor(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendAlert() {
        let content = UNMutableNotificationContent()
        content.title = "Straighten up"
        content.body = "You've been slouching for a while. Sit tall."
        if alertSoundEnabled {
            content.sound = .default
        }
        let request = UNNotificationRequest(
            identifier: "poise.slouch.\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
