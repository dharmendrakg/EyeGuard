import Foundation
import UserNotifications
import os

/// Schedules and cancels `UNUserNotification` alerts for upcoming breaks.
@MainActor
final class NotificationManager: NotificationScheduling {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.eyeguard",
        category: "NotificationManager"
    )

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            if let error {
                Task { @MainActor in
                    self?.logger.error("Notification permission request failed: \(error.localizedDescription)")
                }
            } else if !granted {
                Task { @MainActor in
                    self?.logger.warning("Notification permission denied by user")
                }
            } else {
                Task { @MainActor in
                    self?.logger.info("Notification permission granted")
                }
            }
        }
    }

    func scheduleBreakWarning(secondsUntilBreak: Int) {
        // Skip scheduling if the user has denied notification permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "Break in \(secondsUntilBreak)s"
            content.body = "Get ready to look 20 feet away for 20 seconds."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "break-warning",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
