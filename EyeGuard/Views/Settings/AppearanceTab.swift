import SwiftUI

struct AppearanceTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(TimerService.self) private var timerService

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Overlay Darkness")
                    .font(.headline)
                Spacer()
                Button(action: { timerService.takeBreakNow() }) {
                    Label("Preview", systemImage: "eye.fill")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text("Adjust the darkness level of the screen overlay during eye breaks. EyeGuard uses a lightweight, calm backdrop to minimize CPU and battery usage.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Lighter")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Darker")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.overlayOpacity, in: 0.05...0.9, step: 0.05)
                Text("Background darkness: \(Int(settings.overlayOpacity * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
    }
}
