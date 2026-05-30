import Foundation
import Carbon.HIToolbox

/// Represents a global hotkey action that EyeGuard can respond to.
enum HotkeyAction: String, CaseIterable, Codable, Identifiable {
    case takeBreak    = "takeBreak"
    case togglePause  = "togglePause"
    case skipBreak    = "skipBreak"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .takeBreak:   return "Take Break Now"
        case .togglePause: return "Pause / Resume"
        case .skipBreak:   return "Skip Break"
        }
    }

    var defaultKeyCombo: KeyCombo {
        switch self {
        case .takeBreak:
            return KeyCombo(
                keyCode: UInt32(kVK_ANSI_B),
                carbonModifiers: KeyCombo.carbonCmd | KeyCombo.carbonShift
            )
        case .togglePause:
            return KeyCombo(
                keyCode: UInt32(kVK_ANSI_P),
                carbonModifiers: KeyCombo.carbonCmd | KeyCombo.carbonShift
            )
        case .skipBreak:
            return KeyCombo(
                keyCode: UInt32(kVK_ANSI_S),
                carbonModifiers: KeyCombo.carbonCmd | KeyCombo.carbonShift
            )
        }
    }

    /// Integer ID used as `EventHotKeyID.id` when registering with Carbon.
    var carbonID: UInt32 {
        switch self {
        case .takeBreak:   return 1
        case .togglePause: return 2
        case .skipBreak:   return 3
        }
    }
}
