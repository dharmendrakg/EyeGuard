import SwiftUI
import SwiftData

struct StreakView: View {
    /// Summaries are passed from the parent view to avoid a duplicate `@Query` fetch.
    let summaries: [DailySummary]

    @State private var cachedStreak: Int = 0

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
                Text("\(cachedStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }
            Text("day streak")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear { cachedStreak = computeStreak() }
        .onChange(of: summaries.map(\.breaksTaken)) { cachedStreak = computeStreak() }
    }

    private func computeStreak() -> Int {
        let cal = Calendar.current
        // Build O(1) lookup by start-of-day to avoid O(n*m) linear scans
        let byDay = Dictionary(grouping: summaries, by: { cal.startOfDay(for: $0.date) })
        var streak = 0
        var checkDate = Date().startOfDay
        while let day = byDay[checkDate]?.first, day.complianceRate >= 0.5 {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }
}
