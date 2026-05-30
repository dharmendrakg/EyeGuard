import Foundation
import SwiftData

@Model
final class DailySummary {
    var date: Date
    var totalWorkSeconds: Int
    var breaksTaken: Int
    var breaksSkipped: Int
    var breaksDeferred: Int

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.totalWorkSeconds = 0
        self.breaksTaken = 0
        self.breaksSkipped = 0
        self.breaksDeferred = 0
    }

    var complianceRate: Double {
        let total = breaksTaken + breaksSkipped
        guard total > 0 else { return 1.0 }
        return Double(breaksTaken) / Double(total)
    }

    var totalBreaks: Int {
        breaksTaken + breaksSkipped
    }
}
