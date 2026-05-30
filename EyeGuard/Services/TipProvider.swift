import Foundation

/// Manages the cycling of eye-health tips shown during breaks.
///
/// Tips cycle sequentially through `Constants.eyeHealthTips`, wrapping around
/// when the end is reached. The current index is persisted in `UserDefaults` so
/// the sequence resumes correctly across app restarts.
@MainActor
final class TipProvider {
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// Returns the next tip in the rotation and advances the persisted index.
    func nextTip() -> String {
        let tips = Constants.eyeHealthTips
        let stored = defaults.integer(forKey: Constants.UserDefaultsKeys.tipIndex)
        let index = stored % tips.count
        defaults.set(index + 1, forKey: Constants.UserDefaultsKeys.tipIndex)
        return tips[index]
    }
}
