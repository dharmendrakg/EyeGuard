import Foundation

/// Abstracts UNUserNotification scheduling for break warnings.
/// Conforming types must be `@MainActor`-isolated.
@MainActor
protocol NotificationScheduling: AnyObject {
    func requestPermission()
    func scheduleBreakWarning(secondsUntilBreak: Int)
    func cancelPendingNotifications()
}
