import Testing
import Foundation
@testable import EyeGuard

/// Tests for `AppSettings` persistence behaviour.
///
/// Each test creates a fresh `UserDefaults` suite and injects it into `AppSettings`,
/// preventing writes from polluting the app's real defaults or bleeding between test runs.
@MainActor
struct AppSettingsTests {

    // MARK: 1. Default values

    @Test func testDefaultValues() {
        let suiteName = "AppSettingsTests.defaults.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: suite)
        // A freshly-initialised AppSettings (no stored keys) must return built-in defaults.
        #expect(settings.workInterval == Constants.Timer.defaultWorkInterval)
        #expect(settings.breakDuration == Constants.Timer.defaultBreakDuration)
        #expect(settings.idleThreshold == Constants.Timer.defaultIdleThreshold)
        #expect(settings.overlayOpacity == 0.45)
        suite.removePersistentDomain(forName: suiteName)
    }

    // MARK: 2. Mutating a property persists to UserDefaults

    @Test func testPersistsToUserDefaults() {
        let suiteName = "AppSettingsTests.persists.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: suite)
        let newInterval: TimeInterval = 15 * 60
        settings.workInterval = newInterval
        let stored = suite.double(forKey: Constants.UserDefaultsKeys.workInterval)
        #expect(stored == newInterval)
        suite.removePersistentDomain(forName: suiteName)
    }

    // MARK: 3. Pre-set UserDefaults value is picked up by init

    @Test func testReadsFromUserDefaults() {
        let suiteName = "AppSettingsTests.reads.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        let customDuration: TimeInterval = 45
        suite.set(customDuration, forKey: Constants.UserDefaultsKeys.breakDuration)
        let settings = AppSettings(defaults: suite)
        #expect(settings.breakDuration == customDuration)
        suite.removePersistentDomain(forName: suiteName)
    }

    // MARK: 4. Sound toggle round-trips through UserDefaults

    @Test func testSoundEnabledPersists() {
        let suiteName = "AppSettingsTests.sound.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: suite)
        settings.soundEnabled = false
        let stored = suite.bool(forKey: Constants.UserDefaultsKeys.soundEnabled)
        #expect(stored == false)
        suite.removePersistentDomain(forName: suiteName)
    }

    // MARK: 5. Overlay opacity persists and clamps

    @Test func testOverlayOpacityPersistsAndClamps() {
        let suiteName = "AppSettingsTests.opacity.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: suite)
        settings.overlayOpacity = 0.75
        let stored = suite.double(forKey: Constants.UserDefaultsKeys.overlayOpacity)
        #expect(stored == 0.75)

        // Verify clamping below 0.05
        settings.overlayOpacity = 0.01
        #expect(settings.overlayOpacity == 0.05)

        // Verify clamping above 0.90
        settings.overlayOpacity = 1.0
        #expect(settings.overlayOpacity == 0.90)

        suite.removePersistentDomain(forName: suiteName)
    }
}
