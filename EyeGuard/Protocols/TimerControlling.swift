import Foundation

/// Abstracts the timer actions and state that the overlay and hotkey service need.
/// Conforming types must be `@MainActor`-isolated.
@MainActor
protocol TimerControlling: AnyObject, Sendable {
    var state: TimerState { get }
    var breakTimeRemaining: TimeInterval { get }
    func takeBreakNow()
    func togglePause()
    func skipBreak()
    func skipNextBreak()
    func deferBreak()
    func resetPomodoro()
}
