import Foundation

/// Abstracts macOS Do Not Disturb / Focus observation.
/// Conforming types must be `@MainActor`-isolated.
@MainActor
protocol DNDChecking: AnyObject {
    var isDoNotDisturbActive: Bool { get }
    func start()
    func stop()
}
