import SwiftUI

struct MenuBarIconView: View {
    let state: TimerState
    let progress: Double  // 1.0 = full (start of work), 0.0 = depleted (break imminent)
    let nextBreakTime: String?  // e.g. "14:20"

    private var iconName: String {
        switch state {
        case .working: return "eye"
        case .onBreak: return "eye.trianglebadge.exclamationmark"
        case .paused, .idle: return "eye.slash"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                if state == .working {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 18, height: 18)
                }
                Image(systemName: iconName)
                    .font(.system(size: 11))
            }
            .frame(width: 22, height: 22)

            if let time = nextBreakTime {
                Text(time)
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
            }
        }
    }
}
