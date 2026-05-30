import SwiftUI

struct AppearanceTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(TimerService.self) private var timerService

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 20) {
            // MARK: Theme picker
            HStack {
                Text("Overlay Theme")
                    .font(.headline)
                Spacer()
                Button(action: { timerService.takeBreakNow() }) {
                    Label("Preview", systemImage: "eye.fill")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(OverlayTheme.allCases) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: settings.overlayTheme == theme
                    )
                    .onTapGesture {
                        settings.overlayTheme = theme
                    }
                }
            }

            Divider()

            // MARK: Opacity slider
            Text("Overlay Opacity")
                .font(.headline)

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
        }
        .padding(20)
    }
}

// MARK: - ThemeCard

private struct ThemeCard: View {
    let theme: OverlayTheme
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: theme.iconName)
                .font(.system(size: 28))
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .frame(height: 36)

            Text(theme.displayName)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(nsColor: .quaternaryLabelColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }
}
