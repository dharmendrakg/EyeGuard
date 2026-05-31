import Testing
import Foundation
import SwiftData
@testable import EyeGuard

/// Helper that builds an in-memory SwiftData `ModelContext` for use in tests.
@MainActor
private func makeTestModelContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: BreakSession.self, DailySummary.self,
        configurations: config
    )
    return ModelContext(container)
}

/// Minimal idle detector stub that never reports idle — used in tests.
@MainActor
private final class StubIdleDetector: IdleDetecting {
    private(set) var isIdle: Bool = false
    var idleThreshold: TimeInterval = Constants.Timer.defaultIdleThreshold
    func start() {}
    func stop() { isIdle = false }
    func poll() {}
}

/// Helper that constructs a fully-wired `TimerService` backed by mock dependencies.
/// The returned tuple holds references to every mock so tests can inspect them.
/// An isolated `UserDefaults` suite is used to prevent inter-test pollution of
/// `UserDefaults.standard` (fixes the issue where `testTipRotation` leaked `tipIndex`).
@MainActor
private func makeTimerService(
    workInterval: TimeInterval = 60,
    breakDuration: TimeInterval = 5,
    modelContext: ModelContext
) -> (
    service: TimerService,
    settings: AppSettings,
    sound: MockSoundManager,
    overlay: MockOverlayManager,
    notifications: MockNotificationManager
) {
    // Use a per-call isolated suite so tests cannot pollute each other via UserDefaults.standard
    let suiteName = "com.eyeguard.tests.\(UUID().uuidString)"
    let testDefaults = UserDefaults(suiteName: suiteName)!

    let settings = AppSettings(defaults: testDefaults)
    settings.workInterval = workInterval
    settings.breakDuration = breakDuration
    settings.soundEnabled = true
    settings.notificationEnabled = false

    let sound         = MockSoundManager()
    let overlay       = MockOverlayManager()
    let notifications = MockNotificationManager()
    let idleDetector  = StubIdleDetector()

    let service = TimerService()
    service.configure(TimerService.Dependencies(
        settings: settings,
        overlayManager: overlay,
        soundManager: sound,
        notificationManager: notifications,
        modelContext: modelContext,
        idleDetector: idleDetector,
        defaults: testDefaults
    ))
    return (service, settings, sound, overlay, notifications)
}

// MARK: - Tests

@MainActor
struct TimerServiceTests {

    // MARK: 1. start() sets .working state

    @Test func testStartSetsWorkingState() throws {
        let ctx = try makeTestModelContext()
        let (service, _, _, _, _) = makeTimerService(modelContext: ctx)
        service.start()
        #expect(service.state == .working)
        service.stop()
    }

    // MARK: 2. timeUntilBreak decreases over time

    @Test func testWorkProgressDecreasesOverTime() async throws {
        let ctx = try makeTestModelContext()
        let (service, settings, _, _, _) = makeTimerService(workInterval: 60, modelContext: ctx)
        service.start()
        let initial = service.timeUntilBreak
        // Wait for a couple of timer ticks (timer fires every 1 s)
        try await Task.sleep(for: .seconds(2.5))
        #expect(service.timeUntilBreak < initial)
        service.stop()
    }

    // MARK: 3. Break triggers when timer reaches zero

    @Test func testBreakTriggersWhenTimerReachesZero() async throws {
        let ctx = try makeTestModelContext()
        // Use a 2-second work interval so the break fires quickly
        let (service, _, _, _, _) = makeTimerService(workInterval: 2, modelContext: ctx)
        service.start()
        try await Task.sleep(for: .seconds(3.5))
        #expect(service.state == .onBreak)
        service.stop()
    }

    // MARK: 4. skipBreak resets timer to .working

    @Test func testSkipBreakResetsTimer() throws {
        let ctx = try makeTestModelContext()
        let (service, settings, _, _, _) = makeTimerService(modelContext: ctx)
        service.start()
        service.takeBreakNow()
        #expect(service.state == .onBreak)
        service.skipBreak()
        #expect(service.state == .working)
        #expect(service.timeUntilBreak == settings.workInterval)
        service.stop()
    }

    // MARK: 5. togglePause stops and resumes timer

    @Test func testTogglePause() throws {
        let ctx = try makeTestModelContext()
        let (service, _, _, _, _) = makeTimerService(modelContext: ctx)
        service.start()
        #expect(service.state == .working)
        service.togglePause()
        #expect(service.state == .paused)
        service.togglePause()
        #expect(service.state == .working)
        service.stop()
    }

    // MARK: 7. Sound plays on break start

    @Test func testSoundPlaysOnBreakStart() throws {
        let ctx = try makeTestModelContext()
        let (service, _, sound, _, _) = makeTimerService(modelContext: ctx)
        service.start()
        service.takeBreakNow()
        #expect(sound.breakStartCount == 1)
        service.stop()
    }

    // MARK: 7b. Sound plays on break end (after skip — no break-end sound on skip)

    @Test func testSoundPlaysOnBreakEnd() async throws {
        let ctx = try makeTestModelContext()
        // Short break so it ends naturally
        let (service, _, sound, _, _) = makeTimerService(workInterval: 2, breakDuration: 2, modelContext: ctx)
        service.start()
        try await Task.sleep(for: .seconds(5))
        // Service went: working -> onBreak -> working; break-end sound fired once
        #expect(sound.breakEndCount >= 1)
        service.stop()
    }

    // MARK: 8. recordBreak saves a BreakSession to SwiftData

    @Test func testRecordBreakSavesToSwiftData() throws {
        let ctx = try makeTestModelContext()
        let (service, _, _, _, _) = makeTimerService(modelContext: ctx)
        service.start()
        service.takeBreakNow()
        service.skipBreak()  // skipped == true, triggers recordBreak

        let descriptor = FetchDescriptor<BreakSession>()
        let sessions = try ctx.fetch(descriptor)
        #expect(sessions.count == 1)
        #expect(sessions.first?.wasSkipped == true)
    }

    // MARK: 9. Tip rotation cycles through all available tips

    @Test func testTipRotation() throws {
        let ctx = try makeTestModelContext()
        let (service, _, _, _, _) = makeTimerService(modelContext: ctx)
        service.start()

        var observedTips: Set<String> = []
        // Cycle through more breaks than the tip count to confirm cycling
        let tipCount = Constants.eyeHealthTips.count
        for _ in 0..<(tipCount + 2) {
            service.takeBreakNow()
            let tip = service.currentTip
            #expect(!tip.isEmpty)
            observedTips.insert(tip)
            service.skipBreak()
        }
        // Should have seen all distinct tips (cycling wraps around)
        #expect(observedTips.count == tipCount)
        service.stop()
    }
}
