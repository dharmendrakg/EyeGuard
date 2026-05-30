@testable import EyeGuard

/// Test double for `DNDChecking`. Exposes `isDoNotDisturbActive` as a settable flag.
@MainActor
final class MockDNDObserver: DNDChecking {
    var isDoNotDisturbActive = false
    var startCount = 0
    var stopCount  = 0

    func start() { startCount += 1 }
    func stop()  { stopCount  += 1 }
}
