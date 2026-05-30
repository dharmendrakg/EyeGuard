import Foundation
import SwiftUI

@Observable
@MainActor
final class AppSettings {
    // MARK: - Injected UserDefaults

    /// The UserDefaults suite used for all persistence. Injected at init for testability.
    private let defaults: UserDefaults

    // MARK: - Work/break intervals

    // Work interval in seconds
    var workInterval: TimeInterval {
        didSet {
            // Clamp to a positive value to prevent division-by-zero in progress calculations.
            // Only reassign when clamping is actually needed — a no-op assignment would
            // re-trigger didSet and cause infinite recursion.
            if workInterval < 1 { workInterval = 1; return }
            persist(workInterval, forKey: Constants.UserDefaultsKeys.workInterval)
        }
    }

    // Break duration in seconds
    var breakDuration: TimeInterval {
        didSet {
            if breakDuration < 1 { breakDuration = 1; return }
            persist(breakDuration, forKey: Constants.UserDefaultsKeys.breakDuration)
        }
    }

    // Idle threshold in seconds — pauses timer when user is idle this long
    var idleThreshold: TimeInterval {
        didSet { persist(idleThreshold, forKey: Constants.UserDefaultsKeys.idleThreshold) }
    }

    var soundEnabled: Bool {
        didSet { persist(soundEnabled, forKey: Constants.UserDefaultsKeys.soundEnabled) }
    }

    var notificationEnabled: Bool {
        didSet { persist(notificationEnabled, forKey: Constants.UserDefaultsKeys.notificationEnabled) }
    }

    var launchAtLogin: Bool {
        didSet { persist(launchAtLogin, forKey: Constants.UserDefaultsKeys.launchAtLogin) }
    }

    var respectDND: Bool {
        didSet { persist(respectDND, forKey: Constants.UserDefaultsKeys.respectDND) }
    }

    var overlayTheme: OverlayTheme {
        didSet { persist(overlayTheme.rawValue, forKey: Constants.UserDefaultsKeys.overlayTheme) }
    }

    var breakStartSound: BreakSound {
        didSet { persist(breakStartSound.rawValue, forKey: Constants.UserDefaultsKeys.breakStartSound) }
    }

    var breakEndSound: BreakSound {
        didSet { persist(breakEndSound.rawValue, forKey: Constants.UserDefaultsKeys.breakEndSound) }
    }

    var overlayOpacity: Double {
        didSet {
            let clamped = overlayOpacity.clamped(to: 0.05...0.90)
            if clamped != overlayOpacity { overlayOpacity = clamped; return }
            persist(overlayOpacity, forKey: Constants.UserDefaultsKeys.overlayOpacity)
        }
    }

    var showSkipButton: Bool {
        didSet { persist(showSkipButton, forKey: Constants.UserDefaultsKeys.showSkipButton) }
    }

    var showSnoozeButton: Bool {
        didSet { persist(showSnoozeButton, forKey: Constants.UserDefaultsKeys.showSnoozeButton) }
    }

    var snoozeDuration: TimeInterval {
        didSet { persist(snoozeDuration, forKey: Constants.UserDefaultsKeys.snoozeDuration) }
    }

    var showOverlayElements: Bool {
        didSet { persist(showOverlayElements, forKey: Constants.UserDefaultsKeys.showOverlayElements) }
    }

    // MARK: - Pomodoro

    var pomodoroEnabled: Bool {
        didSet { persist(pomodoroEnabled, forKey: Constants.UserDefaultsKeys.pomodoroEnabled) }
    }

    var pomodoroWorkInterval: TimeInterval {
        didSet { persist(pomodoroWorkInterval, forKey: Constants.UserDefaultsKeys.pomodoroWorkInterval) }
    }

    var pomodoroShortBreak: TimeInterval {
        didSet { persist(pomodoroShortBreak, forKey: Constants.UserDefaultsKeys.pomodoroShortBreak) }
    }

    var pomodoroLongBreak: TimeInterval {
        didSet { persist(pomodoroLongBreak, forKey: Constants.UserDefaultsKeys.pomodoroLongBreak) }
    }

    var pomodoroSessionsBeforeLongBreak: Int {
        didSet { persist(pomodoroSessionsBeforeLongBreak, forKey: Constants.UserDefaultsKeys.pomodoroSessionsBeforeLongBreak) }
    }

    // MARK: - Hotkeys

    var hotkeyEnabled: Bool {
        didSet { persist(hotkeyEnabled, forKey: Constants.UserDefaultsKeys.hotkeyEnabled) }
    }

    var hotkeyTakeBreak: KeyCombo? {
        didSet { saveKeyCombo(hotkeyTakeBreak, forKey: Constants.UserDefaultsKeys.hotkeyTakeBreak) }
    }

    var hotkeyTogglePause: KeyCombo? {
        didSet { saveKeyCombo(hotkeyTogglePause, forKey: Constants.UserDefaultsKeys.hotkeyTogglePause) }
    }

    var hotkeySkipBreak: KeyCombo? {
        didSet { saveKeyCombo(hotkeySkipBreak, forKey: Constants.UserDefaultsKeys.hotkeySkipBreak) }
    }

    /// The effective work interval based on current mode
    var effectiveWorkInterval: TimeInterval {
        pomodoroEnabled ? pomodoroWorkInterval : workInterval
    }

    // MARK: - Hotkey KeyPath lookup

