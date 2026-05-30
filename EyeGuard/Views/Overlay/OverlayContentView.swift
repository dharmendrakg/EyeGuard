import SwiftUI

struct OverlayContentView: View {
    let config: BreakOverlayConfig
    @State private var opacity: Double = 0
    @State private var iconPulse: Bool = false

    // NOTE: timerService and settings are passed as plain properties (not via @Environment)
    // because this view is hosted via NSHostingView in OverlayManager.createPanels().
    // SwiftUI environment values do not flow through NSHostingView boundaries, so
    // environment injection is unavailable here — this is an intentional architectural constraint.

    // Reference to timer for break state observation and actions.
    // Uses `any TimerControlling` so the view has no dependency on the concrete TimerService type.
    let timerService: any TimerControlling

    var body: some View {
        ZStack {
            // Layer 1: Blur background (fades out at low opacity to allow true transparency)
            VisualEffectBlur()
                .ignoresSafeArea()
                .opacity(min(1.0, max(0.0, (config.opacity - 0.05) / 0.25)))

            // Layer 2: Semi-transparent overlay (user-controlled opacity)
            Color.black.opacity(config.opacity)
                .ignoresSafeArea()

            // Layer 3: Animated particles (always visible, independent of content toggle)
            ParticleBackgroundView(theme: config.theme)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            // Layer 4: Break content (opacity-hidden to preserve view identity and avoid
            // disrupting sibling views like ParticleBackgroundView)
            VStack(spacing: 0) {
                Spacer()
                headerView
                Spacer().frame(height: 28)
                breakTimerSection
                Spacer()
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
            .opacity(config.showElements ? 1 : 0)
            .allowsHitTesting(config.showElements)

            // Action buttons — independently controlled, always at bottom
            if config.showSnoozeButton || config.showSkipButton {
                actionButtonsView
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) {
                opacity = 1.0
            }
            iconPulse = true
        }
    }

    // MARK: - Subviews

    /// Eye icon + "Time for an Eye Break" title.
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, Color(red: 0.7, green: 0.85, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(iconPulse ? 1.05 : 1.0)
                .opacity(iconPulse ? 1.0 : 0.85)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: iconPulse
                )

            Text("Time for an Eye Break")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    /// Countdown ring, instruction text, and health tip card.
    private var breakTimerSection: some View {
        VStack(spacing: 0) {
            BreakTimerView(
                timeRemaining: timerService.breakTimeRemaining,
                totalDuration: config.duration
            )

            Spacer().frame(height: 32)

            // Primary action instruction
            Text("Look at something 20 feet away")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .padding(.bottom, 16)

            tipCardView
        }
    }

    /// Contextual eye-health tip in a subtle rounded container.
    private var tipCardView: some View {
        Text(config.tip)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .frame(maxWidth: 440)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
    }

    /// Snooze and skip buttons anchored to the bottom of the overlay.
    private var actionButtonsView: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                if config.showSnoozeButton {
                    Button(action: { timerService.deferBreak() }) {
                        Text("Snooze \(Int(config.snoozeDuration / 60)) min")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
                if config.showSkipButton {
                    Button(action: { timerService.skipBreak() }) {
                        Text("Skip Break")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.08), in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 40)
        }
    }
}

/// NSVisualEffectView wrapper for SwiftUI
struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .fullScreenUI
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
