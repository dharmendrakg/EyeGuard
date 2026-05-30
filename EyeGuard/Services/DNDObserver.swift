import Foundation
import os

/// Observes macOS Focus / Do Not Disturb state.
/// Uses a polling approach since there is no public API for DND state changes.
///
/// NOTE: On macOS 13 (Ventura) and later, the `com.apple.ncprefs.plist` mechanism
/// used to detect DND state is non-functional. This observer skips timer creation
/// entirely on macOS 13+ and leaves `isDoNotDisturbActive = false`. The
/// "Respect Do Not Disturb" setting will have no effect on modern macOS until a
/// supported alternative is available.
@Observable
@MainActor
final class DNDObserver: DNDChecking {
    private(set) var isDoNotDisturbActive: Bool = false
    private var timer: DispatchSourceTimer?

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.eyeguard",
        category: "DNDObserver"
    )

    func start() {
        // On macOS 13+, the plist-based DND detection is non-functional.
        // Skip timer creation to avoid 100% wasted polling every 60 seconds.
        guard ProcessInfo.processInfo.operatingSystemVersion.majorVersion <= 12 else {
            Self.logger.info("DND detection unavailable on macOS 13+; 'Respect DND' setting will have no effect")
            isDoNotDisturbActive = false
            return
        }

        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: 60.0)
        t.setEventHandler { [weak self] in
            self?.checkDND()
        }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func checkDND() {
        // File I/O is dispatched to a background queue to avoid blocking the main thread.
        // The result is marshalled back to the main actor for the @Observable property update.
        DispatchQueue.global(qos: .utility).async {
            let result = DNDObserver.readDNDState()
            Task { @MainActor [weak self] in
                self?.isDoNotDisturbActive = result
            }
        }
    }

    /// Reads DND state from the system preferences file (macOS 12 and earlier only).
    ///
    /// - macOS 12 (Monterey) and earlier: reads `com.apple.ncprefs.plist` for `dnd_prefs.userPref.enabled`
    /// - macOS 13+: this function is never called (guarded in `start()`)
    private static nonisolated func readDNDState() -> Bool {
        let path = "\(NSHomeDirectory())/Library/Preferences/com.apple.ncprefs.plist"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let dndPrefs = plist["dnd_prefs"] as? [String: Any],
              let userPref = dndPrefs["userPref"] as? [String: Any] else {
            // Plist unreadable or structure changed — fail open (DND assumed off)
            return false
        }
        return userPref["enabled"] as? Bool ?? false
    }
}
