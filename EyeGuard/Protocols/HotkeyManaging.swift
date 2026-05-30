import Foundation

/// Abstracts global keyboard shortcut registration.
/// Enables mocking `HotkeyService` in future tests.
@MainActor
protocol HotkeyManaging: AnyObject {
    /// Whether global hotkeys are currently registered.
    var isActive: Bool { get }

    /// Wires the settings and timer service references. Must be called before `start()`.
    func configure(settings: AppSettings, timerService: any TimerControlling)

    /// Installs the Carbon event handler and registers shortcuts if enabled.
    func start()

    /// Unregisters all shortcuts and removes the Carbon event handler.
    func stop()

    /// Called when `hotkeyEnabled` is toggled in Settings.
    func applyEnabledState()

    /// Re-registers all hotkeys after a shortcut binding change.
    func reregisterAll()
}
