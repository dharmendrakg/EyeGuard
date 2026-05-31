import Foundation
import AppKit
import SwiftData
import os

enum TimerState: Equatable {
    case working
    case onBreak
    case paused
    case idle
}

/// Drives the 20-20-20 break cycle: counts down work intervals, triggers breaks,
/// records break sessions, and coordinates all dependent services.
///
/// Must be wired via `configure(_:)` before calling `start()`.
@Observable
@MainActor
final class TimerService: TimerControlling {
    // MARK: - Public state
    private(set) var state: TimerState = .working
    private(set) var timeUntilBreak: TimeInterval = Constants.Timer.defaultWorkInterval
    private(set) var breakTimeRemaining: TimeInterval = Constants.Timer.defaultBreakDuration
    private(set) var currentTip: String = ""
    private(set) var currentPomodoroSession: Int = 1

    // MARK: - Private
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.eyeguard",
        category: "TimerService"
    )

    // MARK: - Dependencies

    /// Holds all external service dependencies required by TimerService.
    /// Set via `configure(_:)` before calling `start()`.
    struct Dependencies {
        let settings: AppSettings
        let overlayManager: any OverlayPresenting
        let soundManager: any SoundPlaying
        let notificationManager: any NotificationScheduling
        let modelContext: ModelContext
        let idleDetector: any IdleDetecting
        /// The UserDefaults suite for persisting timer state. Use `.standard` in production;
        /// inject a test suite in unit tests to prevent inter-test pollution.
        let defaults: UserDefaults
    }

    private var deps: Dependencies?

    /// Safe accessor — crashes with a clear message if called before configure().
    private var dependencies: Dependencies {
        guard let deps else {
            preconditionFailure("TimerService.configure(_:) must be called before use")
        }
        return deps
    }

    // MARK: - Timer state
    private var workTimer: DispatchSourceTimer?
    private var breakTimer: DispatchSourceTimer?
    private var sleepObserver: Any?
    private var wakeObserver: Any?
    private var elapsedWorkTime: TimeInterval = 0
    private var persistTick: Int = 0
    /// Tracks the work interval value we last observed, to detect mid-cycle setting changes.
    private var lastKnownWorkInterval: TimeInterval = 0

    // MARK: - Extracted sub-services (A2)
    private var breakRecorder: BreakRecorder?
    private var tipProvider: TipProvider?

    private var idleDetector: any IdleDetecting {
        dependencies.idleDetector
    }

    var workProgress: Double {
        guard state == .working, deps != nil else { return 0 }
        let total = effectiveWorkInterval
        guard total > 0 else { return 0 }
        // Quantize to 1% steps so the menu bar ring redraws ~100 times per cycle
        // instead of every second (~1200 times for a 20-minute interval).
        // Sub-pixel difference at 18 px ring diameter — visually indistinguishable.
        return (timeUntilBreak / total * 100).rounded() / 100
    }

    // MARK: - Pomodoro computed properties

    /// Whether the next break will be a long break (Pomodoro mode only)
    var isNextBreakLong: Bool {
        guard let deps, deps.settings.pomodoroEnabled else { return false }
        return currentPomodoroSession >= deps.settings.pomodoroSessionsBeforeLongBreak
    }

    /// Pomodoro session info for UI (e.g. "2 / 4"), nil when not in Pomodoro mode
    var pomodoroSessionLabel: String? {
        guard let deps, deps.settings.pomodoroEnabled else { return nil }
        return "\(currentPomodoroSession) / \(deps.settings.pomodoroSessionsBeforeLongBreak)"
    }

    private var effectiveWorkInterval: TimeInterval {
        guard let deps else { return Constants.Timer.defaultWorkInterval }
        return deps.settings.pomodoroEnabled
            ? deps.settings.pomodoroWorkInterval
            : deps.settings.workInterval
    }

    private var effectiveBreakDuration: TimeInterval {
        guard let deps else { return Constants.Timer.defaultBreakDuration }
        guard deps.settings.pomodoroEnabled else { return deps.settings.breakDuration }
        return isNextBreakLong
            ? deps.settings.pomodoroLongBreak
            : deps.settings.pomodoroShortBreak
    }

    var statusText: String {
        switch state {
        case .working:
            return "Next break in \(timeUntilBreak.minuteSecondDisplay)"
        case .onBreak:
            return "Break: \(breakTimeRemaining.minuteSecondDisplay)"
        case .paused:
            return "Paused"
        case .idle:
            return "Idle — timer paused"
        }
    }

    // MARK: - Lifecycle

    /// Wires all required dependencies. Must be called before `start()`.
    func configure(_ dependencies: Dependencies) {
        self.deps = dependencies
        self.breakRecorder = BreakRecorder(
            modelContext: dependencies.modelContext,
            settings: dependencies.settings,
            defaults: dependencies.defaults
        )
        self.tipProvider = TipProvider(defaults: dependencies.defaults)
    }

    func start() {
        precondition(deps != nil, "TimerService.configure(_:) must be called before start()")
        let defaults = dependencies.defaults

        // Restore Pomodoro session counter
        let savedSession = defaults.integer(forKey: Constants.UserDefaultsKeys.pomodoroCurrentSession)
        currentPomodoroSession = savedSession > 0 ? savedSession : 1

        // Restore elapsed time from previous session
        let saved = defaults.double(forKey: Constants.UserDefaultsKeys.elapsedWorkTime)
        let workInterval = effectiveWorkInterval
        elapsedWorkTime = min(saved, workInterval)
        timeUntilBreak = workInterval - elapsedWorkTime

        idleDetector.idleThreshold = dependencies.settings.idleThreshold
        idleDetector.start()

        registerSleepWakeObservers()
        startWorkTimer()
    }

    func stop() {
        // Persist current elapsed time before cancelling timers so progress is
        // not lost on a graceful quit (R3).
        if deps != nil {
            dependencies.defaults.set(elapsedWorkTime, forKey: Constants.UserDefaultsKeys.elapsedWorkTime)
        }
        cancelTimers()
        idleDetector.stop()
        removeSleepWakeObservers()
    }

    func togglePause() {
        switch state {
        case .paused, .idle:
            state = .working
            // Restart idle detection before resuming the work timer so any current
            // idle state is immediately evaluated on the first tick.
            idleDetector.start()
            startWorkTimer()
        case .working:
            cancelTimers()
            // Stop idle polling while paused — user-initiated pause doesn't need
            // idle detection, eliminating unnecessary 30-second CPU wakeups.
            idleDetector.stop()
            state = .paused
        default:
            break
        }
    }

    func skipBreak() {
        guard state == .onBreak else { return }
        breakTimer?.cancel()
        breakTimer = nil
        dependencies.notificationManager.cancelPendingNotifications()
        dependencies.overlayManager.hideOverlay()
        recordBreak(skipped: true)
        resetWorkTimer()
    }

    func deferBreak() {
        guard state == .onBreak else { return }
        breakTimer?.cancel()
        breakTimer = nil
        dependencies.notificationManager.cancelPendingNotifications()
        dependencies.overlayManager.hideOverlay()
        recordBreak(deferred: true)

        // Start a short work timer equal to snooze duration — break re-triggers when it expires
        elapsedWorkTime = 0
        dependencies.defaults.set(0.0, forKey: Constants.UserDefaultsKeys.elapsedWorkTime)
        timeUntilBreak = dependencies.settings.snoozeDuration
        startWorkTimer()
    }

    func takeBreakNow() {
        guard state == .working || state == .paused || state == .idle else { return }
        cancelTimers()
        triggerBreak()
    }

    func skipNextBreak() {
        guard state == .working else { return }
        // Reset timer as if break was just taken, but do NOT advance Pomodoro session
        // (the user is skipping the upcoming break, not completing a work session)
        resetWorkTimer(shouldAdvancePomodoro: false)
    }

    // MARK: - Work timer

    private func startWorkTimer() {
        state = .working
        lastKnownWorkInterval = effectiveWorkInterval
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now() + 1, repeating: 1.0, leeway: .milliseconds(100))
        t.setEventHandler { [weak self] in
            self?.workTick()
        }
        t.resume()
        workTimer = t
    }

    private func workTick() {
        syncIdleThreshold()
        guard !handleIdleTransition() else { return }

        handleIntervalChange()

        timeUntilBreak -= 1
        elapsedWorkTime += 1

        persistIfNeeded()
        scheduleBreakWarningIfNeeded()

        if timeUntilBreak <= 0 {
            workTimer?.cancel()
            workTimer = nil
            triggerBreak()
        }
    }

    // MARK: - workTick helpers (Q7)

    /// Syncs idle threshold from settings so changes take effect immediately.
    private func syncIdleThreshold() {
        let currentThreshold = dependencies.settings.idleThreshold
        if idleDetector.idleThreshold != currentThreshold {
            idleDetector.idleThreshold = currentThreshold
        }
    }

    /// Handles idle → working and working → idle transitions.
    /// Returns `true` when the tick should not advance (idle handling consumed it).
    private func handleIdleTransition() -> Bool {
        if idleDetector.isIdle {
            if state != .idle {
                // If on break, cancel the break timer and hide the overlay
                if state == .onBreak {
                    breakTimer?.cancel()
                    breakTimer = nil
                    dependencies.overlayManager.hideOverlay()
                }
                // Keep workTimer alive so this handler keeps polling for idle-end.
                // Only cancelTimers() would kill workTimer, which would make the
                // idle-resume branch below unreachable.
                state = .idle
            }
            return true
        } else if state == .idle {
            // Resumed from idle — cancel the currently-firing workTimer before
            // creating a new one, otherwise the old DispatchSourceTimer keeps firing.
            workTimer?.cancel()
            workTimer = nil
            startWorkTimer()
            return true
        }
        return false
    }

    /// Detects mid-cycle work interval changes (A6) and recalculates `timeUntilBreak`.
    /// Triggers an immediate break if the new interval means we've already exceeded it.
    private func handleIntervalChange() {
        let currentInterval = effectiveWorkInterval
        guard currentInterval != lastKnownWorkInterval else { return }
        lastKnownWorkInterval = currentInterval
        timeUntilBreak = max(0, currentInterval - elapsedWorkTime)
        Self.logger.info("Work interval changed to \(currentInterval)s; recalculated timeUntilBreak = \(self.timeUntilBreak)s")
        if timeUntilBreak == 0 {
            workTimer?.cancel()
            workTimer = nil
            triggerBreak()
        }
    }

    /// Persists elapsed work time every `Constants.Timer.persistInterval` seconds.
    private func persistIfNeeded() {
        persistTick += 1
        if persistTick >= Int(Constants.Timer.persistInterval) {
            persistTick = 0
            dependencies.defaults.set(elapsedWorkTime, forKey: Constants.UserDefaultsKeys.elapsedWorkTime)
        }
    }

    /// Schedules a pre-break notification when the countdown enters the warning window.
    private func scheduleBreakWarningIfNeeded() {
        let notifThreshold = Constants.Notifications.breakWarningSeconds
        if timeUntilBreak <= notifThreshold && timeUntilBreak > notifThreshold - 1 {
            if dependencies.settings.notificationEnabled {
                dependencies.notificationManager.scheduleBreakWarning(secondsUntilBreak: Int(timeUntilBreak))
            }
        }
    }

    // MARK: - Break

    private func triggerBreak() {
        dependencies.notificationManager.cancelPendingNotifications()
        let duration = effectiveBreakDuration
        breakTimeRemaining = duration
        state = .onBreak
        currentTip = nextTip()

        if dependencies.settings.soundEnabled {
            dependencies.soundManager.playBreakStart()
        }
        let config = BreakOverlayConfig(tip: currentTip, duration: duration, settings: dependencies.settings)
        dependencies.overlayManager.showOverlay(config: config, timerService: self)

        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now() + 1, repeating: 1.0, leeway: .milliseconds(100))
        t.setEventHandler { [weak self] in
            self?.breakTick()
        }
        t.resume()
        breakTimer = t
    }

    private func breakTick() {
        breakTimeRemaining -= 1
        if breakTimeRemaining <= 0 {
            breakTimer?.cancel()
            breakTimer = nil
            dependencies.overlayManager.hideOverlay()
            if dependencies.settings.soundEnabled {
                dependencies.soundManager.playBreakEnd()
            }
            recordBreak(skipped: false)
            resetWorkTimer()
        }
    }

    private func resetWorkTimer(shouldAdvancePomodoro: Bool = true) {
        elapsedWorkTime = 0
        dependencies.defaults.set(0.0, forKey: Constants.UserDefaultsKeys.elapsedWorkTime)
        if shouldAdvancePomodoro && dependencies.settings.pomodoroEnabled {
            advancePomodoroSession()
        }
        timeUntilBreak = effectiveWorkInterval
        startWorkTimer()
    }

    // MARK: - Sleep/Wake

    private func registerSleepWakeObservers() {
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.handleSleep() }
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.handleWake() }
        }
    }

    private func removeSleepWakeObservers() {
        if let obs = sleepObserver { NSWorkspace.shared.notificationCenter.removeObserver(obs) }
        if let obs = wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(obs) }
    }

    private func handleSleep() {
        cancelTimers()
        if state != .onBreak {
            state = .paused
        }
    }

    private func handleWake() {
        if state == .paused {
            // Force an immediate idle check before resuming so we don't count down
            // the ~30-second window before the next scheduled poll fires.
            idleDetector.poll()
            if idleDetector.isIdle {
                state = .idle
            } else {
                state = .working
                startWorkTimer()
            }
        }
    }

    // MARK: - Data persistence

    private func recordBreak(skipped: Bool = false, deferred: Bool = false) {
        guard let breakRecorder else {
            Self.logger.error("recordBreak called before configure()")
            return
        }
        breakRecorder.record(
            skipped: skipped,
            deferred: deferred,
            currentTip: currentTip,
            effectiveBreakDuration: effectiveBreakDuration,
            effectiveWorkInterval: effectiveWorkInterval
        )
    }

    // MARK: - Helpers

    private func advancePomodoroSession() {
        let total = dependencies.settings.pomodoroSessionsBeforeLongBreak
        currentPomodoroSession = currentPomodoroSession >= total ? 1 : currentPomodoroSession + 1
        dependencies.defaults.set(currentPomodoroSession, forKey: Constants.UserDefaultsKeys.pomodoroCurrentSession)
    }

    /// Resets the Pomodoro cycle to session 1 and restarts the work timer.
    func resetPomodoro() {
        cancelTimers()
        resetToSessionOne()
    }

    /// Called when Pomodoro mode is toggled; resets state to match the new mode.
    func handleModeChange() {
        cancelTimers()
        resetToSessionOne()
    }

    /// Shared reset logic: sets Pomodoro session to 1, clears elapsed time, and starts the work timer.
    private func resetToSessionOne() {
        currentPomodoroSession = 1
        dependencies.defaults.set(1, forKey: Constants.UserDefaultsKeys.pomodoroCurrentSession)
        elapsedWorkTime = 0
        dependencies.defaults.set(0.0, forKey: Constants.UserDefaultsKeys.elapsedWorkTime)
        timeUntilBreak = effectiveWorkInterval
        startWorkTimer()
    }

    private func cancelTimers() {
        workTimer?.cancel()
        workTimer = nil
        breakTimer?.cancel()
        breakTimer = nil
    }

    private func nextTip() -> String {
        guard let tipProvider else {
            Self.logger.error("nextTip called before configure()")
            return Constants.eyeHealthTips[0]
        }
        return tipProvider.nextTip()
    }
}
