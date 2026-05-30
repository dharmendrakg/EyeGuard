import Foundation

/// Abstracts sound playback at break boundaries.
/// Conforming types must be `@MainActor`-isolated.
@MainActor
protocol SoundPlaying: AnyObject {
    func playBreakStart()
    func playBreakEnd()
    func preview(_ sound: BreakSound)
}
