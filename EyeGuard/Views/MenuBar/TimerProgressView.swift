import SwiftUI

struct TimerProgressView: View {
    let timeRemaining: TimeInterval
    let totalDuration: TimeInterval

    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return timeRemaining / totalDuration
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 3)
                .frame(width: 36, height: 36)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            Text(timeRemaining.minuteSecondDisplay)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
    }
}
