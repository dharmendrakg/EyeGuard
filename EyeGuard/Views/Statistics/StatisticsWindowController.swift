import AppKit
import SwiftUI
import SwiftData

// MARK: - Environment key

struct StatisticsWindowControllerKey: EnvironmentKey {
    static var defaultValue: StatisticsWindowController? = nil
}

extension EnvironmentValues {
    var statisticsWindowController: StatisticsWindowController? {
        get { self[StatisticsWindowControllerKey.self] }
        set { self[StatisticsWindowControllerKey.self] = newValue }
    }
}

// MARK: - Controller

/// Manages the Statistics window lifecycle since `openWindow` doesn't work from MenuBarExtra.
/// Create one instance in `EyeGuardApp` and inject via `.environment(\.statisticsWindowController, ...)`.
@MainActor
final class StatisticsWindowController {

    private var window: NSWindow?
    private let modelContainer: ModelContainer

    /// - Parameter modelContainer: The app's SwiftData container. Required; passing it here
    ///   ensures the controller is always fully initialised before `showWindow()` is called.
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func showWindow() {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let statisticsView = StatisticsView()
            .frame(minWidth: 520, minHeight: 380)
            .modelContainer(modelContainer)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Statistics — EyeGuard"
        window.contentView = NSHostingView(rootView: statisticsView)
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
