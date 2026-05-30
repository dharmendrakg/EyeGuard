@testable import EyeGuard

/// Test double for `SoundPlaying`. Counts calls for assertion in tests.
@MainActor
final class MockSoundManager: SoundPlaying {
    var breakStartCount = 0
    var breakEndCount = 0

    func playBreakStart() { breakStartCount += 1 }
    func playBreakEnd()   { breakEndCount  += 1 }
    func preview(_ sound: BreakSound) {}
}
