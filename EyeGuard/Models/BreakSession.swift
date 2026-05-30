import Foundation
import SwiftData

@Model
final class BreakSession {
    var id: UUID
    var scheduledAt: Date
    var startedAt: Date?
    var endedAt: Date?
    var wasSkipped: Bool
    var wasDeferred: Bool
    var durationSeconds: Int
    var tipShown: String?

    init(
        scheduledAt: Date,
        durationSeconds: Int = Int(Constants.Timer.defaultBreakDuration)
    ) {
        self.id = UUID()
        self.scheduledAt = scheduledAt
        self.wasSkipped = false
        self.wasDeferred = false
        self.durationSeconds = durationSeconds
    }

    var isCompleted: Bool {
        endedAt != nil && !wasSkipped
    }

    var actualDuration: TimeInterval? {
        guard let start = startedAt, let end = endedAt else { return nil }
        return end.timeIntervalSince(start)
    }
}
