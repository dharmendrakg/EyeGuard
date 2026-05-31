import Foundation
import CoreGraphics

/// Polls CGEventSource to detect user idle time.
@Observable
@MainActor
final class IdleDetector: IdleDetecting {
    private(set) var isIdle: Bool = false
    private var timer: DispatchSourceTimer?
    var idleThreshold: TimeInterval = Constants.Timer.defaultIdleThreshold

    func start() {
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: Constants.Timer.idlePollInterval, leeway: .seconds(5))
        t.setEventHandler { [weak self] in
            self?.poll()
        }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isIdle = false
    }

    func poll() {
        // CGEventType(rawValue: ~0) is the well-known "all event types" sentinel for
        // CGEventSource.secondsSinceLastEventType. Guard against a hypothetical nil return
        // rather than force-unwrapping, so the worst case is a missed poll, not a crash.
        guard let allEvents = CGEventType(rawValue: ~0) else { return }
        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: allEvents
        )
        let nowIdle = idleSeconds >= idleThreshold
        if nowIdle != isIdle {
            isIdle = nowIdle
        }
    }
}
