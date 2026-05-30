import Foundation
import ServiceManagement
import os

/// Manages the app's launch-at-login state via `SMAppService`.
@Observable
@MainActor
final class LoginItemManager: LoginItemManaging {

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.eyeguard",
        category: "LoginItemManager"
    )

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error("Failed to \(enable ? "enable" : "disable") login item: \(error.localizedDescription)")
        }
    }
}
