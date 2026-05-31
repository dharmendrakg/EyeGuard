import AppKit
import Foundation

/// Plays system sounds at break boundaries, using the user's chosen sounds from AppSettings.
@Observable
@MainActor
final class SoundManager: SoundPlaying {

    // MARK: - Dependencies

    private var settings: AppSettings?

    // MARK: - Cache

    /// Cached `NSSound` instances keyed by `BreakSound`.
    /// `NSSound(named:)` performs a file-system lookup and audio data load on each call;
    /// caching eliminates this overhead from the break-trigger critical path.
    private var soundCache: [BreakSound: NSSound] = [:]

    // MARK: - Configuration

    func configure(_ settings: AppSettings) {
        self.settings = settings
    }

    // MARK: - SoundPlaying

    func playBreakStart() {
        guard let sound = settings?.breakStartSound, sound != .none else { return }
        cachedSound(for: sound)?.play()
    }

    func playBreakEnd() {
        guard let sound = settings?.breakEndSound, sound != .none else { return }
        cachedSound(for: sound)?.play()
    }

    /// Plays the given sound unconditionally — used for in-settings preview.
    /// Ignores `soundEnabled`; this is explicit user action.
    func preview(_ sound: BreakSound) {
        guard sound != .none else { return }
        cachedSound(for: sound)?.play()
    }

    // MARK: - Private

    /// Returns a cached `NSSound` for `sound`, loading it lazily on first use.
    private func cachedSound(for sound: BreakSound) -> NSSound? {
        if let cached = soundCache[sound] {
            return cached
        }
        let loaded = NSSound(named: sound.rawValue)
        soundCache[sound] = loaded
        return loaded
    }
}
