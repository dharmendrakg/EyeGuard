# EyeGuard

A macOS menu-bar app that helps protect your eyesight by reminding you to follow the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds.

## Features

- **20-20-20 rule timer** — configurable work interval and break duration
- **Pomodoro Timer mode** — alternate work/short-break/long-break cycle with configurable session counts
- **Full-screen overlay** — 8 animated themes: Minimal, Falling Leaves, Snowfall, Bubbles, Starfield, Rain, Fireflies, Sakura
- **Menu-bar-only design** — no dock icon; menu-bar icon shows a circular progress ring and next-break clock time
- **Snooze / defer breaks** — postpone an incoming break by a configurable snooze duration
- **Global keyboard shortcuts** — control EyeGuard hands-free from any app (see table below)
- **Configurable break sounds** — choose separate macOS system sounds for break start and break end
- **Break statistics** — daily charts and streak tracking
- **Idle detection** — automatically pauses the timer when you step away
- **Do Not Disturb awareness** — respects system DND state
- **Multi-monitor support** — overlay spans all connected screens
- **Launch at login** — optionally start EyeGuard on system startup
- **Notification alerts** — system notifications for break start/end
- **Eye health tips** — curated tips displayed during each break

## Requirements

- macOS 14 (Sonoma) or later
- Swift 5.9 or later (for building from source)

## Installation

### From Source (Xcode)

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/EyeGuard.git
   ```
2. Open `EyeGuard.xcodeproj` in Xcode.
3. Select the **EyeGuard** scheme and your Mac as the destination.
4. Press **Run** (or `Cmd+R`) to build and launch the app.

### Build and Install (Command Line)

Build an optimized release archive and install the `.app` bundle to `/Applications`:

```bash
# Build a release archive
xcodebuild archive \
  -scheme EyeGuard \
  -destination 'platform=macOS' \
  -archivePath build/EyeGuard.xcarchive

# Export the .app from the archive
xcodebuild -exportArchive \
  -archivePath build/EyeGuard.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/release

# Copy to Applications
cp -R build/release/EyeGuard.app /Applications/
```

> **Note:** If you do not have an `ExportOptions.plist`, you can copy the `.app` directly from the archive:
> ```bash
> cp -R build/EyeGuard.xcarchive/Products/Applications/EyeGuard.app /Applications/
> ```

The app appears in the menu bar immediately after launch. There is no dock icon.

## How It Works

The 20-20-20 rule is an evidence-based guideline for reducing digital eye strain:

- Every **20 minutes** of screen time, take a break.
- During the break, focus on something at least **20 feet away**.
- Hold that gaze for at least **20 seconds**.

EyeGuard runs a background timer and displays a full-screen overlay when it is time to take a break. The overlay counts down the break duration and dismisses automatically when the break ends. If you are idle (away from the keyboard/mouse), the work timer pauses until you return.

## Configuration

Open **Settings** from the menu-bar icon to adjust:

| Setting | Default | Description |
|---|---|---|
| Work interval | 20 min | How long between breaks (20-20-20 mode) |
| Break duration | 20 sec | How long each break lasts |
| Idle threshold | 5 min | Idle time before the timer pauses |
| Overlay theme | Minimal | Animation shown during breaks |
| Overlay opacity | — | Transparency of the break overlay |
| Skip button | enabled | Allow dismissing a break early |
| Snooze button | enabled | Show a snooze/defer option at break time |
| Snooze duration | 5 min | How long a snoozed break is postponed |
| Break start sound | — | macOS system sound played when a break begins |
| Break end sound | — | macOS system sound played when a break ends |
| Notifications | — | Show system notifications for breaks |
| Do Not Disturb | — | Pause timer while DND is active |
| Launch at login | — | Start EyeGuard automatically on login |
| **Pomodoro mode** | disabled | Switch from 20-20-20 to Pomodoro timing |
| Pomodoro work interval | 25 min | Work session length in Pomodoro mode |
| Pomodoro short break | 5 min | Short break length in Pomodoro mode |
| Pomodoro long break | 15 min | Long break length in Pomodoro mode |
| Sessions before long break | 4 | Number of work sessions before a long break |

## Keyboard Shortcuts

Default global shortcuts (configurable in **Settings → Shortcuts**):

| Shortcut | Action |
|---|---|
| ⇧⌘B | Take a break now |
| ⇧⌘P | Pause / Resume the timer |
| ⇧⌘S | Skip the current break |

## Building from the Command Line

```bash
# Debug build (no archive)
xcodebuild -scheme EyeGuard -destination 'platform=macOS' build

