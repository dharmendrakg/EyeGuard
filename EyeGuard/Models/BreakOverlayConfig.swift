import Foundation

/// Snapshot of all settings-derived data needed to display the break overlay.
/// Passed to `OverlayPresenting.showOverlay` so the protocol does not depend on
/// the concrete `AppSettings` type.
struct BreakOverlayConfig {
    let tip: String
    let duration: TimeInterval
    let theme: OverlayTheme
    let opacity: Double
    let showElements: Bool
    let showSnoozeButton: Bool
    let showSkipButton: Bool
    let snoozeDuration: TimeInterval

    /// Convenience init from AppSettings snapshot.
    init(tip: String, duration: TimeInterval, settings: AppSettings) {
        self.tip = tip
        self.duration = duration
        self.theme = settings.overlayTheme
        self.opacity = settings.overlayOpacity
        self.showElements = settings.showOverlayElements
        self.showSnoozeButton = settings.showSnoozeButton
        self.showSkipButton = settings.showSkipButton
        self.snoozeDuration = settings.snoozeDuration
    }
}
