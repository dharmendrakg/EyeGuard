import Foundation

/// Abstracts full-screen overlay presentation during breaks.
/// Conforming types must be `@MainActor`-isolated.
///
/// The `showOverlay` method accepts a `BreakOverlayConfig` value (a settings snapshot)
/// and `any TimerControlling` so the protocol has no dependency on the concrete
/// `TimerService` or `AppSettings` types. Mocks can conform without importing either.
///
/// Note: `hideOverlay(animated:)` cannot carry a default parameter value in the protocol
/// itself. Use `hideOverlay()` (extension-provided default of `animated: true`) or call
/// `hideOverlay(animated:)` with an explicit argument.
@MainActor
protocol OverlayPresenting: AnyObject {
    func showOverlay(config: BreakOverlayConfig, timerService: any TimerControlling)
    func hideOverlay(animated: Bool)
}

extension OverlayPresenting {
    /// Convenience overload that hides with the default animation.
    func hideOverlay() {
        hideOverlay(animated: true)
    }
}
