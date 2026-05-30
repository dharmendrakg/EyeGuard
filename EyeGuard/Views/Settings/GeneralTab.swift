import SwiftUI

struct GeneralTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LoginItemManager.self) private var loginItemManager

    /// True when running on macOS 13 (Ventura) or later, where plist-based DND
    /// detection is non-functional. Used to show an informational note.
    private var isDNDUnavailable: Bool {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13
    }

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, newValue in
                        loginItemManager.setEnabled(newValue)
                    }
            }

            Section("Behavior") {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Respect Focus / Do Not Disturb", isOn: $settings.respectDND)
                        .disabled(isDNDUnavailable)
                    if isDNDUnavailable {
                        Label(
                            "Not available on macOS 13 or later — Focus state detection requires a private API unavailable in sandboxed apps.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                Toggle("Show notifications", isOn: $settings.notificationEnabled)
                Toggle("Show button to skip break", isOn: $settings.showSkipButton)
                Toggle("Show button to snooze break", isOn: $settings.showSnoozeButton)
            }

            Section("Overlay") {
                Toggle("Show text and icons on overlay", isOn: $settings.showOverlayElements)
                    .help("When off, the overlay shows only the background tint and particles without any text, timer, or icons.")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
