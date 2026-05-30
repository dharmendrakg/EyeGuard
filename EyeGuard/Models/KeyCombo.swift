import Foundation
import AppKit
import Carbon.HIToolbox

/// A value type representing a keyboard shortcut (key code + modifier flags).
struct KeyCombo: Codable, Equatable, Hashable {
    /// Carbon virtual key code (e.g., `kVK_ANSI_B`)
    let keyCode: UInt32
    /// Carbon modifier flags (e.g., `cmdKey | shiftKey`)
    let carbonModifiers: UInt32

    // MARK: - Carbon modifier constants

    static let carbonCmd: UInt32    = UInt32(cmdKey)      // 0x0100
    static let carbonShift: UInt32  = UInt32(shiftKey)    // 0x0200
    static let carbonOption: UInt32 = UInt32(optionKey)   // 0x0800
    static let carbonControl: UInt32 = UInt32(controlKey) // 0x1000

    // MARK: - Conversion helpers

    /// Convert NSEvent.ModifierFlags to Carbon modifier flags.
    static func carbonModifiers(from nsFlags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if nsFlags.contains(.command) { result |= carbonCmd }
        if nsFlags.contains(.shift)   { result |= carbonShift }
        if nsFlags.contains(.option)  { result |= carbonOption }
        if nsFlags.contains(.control) { result |= carbonControl }
        return result
    }

    /// Create a KeyCombo from an NSEvent (e.g., captured in keyDown).
    init?(nsEvent event: NSEvent) {
        guard event.type == .keyDown else { return nil }
        let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
        // Require at least Cmd or Ctrl to form a valid global shortcut
        guard mods.contains(.command) || mods.contains(.control) else { return nil }
        self.keyCode = UInt32(event.keyCode)
        self.carbonModifiers = KeyCombo.carbonModifiers(from: mods)
    }

    init(keyCode: UInt32, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }

    // MARK: - Display string

    var displayString: String {
        var result = ""
        if carbonModifiers & KeyCombo.carbonControl != 0 { result += "⌃" }
        if carbonModifiers & KeyCombo.carbonOption  != 0 { result += "⌥" }
        if carbonModifiers & KeyCombo.carbonShift   != 0 { result += "⇧" }
        if carbonModifiers & KeyCombo.carbonCmd     != 0 { result += "⌘" }
        result += keyLabel(for: keyCode)
        return result
    }

    // MARK: - Key code lookup table

    // swiftlint:disable cyclomatic_complexity
    private func keyLabel(for code: UInt32) -> String {
        switch Int(code) {
        // Letters
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        // Numbers
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        // Function keys
        case kVK_F1:  return "F1"
        case kVK_F2:  return "F2"
        case kVK_F3:  return "F3"
        case kVK_F4:  return "F4"
        case kVK_F5:  return "F5"
        case kVK_F6:  return "F6"
        case kVK_F7:  return "F7"
        case kVK_F8:  return "F8"
        case kVK_F9:  return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        // Special keys
        case kVK_Space:     return "Space"
        case kVK_Return:    return "↩"
        case kVK_Tab:       return "⇥"
        case kVK_Delete:    return "⌫"
        case kVK_Escape:    return "⎋"
        case kVK_UpArrow:   return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_Home:      return "↖"
        case kVK_End:       return "↘"
        case kVK_PageUp:    return "⇞"
        case kVK_PageDown:  return "⇟"
        case kVK_ANSI_Minus:        return "-"
        case kVK_ANSI_Equal:        return "="
        case kVK_ANSI_LeftBracket:  return "["
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_Backslash:    return "\\"
        case kVK_ANSI_Semicolon:    return ";"
        case kVK_ANSI_Quote:        return "'"
        case kVK_ANSI_Comma:        return ","
        case kVK_ANSI_Period:       return "."
        case kVK_ANSI_Slash:        return "/"
        case kVK_ANSI_Grave:        return "`"
        default: return "(\(code))"
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
