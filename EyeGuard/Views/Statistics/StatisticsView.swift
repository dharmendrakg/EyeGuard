import SwiftUI
import SwiftData

struct StatisticsView: View {
    // Use bounded @Query predicates initialised in init() to prevent unbounded memory growth.
    // A 7-day window covers the chart and today's stats; DailySummary covers streak calculations.
    // Initialising @Query in init() allows dynamic (runtime-computed) date predicates while
    // still retaining @Query's reactive auto-update behaviour.
    @Query private var sessions: [BreakSession]
    @Query private var summaries: [DailySummary]

    init() {
        let cal = Calendar.current
        let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: Date().startOfDay)!
        _sessions = Query(
            filter: #Predicate<BreakSession> { $0.scheduledAt >= sevenDaysAgo },
            sort: \BreakSession.scheduledAt, order: .reverse
        )
        _summaries = Query(
            filter: #Predicate<DailySummary> { $0.date >= sevenDaysAgo },
            sort: \DailySummary.date, order: .reverse
        )
    }

    private var todaySessions: [BreakSession] {
        sessions.filter { $0.scheduledAt.isSameDay(as: Date()) }
    }

    private var todayTaken: Int { todaySessions.filter { !$0.wasSkipped && !$0.wasDeferred }.count }
    private var todaySkipped: Int { todaySessions.filter { $0.wasSkipped }.count }
    private var todayDeferred: Int { todaySessions.filter { $0.wasDeferred }.count }

    /// Today's compliance rate, sourced from `DailySummary` to share a single
    /// formula with `StreakView`. Falls back to computed value when no summary exists yet.
    private var todayCompliance: Double {
        let cal = Calendar.current
        if let todaySummary = summaries.first(where: { cal.isDateInToday($0.date) }) {
            return todaySummary.complianceRate
        }
        // No summary written yet today — compute from in-memory sessions
        let total = todayTaken + todaySkipped
        guard total > 0 else { return 1.0 }
        return Double(todayTaken) / Double(total)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Today's summary
                HStack(spacing: 24) {
                    statCard(value: "\(todayTaken)", label: "Taken today", color: .green)
                    statCard(value: "\(todaySkipped)", label: "Skipped today", color: .orange)
                    statCard(value: "\(todayDeferred)", label: "Deferred today", color: .yellow)
                    statCard(
                        value: String(format: "%.0f%%", todayCompliance * 100),
                        label: "Today's compliance",
                        color: .blue
                    )
                    // Pass the already-fetched summaries to avoid a duplicate @Query
                    StreakView(summaries: summaries)
                        .padding(16)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }

                Divider()

                // 7-day chart — pass already-fetched sessions to avoid a duplicate @Query
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last 7 Days")
                        .font(.headline)
                    DailyChartView(sessions: sessions)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 520, minHeight: 380)
        .navigationTitle("Statistics")
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}
