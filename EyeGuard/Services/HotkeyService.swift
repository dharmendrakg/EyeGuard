import Foundation
import AppKit
import Carbon.HIToolbox
import os

/// Manages system-wide Carbon hotkey registration and dispatches actions to `TimerService`.
///
/// Must be configured via `configure(settings:timerService:)` before calling `start()`.
/// Uses a static callback (required by the C-level Carbon API) that routes through `activeInstance`.
@Observable
@MainActor
final class HotkeyService: HotkeyManaging {

    // MARK: - Observable state

    /// Whether global hotkeys are currently registered (mirrors `settings.hotkeyEnabled`).
    private(set) var isActive: Bool = false

    // MARK: - Private state

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.eyeguard",
        category: "HotkeyService"
    )

    private var settings: AppSettings?
    private weak var timerService: (any TimerControlling)?

    /// The Carbon event handler installed on the application event target.
    private var eventHandler: EventHandlerRef?

    /// Maps each action to its currently registered Carbon hotkey reference.
    private var registeredHotkeys: [HotkeyAction: EventHotKeyRef] = [:]

    /// Singleton reference used by the C callback to route events back to this instance.
    /// Kept weak because `HotkeyService` is owned for its full lifetime by `@State` in
    /// `EyeGuardApp`; a strong static reference here is unnecessary and would prevent
    /// deallocation if the ownership model ever changes.
    private static weak var activeInstance: HotkeyService?

    // MARK: - Four-character signature for EventHotKeyID

    private static let hotkeySignature: UInt32 = {
        // "EyGd" as a 4-char OSType
        let chars: [UInt8] = [UInt8(ascii: "E"), UInt8(ascii: "y"),
                              UInt8(ascii: "G"), UInt8(ascii: "d")]
        return UInt32(chars[0]) << 24 | UInt32(chars[1]) << 16 |
               UInt32(chars[2]) << 8  | UInt32(chars[3])
    }()

    // MARK: - Lifecycle

    func configure(settings: AppSettings, timerService: any TimerControlling) {
        self.settings = settings
        self.timerService = timerService
    }

    func start() {
        guard let settings else {
            Self.logger.error("HotkeyService.start() called before configure()")
            return
        }
        Self.activeInstance = self
        installCarbonHandler()
        if settings.hotkeyEnabled {
            registerAll()
        }
    }

    func stop() {
        unregisterAll()
        removeCarbonHandler()
        Self.activeInstance = nil
        isActive = false
    }

    // MARK: - Public API

    /// Called from Settings when `hotkeyEnabled` is toggled.
    func applyEnabledState() {
        guard let settings else { return }
        if settings.hotkeyEnabled {
            registerAll()
        } else {
            unregisterAll()
            isActive = false
        }
    }

    /// Re-registers all hotkeys (call after any shortcut change in Settings).
    func reregisterAll() {
        unregisterAll()
        guard let settings, settings.hotkeyEnabled else { return }
        registerAll()
    }

    // MARK: - Carbon handler installation

    private func installCarbonHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                // Route to the active instance.
                guard let instance = HotkeyService.activeInstance else { return OSStatus(eventNotHandledErr) }
                return instance.handleCarbonEvent(event)
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
        if status != noErr {
            Self.logger.error("Failed to install Carbon event handler: \(status)")
        }
    }

    private func removeCarbonHandler() {
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    // MARK: - Hotkey registration

    private func registerAll() {
        guard let settings else { return }
        for action in HotkeyAction.allCases {
            let combo: KeyCombo? = {
                switch action {
                case .takeBreak:   return settings.hotkeyTakeBreak
                case .togglePause: return settings.hotkeyTogglePause
                case .skipBreak:   return settings.hotkeySkipBreak
                }
            }()
            if let combo {
                register(action: action, combo: combo)
            }
        }
        isActive = !registeredHotkeys.isEmpty
    }

    private func register(action: HotkeyAction, combo: KeyCombo) {
        // Unregister existing entry for this action first
        if let existing = registeredHotkeys[action] {
            UnregisterEventHotKey(existing)
            registeredHotkeys.removeValue(forKey: action)
        }

        let hotKeyID = EventHotKeyID(signature: Self.hotkeySignature, id: action.carbonID)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status == noErr, let ref = hotKeyRef {
            registeredHotkeys[action] = ref
            Self.logger.debug("Registered hotkey \(action.rawValue): \(combo.displayString)")
        } else {
            Self.logger.warning("Failed to register hotkey \(action.rawValue): \(status)")
        }
    }

    private func unregisterAll() {
        for (action, ref) in registeredHotkeys {
            UnregisterEventHotKey(ref)
            Self.logger.debug("Unregistered hotkey \(action.rawValue)")
        }
        registeredHotkeys.removeAll()
    }

    // MARK: - Carbon event handling

    private func handleCarbonEvent(_ event: EventRef?) -> OSStatus {
        guard let event else { return OSStatus(eventNotHandledErr) }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard status == noErr, hotKeyID.signature == Self.hotkeySignature else {
            return OSStatus(eventNotHandledErr)
        }

        // Match the ID to a HotkeyAction and dispatch
        if let action = HotkeyAction.allCases.first(where: { $0.carbonID == hotKeyID.id }) {
            dispatchAction(action)
            return noErr
        }
        return OSStatus(eventNotHandledErr)
    }

    // MARK: - Action dispatch

    private func dispatchAction(_ action: HotkeyAction) {
        guard let timerService else { return }
        Self.logger.debug("Dispatching hotkey action: \(action.rawValue)")
        switch action {
        case .takeBreak:
            timerService.takeBreakNow()
        case .togglePause:
            timerService.togglePause()
        case .skipBreak:
            // Context-aware: skip current break or skip upcoming break
            if timerService.state == .onBreak {
                timerService.skipBreak()
            } else {
                timerService.skipNextBreak()
            }
        }
    }
}
