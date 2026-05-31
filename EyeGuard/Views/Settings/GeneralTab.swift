import SwiftUI

struct GeneralTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LoginItemManager.self) private var loginItemManager

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

