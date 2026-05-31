import SwiftUI
import SwiftData
import os

private let appLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.eyeguard",
    category: "EyeGuardApp"
)

@main
struct EyeGuardApp: App {
    @State private var timerService = TimerService()
    @State private var settings = AppSettings()
    @State private var overlayManager = OverlayManager()
    @State private var soundManager = SoundManager()
    @State private var notificationManager = NotificationManager()
    @State private var hotkeyService = HotkeyService()
    @State private var loginItemManager = LoginItemManager()
    @State private var servicesWired = false

    private let modelContainer: ModelContainer
    private let statsWindowController: StatisticsWindowController
    private let idleDetector = IdleDetector()

    init() {
        // Build a container using the versioned schema + migration plan.
        // On failure, fall back to an in-memory store so the app stays usable
        // (data is lost for this session, but no crash on upgrade).
        let schema = Schema(EyeGuardSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: EyeGuardMigrationPlan.self,
                configurations: config
            )
        } catch {
            appLogger.error("Failed to create persistent ModelContainer: \(error.localizedDescription). Falling back to in-memory store.")
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = (try? ModelContainer(for: schema, configurations: fallbackConfig))
                ?? { fatalError("Cannot create even an in-memory ModelContainer: \(error)") }()
        }
        modelContainer = container
        statsWindowController = StatisticsWindowController(modelContainer: container)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(timerService)
                .environment(settings)
                .environment(\.statisticsWindowController, statsWindowController)
                .modelContainer(modelContainer)
                .task {
                    guard !servicesWired else { return }
                    servicesWired = true
                    wireServices()
                }
        } label: {
            MenuBarIconView(state: timerService.state, progress: timerService.workProgress)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(settings)
                .environment(timerService)
                .environment(soundManager)
                .environment(hotkeyService)
                .environment(loginItemManager)
        }
    }

    @MainActor
    private func wireServices() {
        soundManager.configure(settings)

        timerService.configure(TimerService.Dependencies(
            settings: settings,
            overlayManager: overlayManager,
            soundManager: soundManager,
            notificationManager: notificationManager,
            modelContext: modelContainer.mainContext,
            idleDetector: idleDetector,
            defaults: .standard
        ))

        notificationManager.requestPermission()
        timerService.start()

        hotkeyService.configure(settings: settings, timerService: timerService)
        hotkeyService.start()
    }
}
