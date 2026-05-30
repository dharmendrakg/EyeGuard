import Foundation

/// Abstracts launch-at-login management.
/// Conforming types must be `@MainActor`-isolated.
@MainActor
protocol LoginItemManaging: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enable: Bool)
}
