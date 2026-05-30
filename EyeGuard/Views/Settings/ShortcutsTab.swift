import SwiftUI

struct ShortcutsTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(HotkeyService.self) private var hotkeyService

    /// Tracks which action is currently being recorded (nil = none).
    @State private var recordingAction: HotkeyAction? = nil
    /// Tracks which action has a conflict warning.
    @State private var conflictAction: HotkeyAction? = nil

    // MARK: - Conflict detection

    private static let systemReserved: Set<String> = [
        // Cmd+Q, Cmd+W, Cmd+H, Cmd+Tab, Cmd+Space, etc.
        "⌘Q", "⌘W", "⌘H", "⌘M", "⌘Tab", "⌘Space", "⌘⇧3", "⌘⇧4", "⌘⇧5"
    ]

    private func combo(for action: HotkeyAction) -> KeyCombo? {
        settings[keyPath: AppSettings.keyPath(for: action)]
    }

    private func setCombo(_ combo: KeyCombo?, for action: HotkeyAction) {
        settings[keyPath: AppSettings.keyPath(for: action)] = combo
        hotkeyService.reregisterAll()
    }

    private func hasConflict(_ action: HotkeyAction) -> Bool {
        guard let currentCombo = combo(for: action) else { return false }
        let display = currentCombo.displayString
        // System reserved
        if Self.systemReserved.contains(display) { return true }
        // Conflict with another EyeGuard action
        for other in HotkeyAction.allCases where other != action {
            if combo(for: other)?.displayString == display { return true }
        }
        return false
    }

    // MARK: - Body

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Toggle("Enable global keyboard shortcuts", isOn: $settings.hotkeyEnabled)
                    .onChange(of: settings.hotkeyEnabled) { _, _ in
                        hotkeyService.applyEnabledState()
                    }
            }

            Section("Actions") {
                ForEach(HotkeyAction.allCases) { action in
                    shortcutRow(for: action)
                }
            }
            .disabled(!settings.hotkeyEnabled)

            Section {
                Button("Reset to Defaults") {
                    for action in HotkeyAction.allCases {
                        setCombo(action.defaultKeyCombo, for: action)
                    }
                    recordingAction = nil
                }
                .disabled(!settings.hotkeyEnabled)
            }

            Section {
                Label(
                    "Shortcuts work system-wide, even when EyeGuard's menu is closed.",
                    systemImage: "info.circle"
                )
                .foregroundStyle(.secondary)
                .font(.footnote)
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 4)
    }

    // MARK: - Shortcut row

    @ViewBuilder
    private func shortcutRow(for action: HotkeyAction) -> some View {
        let isRecordingThis = recordingAction == action
        let currentCombo = combo(for: action)
        let conflict = hasConflict(action)

        HStack {
            Text(action.displayName)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Conflict warning
            if conflict {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .help("This shortcut conflicts with another shortcut or a system shortcut.")
            }

            // Current combo badge or recording indicator
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isRecordingThis
                          ? Color.accentColor.opacity(0.15)
                          : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecordingThis ? Color.accentColor : Color.gray.opacity(0.3),
                                    lineWidth: isRecordingThis ? 1.5 : 1)
                    )

                if isRecordingThis {
                    // Invisible recorder captures key events
                    ShortcutRecorderView(isRecording: Binding(
                        get: { recordingAction == action },
                        set: { if !$0 { recordingAction = nil } }
                    )) { newCombo in
                        setCombo(newCombo, for: action)
                        recordingAction = nil
                    }
                    .frame(width: 100, height: 24)
                    // Visible label on top
                    Text("Press shortcut…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .allowsHitTesting(false)
                } else if let combo = currentCombo {
                    Text(combo.displayString)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                } else {
                    Text("None")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                }
            }
            .frame(width: 110, height: 26)
            .onTapGesture {
                guard settings.hotkeyEnabled else { return }
                recordingAction = (recordingAction == action) ? nil : action
            }

            // Clear button
            Button {
                setCombo(nil, for: action)
                if recordingAction == action { recordingAction = nil }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(currentCombo != nil ? 1 : 0)
            .disabled(currentCombo == nil)
        }
        .padding(.vertical, 2)
    }
}
