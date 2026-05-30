import Foundation
import SwiftData
import os

/// Records break sessions to SwiftData and maintains `DailySummary` aggregates.
///
/// Extracted from `TimerService` to separate data-persistence concerns from the
/// timer state machine. `TimerService` delegates all SwiftData writes here.
@MainActor
final class BreakRecorder {
    private let modelContext: ModelContext
    private let settings: AppSettings
    private let defaults: UserDefaults

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.eyeguard",
        category: "BreakRecorder"
    )

    init(modelContext: ModelContext, settings: AppSettings, defaults: UserDefaults) {
        self.modelContext = modelContext
        self.settings = settings
        self.defaults = defaults
    }

    // MARK: - Public API

    /// Records a break event and updates the corresponding `DailySummary`.
    ///
    /// - Parameters:
    ///   - skipped: Whether the user skipped the break before it completed.
    ///   - deferred: Whether the user snoozed the break.
    ///   - currentTip: The health tip that was shown during this break.
    ///   - effectiveBreakDuration: The break length in seconds (may be short/long Pomodoro break).
    ///   - effectiveWorkInterval: The work-interval length in seconds used for daily summary accounting.
    func record(
        skipped: Bool = false,
        deferred: Bool = false,
        currentTip: String,
        effectiveBreakDuration: TimeInterval,
        effectiveWorkInterval: TimeInterval
    ) {
        let session = BreakSession(
            scheduledAt: Date(),
            durationSeconds: Int(effectiveBreakDuration)
        )
        session.wasSkipped = skipped
        session.wasDeferred = deferred
        if !skipped && !deferred {
            session.startedAt = Date().addingTimeInterval(-effectiveBreakDuration)
            session.endedAt = Date()
        }
        session.tipShown = currentTip
        modelContext.insert(session)

        // Update daily summary
        let today = Date().startOfDay
        let descriptor = FetchDescriptor<DailySummary>(
            predicate: #Predicate { $0.date == today }
        )
        let summaries: [DailySummary]
        switch Result(catching: { try modelContext.fetch(descriptor) }) {
        case .success(let fetched):
            summaries = fetched
        case .failure(let error):
            Self.logger.error("Failed to fetch DailySummary records: \(error.localizedDescription)")
            summaries = []
        }

        let summary = deduplicateOrCreateSummary(summaries, for: today)

        if deferred {
            summary.totalWorkSeconds += Int(settings.snoozeDuration)
            summary.breaksDeferred += 1
        } else if skipped {
            summary.totalWorkSeconds += Int(effectiveWorkInterval)
            summary.breaksSkipped += 1
        } else {
            summary.totalWorkSeconds += Int(effectiveWorkInterval)
            summary.breaksTaken += 1
        }

        do {
            try modelContext.save()
        } catch {
            Self.logger.error("Failed to save break session: \(error.localizedDescription)")
        }

        pruneOldSessions()
    }

    // MARK: - Private helpers

    /// Deduplicates `DailySummary` records for a given date, or creates a new one.
    private func deduplicateOrCreateSummary(
        _ summaries: [DailySummary],
        for date: Date
    ) -> DailySummary {
        if summaries.count > 1 {
            // Keep the first, merge counts into it, delete the rest
            let primary = summaries[0]
            for duplicate in summaries.dropFirst() {
                primary.breaksTaken      += duplicate.breaksTaken
                primary.breaksSkipped    += duplicate.breaksSkipped
                primary.breaksDeferred   += duplicate.breaksDeferred
                primary.totalWorkSeconds += duplicate.totalWorkSeconds
                modelContext.delete(duplicate)
            }
            return primary
        } else if let existing = summaries.first {
            return existing
        } else {
            let summary = DailySummary(date: date)
            modelContext.insert(summary)
            return summary
        }
    }

    /// Deletes `BreakSession` records older than 90 days, at most once per calendar day.
    private func pruneOldSessions() {
        let lastPruneKey = Constants.UserDefaultsKeys.lastPruneDate
        let today = Date().startOfDay
        if let lastPrune = defaults.object(forKey: lastPruneKey) as? Date,
           lastPrune >= today {
            return  // Already pruned today
        }

        guard let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) else { return }
        let descriptor = FetchDescriptor<BreakSession>(
            predicate: #Predicate { $0.scheduledAt < cutoff }
        )
        if let old = try? modelContext.fetch(descriptor), !old.isEmpty {
            old.forEach { modelContext.delete($0) }
            do {
                try modelContext.save()
            } catch {
                Self.logger.error("Failed to save after pruning old sessions: \(error.localizedDescription)")
            }
            Self.logger.info("Pruned \(old.count) BreakSession records older than 90 days")
        }
        defaults.set(today, forKey: lastPruneKey)
    }
}
