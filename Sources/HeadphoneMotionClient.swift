import CoreMotion
import Foundation

/// One fused reading from the headphone IMU, angles in degrees.
struct MotionSample {
    let pitchDeg: Double
    let rollDeg: Double
    let yawDeg: Double
    /// Rotation rate magnitude in degrees/second.
    let rotationDps: Double
    /// User acceleration magnitude in g (gravity removed).
    let accelerationG: Double
    let timestamp: TimeInterval

    init(motion: CMDeviceMotion) {
        pitchDeg = motion.attitude.pitch * 180 / .pi
        rollDeg = motion.attitude.roll * 180 / .pi
        yawDeg = motion.attitude.yaw * 180 / .pi
        let r = motion.rotationRate
        rotationDps = sqrt(r.x * r.x + r.y * r.y + r.z * r.z) * 180 / .pi
        let a = motion.userAcceleration
        accelerationG = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
        timestamp = motion.timestamp
    }
}

/// Wraps CMHeadphoneMotionManager and forwards connection + motion events.
/// All events are delivered on the main queue.
final class HeadphoneMotionClient: NSObject, CMHeadphoneMotionManagerDelegate {
    enum Event {
        case connected
        case disconnected
        case motion(MotionSample)
        case failed(String)
    }

    private let manager = CMHeadphoneMotionManager()
    var onEvent: ((Event) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    var isDenied: Bool {
        CMHeadphoneMotionManager.authorizationStatus() == .denied
    }

    func start() {
        guard manager.isDeviceMotionAvailable else {
            onEvent?(.failed("Headphone motion is not available on this Mac."))
            return
        }
        guard !manager.isDeviceMotionActive else { return }
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            if let error {
                let nsError = error as NSError
                // Transient errors while AirPods are out of the ear are
                // expected; only surface authorization problems.
                if nsError.code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                    self?.onEvent?(.failed("Motion access was denied. Enable it in System Settings → Privacy & Security → Motion & Fitness."))
                }
                return
            }
            guard let motion else { return }
            self?.onEvent?(.motion(MotionSample(motion: motion)))
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }

    // MARK: - CMHeadphoneMotionManagerDelegate

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        onEvent?(.connected)
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        onEvent?(.disconnected)
    }
}
