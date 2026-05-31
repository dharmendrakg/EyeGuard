import SwiftUI
import AppKit

struct ParticleBackgroundView: View {
    let theme: OverlayTheme

    @State private var startDate: Date = .now
    @State private var particles: [Particle] = []
    @State private var cachedConfig: ParticleConfig?

    var body: some View {
        // For the minimal theme there are no particles to draw. Returning early avoids
        // firing the TimelineView at display-refresh rate (60 Hz) for no visual output.
        if theme == .minimal {
            Color.clear
        } else if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            // When the user has enabled "Reduce Motion" in System Settings, skip particles
            // entirely — a static tint is sufficient and avoids GPU work during breaks.
            Color.clear
        } else {
            // Cap to 30 fps — particle motion is perceptually indistinguishable at 30 vs
            // 60 fps for slow-drifting elements, and halves GPU load per screen.
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas(opaque: false, colorMode: .linear, rendersAsynchronously: true) { context, size in
                    guard let config = cachedConfig else { return }
                    // Wrap elapsed to a 10-minute window (defensive: break overlays are ≤30 s).
                    // Prevents unbounded Double growth on any edge case where the overlay lingers.
                    let rawElapsed = timeline.date.timeIntervalSince(startDate)
                    let elapsed = rawElapsed.truncatingRemainder(dividingBy: 600.0)

                    switch config.direction {
                    case .down:
                        drawParticlesDown(elapsed: elapsed, config: config, context: &context, size: size)
                    case .up:
                        drawParticlesUp(elapsed: elapsed, config: config, context: &context, size: size)
                    case .stationary:
                        drawParticlesStationary(elapsed: elapsed, config: config, context: &context, size: size)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()
            .onAppear { initializeParticles() }
            .onChange(of: theme) { _, _ in initializeParticles() }
        }
    }

    // MARK: - Setup (runs once per theme, not per frame)

    // Per-screen particle budget. Limits GPU work on multi-screen setups without
    // altering single-screen themes that are already under this threshold.
    private static let perScreenParticleBudget = 60

    private func initializeParticles() {
        startDate = .now
        let config = ParticleConfig.config(for: theme)
        cachedConfig = config
        guard let config else {
            particles = []
            return
        }
        // Apply per-screen budget cap: rain (120) and starfield (80) exceed it.
        // Trimming the prefix preserves RNG consistency for the kept particles.
        let all = Particle.makeParticles(config: config)
        particles = all.count > Self.perScreenParticleBudget
            ? Array(all.prefix(Self.perScreenParticleBudget))
            : all
    }

    // MARK: - Direction-specific draw loops (no per-particle branching)

    private func drawParticlesDown(elapsed: Double, config: ParticleConfig, context: inout GraphicsContext, size: CGSize) {
        for particle in particles {
            let pos = ParticlePosition.computeDown(particle: particle, elapsed: elapsed)
            drawParticle(particle: particle, config: config, position: pos, context: &context, size: size)
        }
    }

    private func drawParticlesUp(elapsed: Double, config: ParticleConfig, context: inout GraphicsContext, size: CGSize) {
        for particle in particles {
            let pos = ParticlePosition.computeUp(particle: particle, elapsed: elapsed)
            drawParticle(particle: particle, config: config, position: pos, context: &context, size: size)
        }
    }

    private func drawParticlesStationary(elapsed: Double, config: ParticleConfig, context: inout GraphicsContext, size: CGSize) {
        for particle in particles {
            let pos = ParticlePosition.computeStationary(particle: particle, elapsed: elapsed)
            drawParticle(particle: particle, config: config, position: pos, context: &context, size: size)
        }
    }

    // MARK: - Drawing (uses pre-resolved color and cached paths)

    private func drawParticle(
        particle: Particle,
        config: ParticleConfig,
        position: ParticlePosition,
        context: inout GraphicsContext,
        size: CGSize
    ) {
        let cx = position.x * size.width
        let cy = position.y * size.height

        switch config.shape {
        case .circle:
            guard let circlePath = particle.cachedCirclePath else { return }

            if config.direction == .up {
                // Bubbles: 3 fills — use drawLayer to scope state changes without COW on parent.
                guard let innerPath = particle.cachedInnerCirclePath,
                      let specularPath = particle.cachedSpecularPath else { return }
                context.drawLayer { ctx in
                    ctx.translateBy(x: cx, y: cy)
                    // Outer ring: full size, low opacity
                    ctx.opacity = position.opacity * 0.25
                    ctx.fill(circlePath, with: .color(particle.color))
                    // Inner fill: 60% size, higher opacity — simulates brighter center
                    ctx.opacity = position.opacity * 0.55
                    ctx.fill(innerPath, with: .color(particle.color))
                    // Specular highlight: small bright ellipse, offset baked into path geometry
                    ctx.opacity = position.opacity * 0.6
                    ctx.fill(specularPath, with: .color(.white))
                }
            } else {
                // Snow / fireflies: single fill — lightweight var-copy pattern is sufficient.
                var ctx = context
                ctx.opacity = position.opacity
                ctx.translateBy(x: cx, y: cy)
                ctx.fill(circlePath, with: .color(particle.color))
            }

        case .leaf:
            guard let path = particle.cachedPath else { return }
            var ctx = context
            ctx.opacity = position.opacity
            ctx.translateBy(x: cx, y: cy)
            ctx.rotate(by: .radians(position.rotation))
            ctx.fill(path, with: .color(particle.color))

        case .raindrop:
            guard let path = particle.cachedPath else { return }
            var ctx = context
            ctx.translateBy(x: cx, y: cy)
            // Wind angle tilt: constant ~8° plus small per-particle variation
            let windAngle = 0.14 + particle.depthLayer * 0.04
            ctx.rotate(by: .radians(windAngle))
            // Depth-modulated opacity (no gradient allocation — solid fill is zero-alloc)
            ctx.opacity = position.opacity * (0.5 + 0.5 * particle.depthLayer)
            ctx.fill(path, with: .color(particle.color))

        case .star:
            guard let circlePath = particle.cachedCirclePath else { return }
            let s = particle.size

            // For brighter stars (size > 4.5), draw faint diffraction cross before the dot.
            // Skip when effective opacity is below perceptible threshold to avoid wasted fills.
            if s > 4.5,
               let armH = particle.cachedArmHPath,
               let armV = particle.cachedArmVPath {
                let crossOpacity = (s - 4.5) / 2.5  // 0 at size 4.5, 1 at size 7
                // Only draw arms when they'd be visible; GPU early-discard is not free on CPU side.
                if crossOpacity * position.opacity > 0.05 {
                    // 3 fills — use drawLayer to scope state without COW on parent context.
                    context.drawLayer { ctx in
                        ctx.translateBy(x: cx, y: cy)
                        ctx.opacity = position.opacity * crossOpacity * 0.35
                        ctx.fill(armH, with: .color(particle.color))
                        ctx.fill(armV, with: .color(particle.color))
                        ctx.opacity = position.opacity
                        ctx.fill(circlePath, with: .color(particle.color))
                    }
                    return
                }
            }

            // Dim stars (or arms below threshold): single fill.
            var ctx = context
            ctx.opacity = position.opacity
            ctx.translateBy(x: cx, y: cy)
            ctx.fill(circlePath, with: .color(particle.color))
        }
    }
}