# Release build (optimized, no archive)
xcodebuild -scheme EyeGuard -destination 'platform=macOS' -configuration Release build
```

The built `.app` is placed in `DerivedData` by default. Use the archive workflow described in [Installation](#build-and-install-command-line) above for a distributable build.

## Project Structure

```
EyeGuard/
├── Models/
│   ├── AppSettings.swift       # All user preferences, UserDefaults-backed
│   ├── BreakSession.swift      # SwiftData @Model — individual break records (wasDeferred, tipShown)
│   ├── DailySummary.swift      # SwiftData @Model — daily break aggregates (breaksDeferred)
│   ├── OverlayTheme.swift      # 8 theme variants (String raw-value enum)
│   ├── BreakSound.swift        # Enum of 15 macOS system sounds for break alerts
│   ├── HotkeyAction.swift      # Enum: takeBreak, togglePause, skipBreak (with carbonID)
│   └── KeyCombo.swift          # Codable struct: key code + Carbon modifier flags + displayString
├── Protocols/
│   ├── OverlayPresenting.swift # Protocol for OverlayManager
│   ├── SoundPlaying.swift      # Protocol for SoundManager
│   ├── DNDChecking.swift       # Protocol for DNDObserver
│   └── NotificationScheduling.swift  # Protocol for NotificationManager
├── Services/
│   ├── TimerService.swift      # Core: state machine, Pomodoro, sleep/wake, pruneOldSessions()
│   ├── OverlayManager.swift    # Conforms to OverlayPresenting; one NSPanel per screen
│   ├── SoundManager.swift      # Conforms to SoundPlaying; plays configurable break sounds
│   ├── NotificationManager.swift  # Conforms to NotificationScheduling
│   ├── DNDObserver.swift       # Conforms to DNDChecking; observes Do Not Disturb state
│   ├── HotkeyService.swift     # Carbon API global shortcuts; activeInstance static pattern
│   ├── IdleDetector.swift      # Detects user idle (instantiated inside TimerService)
│   └── LoginItemManager.swift  # Launch-at-login management
├── Views/
│   ├── MenuBar/
│   │   ├── MenuBarView.swift       # Popover content
│   │   ├── MenuBarIconView.swift   # Custom label: progress ring + next-break clock time
│   │   └── TimerProgressView.swift # Circular progress ring component
│   ├── Overlay/
│   │   ├── OverlayPanel.swift          # NSPanel subclass at .screenSaver level
│   │   ├── OverlayContentView.swift    # Root SwiftUI view for the overlay
│   │   ├── BreakTimerView.swift        # Countdown and tip display
│   │   └── Particles/
│   │       ├── ParticleSystem.swift
│   │       └── ParticleBackgroundView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift          # Tab container (General, Sounds, Timer, Appearance, Shortcuts, About)
│   │   ├── GeneralTab.swift
│   │   ├── SoundsTab.swift
│   │   ├── TimerTab.swift
│   │   ├── AppearanceTab.swift
│   │   ├── ShortcutsTab.swift
│   │   ├── ShortcutRecorderView.swift  # Custom key-combo capture view
│   │   └── AboutTab.swift
│   └── Statistics/
│       ├── StatisticsView.swift
│       ├── StreakView.swift
│       ├── DailyChartView.swift
│       └── StatisticsWindowController.swift  # Singleton: .shared
└── Utilities/
    ├── Constants.swift         # Magic numbers and UserDefaults keys (Pomodoro defaults, snooze)
    └── Extensions.swift        # TimeInterval formatting, Date helpers, Color constants
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
