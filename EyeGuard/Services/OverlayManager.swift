import AppKit
import SwiftUI

/// Manages the full-screen overlay panels shown during breaks.
@Observable
@MainActor
final class OverlayManager: OverlayPresenting {
    private var panels: [OverlayPanel] = []
    private var screenObserver: Any?

    func showOverlay(config: BreakOverlayConfig, timerService: any TimerControlling) {
        hideOverlay(animated: false)
        createPanels(config: config, timerService: timerService)
        registerScreenObserver(config: config, timerService: timerService)
    }

    func hideOverlay(animated: Bool = true) {
        // Remove observer immediately to prevent races during animation (e.g. screen
        // configuration change arriving while the fade-out is in flight).
        if let obs = screenObserver {
            NotificationCenter.default.removeObserver(obs)
            screenObserver = nil
        }

        if animated && !panels.isEmpty {
            let panelsToHide = panels
            panels.removeAll()
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panelsToHide.forEach { $0.animator().alphaValue = 0 }
            }, completionHandler: {
                panelsToHide.forEach {
                    $0.alphaValue = 1
                    // Eagerly release the NSHostingView hierarchy before ordering out.
                    // This prevents multi-MB SwiftUI view hierarchies from lingering in
                    // memory until the NSPanel's dealloc on multi-screen setups.
                    $0.contentView = nil
                    $0.orderOut(nil)
                }
            })
        } else {
            dismissPanels()
        }
    }

    private func dismissPanels() {
        // NOTE: screenObserver is always removed by the caller (hideOverlay) before
        // dismissPanels() is reached. No redundant cleanup needed here.
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
    }

    private func createPanels(config: BreakOverlayConfig, timerService: any TimerControlling) {
        for screen in NSScreen.screens {
            let panel = OverlayPanel(screen: screen)
            let contentView = OverlayContentView(
                config: config,
                timerService: timerService
            )
            panel.contentView = NSHostingView(rootView: contentView)
            panel.makeKeyAndOrderFront(nil)
            panels.append(panel)
        }
    }

    private func registerScreenObserver(config: BreakOverlayConfig, timerService: any TimerControlling) {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Re-capture timerService inside the @MainActor Task so it never crosses
            // an isolation boundary in a Sendable closure.
            Task { @MainActor [weak self, weak timerService] in
                guard let self, let timerService else { return }
                self.hideOverlay(animated: false)
                self.createPanels(config: config, timerService: timerService)
            }
        }
    }
}
