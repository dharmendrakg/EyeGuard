import Foundation
@testable import EyeGuard

/// Test double for `OverlayPresenting`. Tracks show/hide calls for assertion in tests.
@MainActor
final class MockOverlayManager: OverlayPresenting {
    var isShowing = false
    var showCount = 0
    var hideCount = 0

    func showOverlay(config: BreakOverlayConfig, timerService: any TimerControlling) {
        isShowing = true
        showCount += 1
    }

    func hideOverlay(animated: Bool) {
        isShowing = false
        hideCount += 1
    }
}
