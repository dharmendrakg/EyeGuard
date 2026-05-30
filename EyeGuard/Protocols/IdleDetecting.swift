import Foundation

/// Abstracts user-idle detection.
/// Conforming types must be `@MainActor`-isolated.
@MainActor
protocol IdleDetecting: AnyObject {
    var isIdle: Bool { get }
    var idleThreshold: TimeInterval { get set }
    func start()
    func stop()
    func poll()
}
