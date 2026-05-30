import SwiftUI

struct SoundsTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(SoundManager.self) private var soundManager

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Toggle("Play sounds", isOn: $settings.soundEnabled)
            }

            Section("Break Start Sound") {
                HStack {
                    Picker("Sound", selection: $settings.breakStartSound) {
                        ForEach(BreakSound.allCases) { sound in
                            Text(sound.displayName).tag(sound)
                        }
                    }
                    .labelsHidden()
                    .disabled(!settings.soundEnabled)

                    Button {
                        soundManager.preview(settings.breakStartSound)
                    } label: {
                        Image(systemName: "speaker.wave.2")
                    }
                    .disabled(!settings.soundEnabled || settings.breakStartSound == .none)
                    .help("Preview break start sound")
                }
            }

            Section("Break End Sound") {
                HStack {
                    Picker("Sound", selection: $settings.breakEndSound) {
                        ForEach(BreakSound.allCases) { sound in
                            Text(sound.displayName).tag(sound)
                        }
                    }
                    .labelsHidden()
                    .disabled(!settings.soundEnabled)

                    Button {
                        soundManager.preview(settings.breakEndSound)
                    } label: {
                        Image(systemName: "speaker.wave.2")
                    }
                    .disabled(!settings.soundEnabled || settings.breakEndSound == .none)
                    .help("Preview break end sound")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
