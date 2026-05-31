import SwiftUI

struct MenuBarView: View {
    @Environment(TimerService.self) private var timerService
    @Environment(AppSettings.self) private var settings
    @Environment(\.statisticsWindowController) private var statsWindowController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status header
            statusHeader
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            // Actions
            Group {
                menuButton(
                    title: (timerService.state == .paused || timerService.state == .idle) ? "Resume Timer" : "Pause Timer",
                    icon: (timerService.state == .paused || timerService.state == .idle) ? "play.fill" : "pause.fill",
                    shortcut: "p"
                ) {
                    timerService.togglePause()
                }

                if timerService.state == .working {
                    menuButton(title: "Skip Next Break", icon: "forward.fill") {
                        timerService.skipNextBreak()
                    }
                }

                if timerService.state == .onBreak {
                    if settings.showSnoozeButton {
                        menuButton(title: "Snooze \(Int(settings.snoozeDuration / 60)) min", icon: "clock.arrow.circlepath") {
                            timerService.deferBreak()
                        }
                    }
                    menuButton(title: "Skip This Break", icon: "xmark.circle") {
                        timerService.skipBreak()
                    }
                } else {
                    menuButton(title: "Take a Break Now", icon: "eye.trianglebadge.exclamationmark") {
                        timerService.takeBreakNow()
                    }
                }

                if settings.pomodoroEnabled {
                    menuButton(title: "Reset Pomodoro", icon: "arrow.counterclockwise") {
                        timerService.resetPomodoro()
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)

            Divider()
                .padding(.vertical, 4)

            Group {
                menuButton(title: "Statistics…", icon: "chart.bar") {
                    statsWindowController?.showWindow()
                }

                SettingsLink {
                    Label("Settings…", systemImage: "gear")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(MenuItemButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)

            Divider()
                .padding(.vertical, 4)

            menuButton(title: "Quit EyeGuard", icon: "power", shortcut: "q") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 260)
    }

    // MARK: - Subviews

    private var statusHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: stateIconName)
                .font(.system(size: 20))
                .foregroundStyle(stateColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(stateTitle)
                    .font(.headline)
                Text(timerService.statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let sessionLabel = timerService.pomodoroSessionLabel {
                    HStack(spacing: 4) {
                        Text("Session \(sessionLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if timerService.isNextBreakLong {
                            Text("· Long break next")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            Spacer()

            if timerService.state == .working {
                TimerProgressView(
                    timeRemaining: timerService.timeUntilBreak,
                    totalDuration: settings.effectiveWorkInterval
                )
            }
        }
    }

    private var stateIconName: String {
        switch timerService.state {
        case .working: return "eye"
        case .onBreak: return "eye.trianglebadge.exclamationmark"
        case .paused, .idle: return "eye.slash"
        }
    }

    private var stateTitle: String {
        switch timerService.state {
        case .working: return "Working"
        case .onBreak: return "On Break"
        case .paused: return "Paused"
        case .idle: return "Idle"
        }
    }

    private var stateColor: Color {
        switch timerService.state {
        case .working: return .green
        case .onBreak: return .orange
        case .paused: return .secondary
        case .idle: return .secondary
        }
    }

    @ViewBuilder
    private func menuButton(
        title: String,
        icon: String,
        shortcut: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(MenuItemButtonStyle())

        if let key = shortcut?.first {
            button.keyboardShortcut(KeyEquivalent(key), modifiers: .command)
        } else {
            button
        }
    }
}

struct MenuItemButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor : Color.clear)
            )
            .foregroundStyle(isHovered ? .white : .primary)
            .onHover { isHovered = $0 }
    }
}
