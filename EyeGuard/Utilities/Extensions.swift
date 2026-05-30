import Foundation
import SwiftUI
extension TimeInterval {
    /// Format as "MM:SS"
    var minuteSecondDisplay: String {
        let totalSeconds = Int(max(0, self))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Format as natural language, e.g. "20 min 0 sec"
    var shortDisplay: String {
        let totalSeconds = Int(max(0, self))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes) min \(seconds) sec"
        }
        return "\(seconds) sec"
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}