    /// Returns the writable KeyPath for a given `HotkeyAction`'s key combo.
    /// Eliminates the parallel switch statements in `ShortcutsTab`.
    static func keyPath(for action: HotkeyAction) -> ReferenceWritableKeyPath<AppSettings, KeyCombo?> {
        switch action {
        case .takeBreak:   return \.hotkeyTakeBreak
        case .togglePause: return \.hotkeyTogglePause
        case .skipBreak:   return \.hotkeySkipBreak
        }
    }

    // MARK: - Init

    /// - Parameter defaults: The UserDefaults suite to use. Defaults to `.standard`;
    ///   pass a test-specific suite to avoid inter-test pollution.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.workInterval = defaults.double(forKey: Constants.UserDefaultsKeys.workInterval).nonZero
            ?? Constants.Timer.defaultWorkInterval
        self.breakDuration = defaults.double(forKey: Constants.UserDefaultsKeys.breakDuration).nonZero
            ?? Constants.Timer.defaultBreakDuration
        self.idleThreshold = defaults.double(forKey: Constants.UserDefaultsKeys.idleThreshold).nonZero
            ?? Constants.Timer.defaultIdleThreshold
        self.soundEnabled = defaults.object(forKey: Constants.UserDefaultsKeys.soundEnabled) as? Bool ?? true
        self.notificationEnabled = defaults.object(forKey: Constants.UserDefaultsKeys.notificationEnabled) as? Bool ?? true
        self.launchAtLogin = defaults.object(forKey: Constants.UserDefaultsKeys.launchAtLogin) as? Bool ?? false
        self.respectDND = defaults.object(forKey: Constants.UserDefaultsKeys.respectDND) as? Bool ?? true
        self.overlayTheme = OverlayTheme(rawValue:
            defaults.string(forKey: Constants.UserDefaultsKeys.overlayTheme) ?? "") ?? .minimal
        self.breakStartSound = BreakSound(rawValue:
            defaults.string(forKey: Constants.UserDefaultsKeys.breakStartSound) ?? "") ?? .glass
        self.breakEndSound = BreakSound(rawValue:
            defaults.string(forKey: Constants.UserDefaultsKeys.breakEndSound) ?? "") ?? .ping
        self.overlayOpacity = defaults.object(forKey: Constants.UserDefaultsKeys.overlayOpacity) as? Double ?? 0.45
        self.showSkipButton = defaults.object(forKey: Constants.UserDefaultsKeys.showSkipButton) as? Bool ?? true
        self.showSnoozeButton = defaults.object(forKey: Constants.UserDefaultsKeys.showSnoozeButton) as? Bool ?? true
        self.snoozeDuration = defaults.double(forKey: Constants.UserDefaultsKeys.snoozeDuration).nonZero
            ?? Constants.Timer.defaultSnoozeDuration
        self.showOverlayElements = defaults.object(forKey: Constants.UserDefaultsKeys.showOverlayElements) as? Bool ?? true
        self.pomodoroEnabled = defaults.object(forKey: Constants.UserDefaultsKeys.pomodoroEnabled) as? Bool ?? false
        self.pomodoroWorkInterval = defaults.double(forKey: Constants.UserDefaultsKeys.pomodoroWorkInterval).nonZero
            ?? Constants.Timer.defaultPomodoroWorkInterval
        self.pomodoroShortBreak = defaults.double(forKey: Constants.UserDefaultsKeys.pomodoroShortBreak).nonZero
            ?? Constants.Timer.defaultPomodoroShortBreak
        self.pomodoroLongBreak = defaults.double(forKey: Constants.UserDefaultsKeys.pomodoroLongBreak).nonZero
            ?? Constants.Timer.defaultPomodoroLongBreak
        self.pomodoroSessionsBeforeLongBreak = {
            let v = defaults.integer(forKey: Constants.UserDefaultsKeys.pomodoroSessionsBeforeLongBreak)
            return v > 0 ? v : Constants.Timer.defaultPomodoroSessions
        }()
        self.hotkeyEnabled = defaults.object(forKey: Constants.UserDefaultsKeys.hotkeyEnabled) as? Bool ?? true
        self.hotkeyTakeBreak   = AppSettings.loadKeyCombo(forKey: Constants.UserDefaultsKeys.hotkeyTakeBreak, defaults: defaults)
            ?? HotkeyAction.takeBreak.defaultKeyCombo
        self.hotkeyTogglePause = AppSettings.loadKeyCombo(forKey: Constants.UserDefaultsKeys.hotkeyTogglePause, defaults: defaults)
            ?? HotkeyAction.togglePause.defaultKeyCombo
        self.hotkeySkipBreak   = AppSettings.loadKeyCombo(forKey: Constants.UserDefaultsKeys.hotkeySkipBreak, defaults: defaults)
            ?? HotkeyAction.skipBreak.defaultKeyCombo
    }

    // MARK: - Persistence helpers

    /// Persists any value that `UserDefaults.set(_:forKey:)` accepts.
    private func persist<T>(_ value: T, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    private static func loadKeyCombo(forKey key: String, defaults: UserDefaults = .standard) -> KeyCombo? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(KeyCombo.self, from: data)
    }

    private func saveKeyCombo(_ combo: KeyCombo?, forKey key: String) {
        if let combo, let data = try? JSONEncoder().encode(combo) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}

private extension Double {
    var nonZero: Double? {
        self == 0 ? nil : self
    }

    func clamped(to range: ClosedRange<Double>) -> Double {
        min(range.upperBound, max(range.lowerBound, self))
    }
}
