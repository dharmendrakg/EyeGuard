@testable import EyeGuard

/// Test double for `NotificationScheduling`. Counts calls for assertion in tests.
@MainActor
final class MockNotificationManager: NotificationScheduling {
    var permissionRequested = false
    var warningsScheduled   = 0
    var cancelCount         = 0

    func requestPermission()                             { permissionRequested = true }
    func scheduleBreakWarning(secondsUntilBreak: Int)    { warningsScheduled += 1 }
    func cancelPendingNotifications()                    { cancelCount += 1 }
}
