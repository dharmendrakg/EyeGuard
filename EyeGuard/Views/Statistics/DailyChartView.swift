import SwiftUI
import Charts
import SwiftData

struct DailyChartView: View {
    /// Sessions are passed from the parent `StatisticsView` to avoid a duplicate `@Query` fetch.
    let sessions: [BreakSession]

    private struct DayData: Identifiable {
        var id: Date { date }
        let label: String
        let taken: Int
        let skipped: Int
        let date: Date
    }

    private var chartData: [DayData] {
        let cal = Calendar.current
        let today = Date().startOfDay
        return (0..<7).reversed().map { daysAgo in
            let day = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            let daySessions = sessions.filter { cal.isDate($0.scheduledAt, inSameDayAs: day) }
            let taken = daySessions.filter { !$0.wasSkipped }.count
            let skipped = daySessions.filter { $0.wasSkipped }.count
            let label = daysAgo == 0 ? "Today" : cal.shortWeekdaySymbols[cal.component(.weekday, from: day) - 1]
            return DayData(label: label, taken: taken, skipped: skipped, date: day)
        }
    }

    var body: some View {
        Chart {
            ForEach(chartData) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Breaks", day.taken)
                )
                .foregroundStyle(.green.opacity(0.8))
                .annotation(position: .top, alignment: .center) {
                    if day.taken > 0 {
                        Text("\(day.taken)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Skipped", day.skipped)
                )
                .foregroundStyle(.orange.opacity(0.6))
            }
        }
        .chartLegend(position: .bottom) {
            HStack(spacing: 16) {
                legendItem(color: .green.opacity(0.8), label: "Taken")
                legendItem(color: .orange.opacity(0.6), label: "Skipped")
            }
            .font(.caption)
        }
        .frame(height: 160)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}
