import AppKit
import Foundation

/// Plays system sounds at break boundaries, using the user's chosen sounds from AppSettings.
@Observable
@MainActor
final class SoundManager: SoundPlaying {

    // MARK: - Dependencies

    private var settings: AppSettings?

    // MARK: - Configuration

    func configure(_ settings: AppSettings) {
        self.settings = settings
    }

    // MARK: - SoundPlaying

    func playBreakStart() {
        guard let sound = settings?.breakStartSound, sound != .none else { return }
        NSSound(named: sound.rawValue)?.play()
    }

    func playBreakEnd() {
        guard let sound = settings?.breakEndSound, sound != .none else { return }
        NSSound(named: sound.rawValue)?.play()
    }

    /// Plays the given sound unconditionally — used for in-settings preview.
    /// Ignores `soundEnabled`; this is explicit user action.
    func preview(_ sound: BreakSound) {
        guard sound != .none else { return }
        NSSound(named: sound.rawValue)?.play()
    }
}
