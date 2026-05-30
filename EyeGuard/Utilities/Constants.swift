import Foundation

enum Constants {
    enum Timer {
        static let defaultWorkInterval: TimeInterval = 20 * 60  // 20 minutes
        static let defaultBreakDuration: TimeInterval = 20       // 20 seconds
        static let defaultIdleThreshold: TimeInterval = 5 * 60  // 5 minutes
        static let idlePollInterval: TimeInterval = 30
        static let persistInterval: TimeInterval = 10

        // Pomodoro defaults
        static let defaultPomodoroWorkInterval: TimeInterval = 25 * 60  // 25 min
        static let defaultPomodoroShortBreak: TimeInterval = 5 * 60     // 5 min
        static let defaultPomodoroLongBreak: TimeInterval = 15 * 60     // 15 min
        static let defaultPomodoroSessions: Int = 4
        static let defaultSnoozeDuration: TimeInterval = 5 * 60  // 5 minutes
    }

    enum UserDefaultsKeys {
        static let workInterval = "workInterval"
        static let breakDuration = "breakDuration"
        static let idleThreshold = "idleThreshold"
        static let soundEnabled = "soundEnabled"
        static let notificationEnabled = "notificationEnabled"
        static let launchAtLogin = "launchAtLogin"
        static let respectDND = "respectDND"
        static let elapsedWorkTime = "elapsedWorkTime"
        static let tipIndex = "tipIndex"
        static let overlayTheme = "overlayTheme"
        static let overlayOpacity = "overlayOpacity"
        static let showSkipButton = "showSkipButton"
        static let showOverlayElements = "showOverlayElements"
        static let lastPruneDate = "lastPruneDate"
        static let breakStartSound = "breakStartSound"
        static let breakEndSound = "breakEndSound"

        // Pomodoro
        static let pomodoroEnabled = "pomodoroEnabled"
        static let pomodoroWorkInterval = "pomodoroWorkInterval"
        static let pomodoroShortBreak = "pomodoroShortBreak"
        static let pomodoroLongBreak = "pomodoroLongBreak"
        static let pomodoroSessionsBeforeLongBreak = "pomodoroSessionsBeforeLongBreak"
        static let pomodoroCurrentSession = "pomodoroCurrentSession"

        // Snooze
        static let snoozeDuration = "snoozeDuration"
        static let showSnoozeButton = "showSnoozeButton"

        // Hotkeys
        static let hotkeyEnabled      = "hotkeyEnabled"
        static let hotkeyTakeBreak    = "hotkeyTakeBreak"
        static let hotkeyTogglePause  = "hotkeyTogglePause"
        static let hotkeySkipBreak    = "hotkeySkipBreak"
    }

    enum Notifications {
        static let breakWarningSeconds: TimeInterval = 30
    }

    // MARK: - Timer Settings Options (used by TimerTab)

    enum TimerOptions {
        static let workIntervals: [(label: String, value: TimeInterval)] = [
            ("10 minutes", 10 * 60),
            ("15 minutes", 15 * 60),
            ("20 minutes", 20 * 60),
            ("25 minutes", 25 * 60),
            ("30 minutes", 30 * 60),
            ("45 minutes", 45 * 60),
            ("60 minutes", 60 * 60),
        ]

        static let breakDurations: [(label: String, value: TimeInterval)] = [
            ("10 seconds", 10),
            ("20 seconds", 20),
            ("30 seconds", 30),
            ("60 seconds", 60),
            ("2 minutes", 120),
        ]

        static let idleThresholds: [(label: String, value: TimeInterval)] = [
            ("2 minutes", 2 * 60),
            ("5 minutes", 5 * 60),
            ("10 minutes", 10 * 60),
            ("15 minutes", 15 * 60),
            ("Disabled", 0),
        ]

        static let pomodoroWorkIntervals: [(label: String, value: TimeInterval)] = [
            ("15 minutes", 15 * 60),
            ("20 minutes", 20 * 60),
            ("25 minutes", 25 * 60),
            ("30 minutes", 30 * 60),
            ("45 minutes", 45 * 60),
            ("50 minutes", 50 * 60),
        ]

        static let pomodoroShortBreaks: [(label: String, value: TimeInterval)] = [
            ("3 minutes", 3 * 60),
            ("5 minutes", 5 * 60),
            ("10 minutes", 10 * 60),
        ]

        static let pomodoroLongBreaks: [(label: String, value: TimeInterval)] = [
            ("10 minutes", 10 * 60),
            ("15 minutes", 15 * 60),
            ("20 minutes", 20 * 60),
            ("30 minutes", 30 * 60),
        ]

        static let pomodoroSessionCounts: [(label: String, value: Int)] = [
            ("2 sessions", 2),
            ("3 sessions", 3),
            ("4 sessions", 4),
            ("5 sessions", 5),
            ("6 sessions", 6),
        ]

        static let snoozeDurations: [(label: String, value: TimeInterval)] = [
            ("1 minute", 60),
            ("2 minutes", 2 * 60),
            ("3 minutes", 3 * 60),
            ("5 minutes", 5 * 60),
            ("10 minutes", 10 * 60),
        ]
    }

    static let eyeHealthTips: [String] = [
        "Look at something 20 feet away for 20 seconds to relax your eye muscles.",
        "Blink fully and frequently — staring at screens reduces blink rate by up to 66%.",
        "Adjust your monitor so the top is at or slightly below eye level.",
        "Keep your screen about an arm's length (20–26 inches) from your eyes.",
        "Reduce overhead lighting to minimize glare on your screen.",
        "Use the night mode or blue-light filter in the evening to improve sleep quality.",
        "Take this moment to roll your eyes slowly in a full circle to stretch the muscles.",
        "Stand up, stretch, and walk for a moment — your whole body will thank you.",
        "Make sure your workspace is well-lit to reduce contrast strain.",
        "Dry eyes? Use artificial tears as needed and ensure good humidity in your workspace.",
        "Try palming: cup your warm palms over closed eyes for 30 seconds.",
        "The 20-20-20 rule reduces digital eye strain significantly — you're doing great!",
        "Refocus on a near object, then a far one, alternating a few times.",
        "Adjust your display brightness to match the ambient light level around you.",
        "Your retinal cells are photoreceptors — let them rest during every break.",
    ]
}
