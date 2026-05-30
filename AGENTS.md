# AGENTS.md — EyeGuard Codebase Guide

## Project Overview

**EyeGuard** is a macOS menu-bar-only app implementing the 20-20-20 eye health rule (every 20 minutes, look 20 feet away for 20 seconds). It shows a full-screen overlay during breaks, tracks break statistics, and provides customizable themes and settings. The app also supports a **Pomodoro Timer mode** and **global keyboard shortcuts** for hands-free control.

- No dock icon, no main window — menu-bar only
- Built with Swift, SwiftUI, SwiftData
- Pure Xcode project — no SPM packages, no CocoaPods, no external dependencies
- Requires Swift 5.9+ / macOS 14+ (`@Observable` macro)

## Architecture

### Entry Point

`EyeGuardApp.swift` — `@main` App struct using `MenuBarExtra` + `Settings` scenes. The `wireServices()` function constructs a `TimerService.Dependencies` struct (protocol-typed references) and passes it to `TimerService.configure(_:)`. `HotkeyService` is injected into the Settings scene via `.environment()`.

### Layer Structure

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

## Key Patterns

### Observation Framework
All service and model classes use `@Observable` (not `ObservableObject`/`@Published`). Services are injected via `.environment()` modifier (not `@EnvironmentObject`).

### Dependency Wiring
Services are created in `EyeGuardApp`. `wireServices()` builds a `TimerService.Dependencies` struct whose fields hold `any ProtocolName` existential references (e.g. `any OverlayPresenting`, `any SoundPlaying`, `any DNDChecking`, `any NotificationScheduling`) and calls `TimerService.configure(_:)`. `IdleDetector` is the exception: instantiated privately inside `TimerService`.

### Protocols
`Protocols/` provides a thin abstraction layer over the four main services, enabling future testability:
- `OverlayPresenting` — implemented by `OverlayManager`
- `SoundPlaying` — implemented by `SoundManager`
- `DNDChecking` — implemented by `DNDObserver`
- `NotificationScheduling` — implemented by `NotificationManager`

All four protocols are annotated `@MainActor`.

### Timer
`TimerService` uses `DispatchSourceTimer` (not `Timer.publish`). Timer state persists across restarts via `UserDefaults`. Two timing modes are supported:
- **20-20-20 mode** — fixed work interval, short break
- **Pomodoro mode** — configurable work/short-break/long-break cycle; `pomodoroCurrentSession` persists in `UserDefaults`

`AppSettings.effectiveWorkInterval` is a computed property that bridges both modes, returning the correct interval for the active mode.

Breaks can be **snoozed (deferred)** by a configurable duration. `BreakSession.wasDeferred` records whether a break was postponed.

The timer also handles **sleep/wake** notifications — it pauses on system sleep and resumes on wake.

**Data pruning**: `TimerService.pruneOldSessions()` deletes `BreakSession` records older than 90 days. This runs once per day; do not break this behavior.

### Overlay
`OverlayManager` conforms to `OverlayPresenting`. `showOverlay(tip:duration:timerService:settings:)` creates one `NSPanel` per connected screen at `.screenSaver` window level, hosted via `NSHostingView<SwiftUI view>`. Dismissal uses a fade-out animation. The manager listens for `NSApplication.didChangeScreenParametersNotification` to handle screen configuration changes.

### Hotkeys
`HotkeyService` registers global keyboard shortcuts via the Carbon `RegisterEventHotKey` API. Because Carbon callbacks are C function pointers, `HotkeyService` uses a `static var activeInstance` reference (not a `shared` singleton) to bridge the C callback back to the Swift instance. Default combos: ⇧⌘B (take break), ⇧⌘P (pause/resume), ⇧⌘S (skip break). Key combos are stored as `KeyCombo` (Codable) values in `AppSettings`.

### Persistence
- **UserDefaults** — all `AppSettings` properties persist in `didSet` using keys from `Constants.UserDefaultsKeys`; Pomodoro session counter and elapsed work time also stored here
- **SwiftData** — `BreakSession` (with `wasDeferred`, `tipShown`) and `DailySummary` (with `breaksDeferred`) track break history

### Singleton
`StatisticsWindowController.shared` is the only true singleton in the codebase — accessed directly rather than via environment. `HotkeyService.activeInstance` is a static weak reference used only for Carbon callback bridging; it is not a singleton.

## Coding Standards

- Swift naming: `camelCase` properties, `PascalCase` types
- `final class` for all model and service types
- Enum namespaces for constants: `Constants.Timer.*`, `Constants.UserDefaultsKeys.*`
- `// MARK: -` comments for section organization within files
- 4-space indentation
- No external dependencies — Apple frameworks only
- All protocol definitions carry the `@MainActor` attribute
- Services use `os.Logger` (subsystem/category pattern) — not `print` statements

## Testing

Test targets exist at `EyeGuardTests/` and `EyeGuardUITests/` but contain only Xcode boilerplate. There are no implemented tests. Build and run via Xcode — no command-line build scripts are configured.

```bash
xcodebuild -scheme EyeGuard -destination 'platform=macOS' build
```

## Important Notes for Agents

- **No `Package.swift`** — pure Xcode project. Do not add SPM dependencies without explicit instruction.
- **Multi-screen support** — overlay panels span all connected screens; always account for screen configuration changes when modifying `OverlayManager`.
- **Timer persistence** — `UserDefaults.elapsedWorkTime` and `pomodoroCurrentSession` survive app restarts; changes to timer logic must preserve this behavior.
- **DND integration** — when `AppSettings.respectDND` is enabled, `DNDObserver` pauses timer advancement; test DND-related changes against both states.
- **`@MainActor`** — all service classes are `@MainActor`-isolated; avoid dispatching UI or state mutations off the main actor.
- **`OverlayManager.showOverlay`** signature is `showOverlay(tip:duration:timerService:settings:)` — do not refactor to environment without updating all call sites.
- **Protocol conformance** — `TimerService` depends on protocol types (`any OverlayPresenting`, etc.), not concrete classes. Service conformances must be maintained when refactoring services.
- **HotkeyService Carbon constraint** — the `activeInstance` static is required by the C callback and must not be removed or made weak in a way that allows premature deallocation.
- **Data pruning** — `pruneOldSessions()` in `TimerService` deletes records older than 90 days; do not break this logic or its once-per-day scheduling guard.
- **Pomodoro state** — `pomodoroCurrentSession` in `UserDefaults` tracks progress through the work/break cycle; changes to Pomodoro logic must keep this key in sync.
