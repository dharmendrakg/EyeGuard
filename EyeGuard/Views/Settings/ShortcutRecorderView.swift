import SwiftUI
import AppKit
import Carbon.HIToolbox

// MARK: - RecorderNSView

/// A minimal NSView that becomes first responder and captures raw keyDown events.
final class RecorderNSView: NSView {
    var onKeyCombo: ((KeyCombo) -> Void)?
    var onCancel: (() -> Void)?
    var onClear: (() -> Void)?
    var isRecording: Bool = false {
        didSet { needsDisplay = true }
    }

    override var acceptsFirstResponder: Bool { true }

    // MARK: - Key handling

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        let keyCode = Int(event.keyCode)

        // Escape → cancel recording
        if keyCode == kVK_Escape {
            onCancel?()
            return
        }

        // Delete/Backspace → clear shortcut
        if keyCode == kVK_Delete || keyCode == kVK_ForwardDelete {
            onClear?()
            return
        }

        // Build the combo — requires at least Cmd or Ctrl
        if let combo = KeyCombo(nsEvent: event) {
            onKeyCombo?(combo)
        }
        // If modifiers insufficient, ignore silently (no beep)
    }

    // Silence NSResponder's default beep for unhandled keyDown
    override func keyUp(with event: NSEvent) {}

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawn by SwiftUI overlay — nothing extra needed here
    }
}

// MARK: - ShortcutRecorderView

/// An `NSViewRepresentable` that captures keyboard shortcuts.
///
/// Usage:
/// ```swift
/// ShortcutRecorderView(isRecording: $isRecording) { combo in
///     // combo is nil when cleared
/// }
/// ```
struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onCommit: (KeyCombo?) -> Void

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.onKeyCombo = { combo in
            context.coordinator.commit(combo: combo)
        }
        view.onCancel = {
            context.coordinator.cancel()
        }
        view.onClear = {
            context.coordinator.commit(combo: nil)
        }
        return view
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        nsView.isRecording = isRecording
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator {
        var parent: ShortcutRecorderView

        init(parent: ShortcutRecorderView) {
            self.parent = parent
        }

        func commit(combo: KeyCombo?) {
            parent.isRecording = false
            parent.onCommit(combo)
        }

        func cancel() {
            parent.isRecording = false
        }
    }
}
