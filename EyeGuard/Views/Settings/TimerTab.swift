import SwiftUI

struct TimerTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(TimerService.self) private var timerService

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Mode") {
                Toggle("Pomodoro mode", isOn: $settings.pomodoroEnabled)
                    .help("Alternate focused work sessions with short breaks. Take a long break after completing all sessions.")
            }
            .onChange(of: settings.pomodoroEnabled) {
                timerService.handleModeChange()
            }

            if settings.pomodoroEnabled {
                Section("Pomodoro Intervals") {
                    Picker("Work session", selection: $settings.pomodoroWorkInterval) {
                        ForEach(Constants.TimerOptions.pomodoroWorkIntervals, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }

                    Picker("Short break", selection: $settings.pomodoroShortBreak) {
                        ForEach(Constants.TimerOptions.pomodoroShortBreaks, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }

                    Picker("Long break", selection: $settings.pomodoroLongBreak) {
                        ForEach(Constants.TimerOptions.pomodoroLongBreaks, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }

                    Picker("Sessions before long break", selection: $settings.pomodoroSessionsBeforeLongBreak) {
                        ForEach(Constants.TimerOptions.pomodoroSessionCounts, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }
                }
            } else {
                Section("Intervals") {
                    Picker("Work interval", selection: $settings.workInterval) {
                        ForEach(Constants.TimerOptions.workIntervals, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }

                    Picker("Break duration", selection: $settings.breakDuration) {
                        ForEach(Constants.TimerOptions.breakDurations, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }
                }
            }

            Section("Idle Detection") {
                Picker("Pause timer when idle for", selection: $settings.idleThreshold) {
                    ForEach(Constants.TimerOptions.idleThresholds, id: \.value) { opt in
                        Text(opt.label).tag(opt.value)
                    }
                }
            }

            Section("Snooze") {
                Picker("Snooze duration", selection: $settings.snoozeDuration) {
                    ForEach(Constants.TimerOptions.snoozeDurations, id: \.value) { opt in
                        Text(opt.label).tag(opt.value)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
