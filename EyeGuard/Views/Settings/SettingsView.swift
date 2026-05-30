import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gear") }

            SoundsTab()
                .tabItem { Label("Sounds", systemImage: "speaker.wave.2") }

            TimerTab()
                .tabItem { Label("Timer", systemImage: "timer") }

            AppearanceTab()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }

            ShortcutsTab()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }

            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 480, height: 480)
        .onAppear {
            NSApp.keyWindow?.level = .floating
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
