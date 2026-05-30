import SwiftUI

// MARK: - Particle (pre-resolved color, cached shape path)

struct Particle {
    let id: Int
    let initialX: Double     // 0...1 normalized
    let initialY: Double     // 0...1 normalized (start position)
    let size: Double
    let speed: Double        // normalized units per second
    let opacity: Double
    let rotation: Double     // initial rotation in radians
    let rotationSpeed: Double
    let drift: Double        // horizontal sway amplitude (normalized)
    let driftPhase: Double   // phase offset for sway sine
    let color: Color         // pre-resolved at creation (no per-frame lookup)
    let cachedPath: Path?    // pre-built path for leaf/raindrop shapes
    // Realism enhancement fields (all pre-computed — zero per-frame cost)
    let driftFrequency2: Double   // secondary drift sine frequency
    let driftAmplitude2: Double   // secondary drift sine amplitude
    let depthLayer: Double        // 0.0 (far) to 1.0 (near) — affects opacity/size scaling
    let flutter: Double           // leaf-specific: rapid oscillation amplitude
    let flutterFreq: Double       // leaf-specific: flutter frequency
    let windPhase: Double         // per-particle phase for wind gust / pulse effect
    // Cached paths for circle/star shapes (centered at origin; draw via translateBy)
    // Eliminates per-frame Path heap allocations for these shapes.
    let cachedCirclePath: Path?       // circle/dot at origin for snow, bubbles, fireflies, stars
    let cachedInnerCirclePath: Path?  // bubble inner fill (60% size), origin-centered
    let cachedSpecularPath: Path?     // bubble specular highlight, origin-relative offset baked in
    let cachedArmHPath: Path?         // star horizontal diffraction arm, origin-centered
    let cachedArmVPath: Path?         // star vertical diffraction arm, origin-centered
}

// MARK: - ParticleConfig

struct ParticleConfig {
    let count: Int
    let sizeRange: ClosedRange<Double>
    let speedRange: ClosedRange<Double>
    let colors: [Color]
    let shape: ParticleShape
    let driftRange: ClosedRange<Double>
    let direction: ParticleDirection

    enum ParticleShape {
        case circle
        case leaf
        case raindrop
        case star
    }

    enum ParticleDirection {
        case down
        case up
        case stationary  // starfield
    }
}

// MARK: - Theme configs

extension ParticleConfig {
    static func config(for theme: OverlayTheme) -> ParticleConfig? {
        switch theme {
        case .minimal:
            return nil

        case .fallingLeaves:
            return ParticleConfig(
                count: 25,
                sizeRange: 12...24,
                speedRange: 0.03...0.10,
                colors: [
                    Color(red: 0.85, green: 0.35, blue: 0.1),
                    Color(red: 0.9,  green: 0.6,  blue: 0.1),
                    Color(red: 0.5,  green: 0.75, blue: 0.2),
                    Color(red: 0.7,  green: 0.2,  blue: 0.1),
                    Color(red: 0.95, green: 0.75, blue: 0.2),
                ],
                shape: .leaf,
                driftRange: 0.02...0.06,
                direction: .down
            )

        case .snowfall:
            return ParticleConfig(
                count: 60,
                sizeRange: 4...10,
                speedRange: 0.05...0.10,
                colors: [
                    .white,
                    Color(red: 0.85, green: 0.93, blue: 1.0),
                    Color(red: 0.75, green: 0.88, blue: 0.98),
                ],
                shape: .circle,
                driftRange: 0.005...0.02,
                direction: .down
            )

        case .bubbles:
            return ParticleConfig(
                count: 20,
                sizeRange: 10...32,
                speedRange: 0.03...0.07,
                colors: [
                    Color(red: 1.0,  green: 0.7,  blue: 0.9).opacity(0.6),
                    Color(red: 0.7,  green: 0.9,  blue: 1.0).opacity(0.6),
                    Color(red: 0.85, green: 1.0,  blue: 0.8).opacity(0.6),
                    Color(red: 1.0,  green: 0.95, blue: 0.7).opacity(0.6),
                    Color(red: 0.9,  green: 0.75, blue: 1.0).opacity(0.6),
                ],
                shape: .circle,
                driftRange: 0.005...0.015,
                direction: .up
            )

        case .starfield:
            return ParticleConfig(
                count: 80,
                sizeRange: 2...7,
                speedRange: 0.3...0.9,
                colors: [
                    .white,
                    Color(red: 1.0, green: 0.97, blue: 0.8),
                    Color(red: 0.8, green: 0.9,  blue: 1.0),
                ],
                shape: .star,
                driftRange: 0.0...0.0,
                direction: .stationary
            )

        case .rain:
            return ParticleConfig(
                count: 120,
                sizeRange: 1...2,
                speedRange: 0.4...0.65,
                colors: [
                    Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.7),
                    Color(red: 0.6, green: 0.8,  blue: 1.0).opacity(0.6),
                    .white.opacity(0.5),
                ],
                shape: .raindrop,
                driftRange: 0.002...0.006,
                direction: .down
            )

        case .fireflies:
            return ParticleConfig(
                count: 30,
                sizeRange: 4...12,
                speedRange: 0.005...0.015,
                colors: [
                    Color(red: 0.95, green: 0.9,  blue: 0.3).opacity(0.8),
                    Color(red: 0.8,  green: 1.0,  blue: 0.4).opacity(0.7),
                    Color(red: 1.0,  green: 0.85, blue: 0.3).opacity(0.9),
                    Color(red: 0.6,  green: 1.0,  blue: 0.5).opacity(0.6),
                ],
                shape: .circle,
                driftRange: 0.01...0.04,
                direction: .up
            )

        case .sakura:
            return ParticleConfig(
                count: 30,
                sizeRange: 10...20,
                speedRange: 0.02...0.06,
                colors: [
                    Color(red: 1.0,  green: 0.75, blue: 0.8),
                    Color(red: 1.0,  green: 0.85, blue: 0.9),
                    Color(red: 0.95, green: 0.6,  blue: 0.75),
                    Color(red: 1.0,  green: 0.9,  blue: 0.92),
                ],
                shape: .leaf,
                driftRange: 0.02...0.05,
                direction: .down
            )
        }
    }
}

// MARK: - Particle factory (pre-resolves color and caches paths)

extension Particle {
    static func makeParticles(config: ParticleConfig) -> [Particle] {
        var rng = SeededRNG(seed: config.count &* 7 + 42)
        return (0..<config.count).map { i in
            let size = config.sizeRange.lowerBound + rng.next() * (config.sizeRange.upperBound - config.sizeRange.lowerBound)
            let colorIndex = Int(rng.next() * Double(config.colors.count))
                .clamped(to: 0...(config.colors.count - 1))
            let resolvedColor = config.colors[colorIndex]

            // Pre-compute speed here so raindrop path can use speed-dependent height
            let speed = config.speedRange.lowerBound + rng.next() * (config.speedRange.upperBound - config.speedRange.lowerBound)

            // Pre-build path for shapes that use geometry
            let path: Path? = {
                switch config.shape {
                case .leaf:
                    return Particle.makeLeafPath(size: size)
                case .raindrop:
                    let w = size
                    // Faster drops are longer streaks: base 6x, up to 14x at max speed
                    let speedFraction = (speed - config.speedRange.lowerBound) /
                        max(config.speedRange.upperBound - config.speedRange.lowerBound, 0.001)
                    let h = size * (6.0 + speedFraction * 8.0)
                    let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
                    return Path(roundedRect: rect, cornerRadius: w / 2)
                default:
                    return nil
                }
            }()

            // Pre-build origin-centered paths for circle/star shapes.
            // At draw time, use context.translateBy(x: cx, y: cy) then fill the cached path —
            // identical geometry to per-frame CGRect construction, zero heap allocation per frame.
            let cachedCirclePath: Path? = {
                switch config.shape {
                case .circle, .star:
                    let r = size * 0.5
                    return Path(ellipseIn: CGRect(x: -r, y: -r, width: size, height: size))
                default:
                    return nil
                }
            }()

            // Bubble-specific: inner fill (60% of outer size), centered at origin
            let cachedInnerCirclePath: Path? = {
                guard config.shape == .circle && config.direction == .up else { return nil }
                let inner = size * 0.6
                let ir = inner * 0.5
                return Path(ellipseIn: CGRect(x: -ir, y: -ir, width: inner, height: inner))
            }()

            // Bubble-specific: specular highlight offset baked in (upper-left, relative to origin)
            let cachedSpecularPath: Path? = {
                guard config.shape == .circle && config.direction == .up else { return nil }
                let r    = size * 0.5
                let hSize = size * 0.26
                let hOff  = r * 0.32
                let hRect = CGRect(
                    x: -hOff - hSize * 0.5,
                    y: -hOff - hSize * 0.4,
                    width:  hSize,
                    height: hSize * 0.7
                )
                return Path(ellipseIn: hRect)
            }()

            // Star-specific: diffraction arm paths centered at origin (only for larger stars)
            let cachedArmHPath: Path? = {
                guard config.shape == .star && size > 4.5 else { return nil }
                let armLen = size * 2.5
                let armW   = size * 0.15
                return Path(ellipseIn: CGRect(x: -armLen * 0.5, y: -armW * 0.5, width: armLen, height: armW))
            }()
            let cachedArmVPath: Path? = {
                guard config.shape == .star && size > 4.5 else { return nil }
                let armLen = size * 2.5
                let armW   = size * 0.15
                return Path(ellipseIn: CGRect(x: -armW * 0.5, y: -armLen * 0.5, width: armW, height: armLen))
            }()

            // Existing ordered fields (order preserved for seed stability)
            let initialX    = rng.next()
            let initialY    = rng.next()
            // speed already consumed above — skip one rng call to match original order slot
            let opacity     = 0.5 + rng.next() * 0.5
            let rotation    = rng.next() * .pi * 2
            let rotationSpeed = (rng.next() - 0.5) * .pi
            let drift       = config.driftRange.lowerBound + rng.next() * (config.driftRange.upperBound - config.driftRange.lowerBound)
            let driftPhase  = rng.next() * .pi * 2

            // New realism fields appended after all original fields
            let driftFrequency2 = 0.7 + rng.next() * 2.0   // 0.7...2.7 Hz
            let driftAmplitude2 = drift * (0.3 + rng.next() * 0.5)  // 30-80% of primary drift
            let depthLayer      = rng.next()                 // 0.0 (far) to 1.0 (near)
            let flutter         = 0.3 + rng.next() * 0.7    // oscillation amplitude in radians
            let flutterFreq     = 3.0 + rng.next() * 5.0    // 3...8 Hz rapid flutter
            let windPhase       = rng.next() * .pi * 2      // per-particle phase

            return Particle(
                id: i,
                initialX: initialX,
                initialY: initialY,
                size: size,
                speed: speed,
                opacity: opacity,
                rotation: rotation,
                rotationSpeed: rotationSpeed,
                drift: drift,
                driftPhase: driftPhase,
                color: resolvedColor,
                cachedPath: path,
                driftFrequency2: driftFrequency2,
                driftAmplitude2: driftAmplitude2,
                depthLayer: depthLayer,
                flutter: flutter,
                flutterFreq: flutterFreq,
                windPhase: windPhase,
                cachedCirclePath: cachedCirclePath,
                cachedInnerCirclePath: cachedInnerCirclePath,
                cachedSpecularPath: cachedSpecularPath,
                cachedArmHPath: cachedArmHPath,
                cachedArmVPath: cachedArmVPath
            )
        }
    }

    /// Asymmetric leaf: one side curves wider, one side narrows, with a subtle center vein
    private static func makeLeafPath(size: Double) -> Path {
        Path { p in
            let h = size
            let wRight = size * 0.62   // wider convex side
            let wLeft  = size * 0.40   // narrower side — asymmetry gives a real leaf silhouette
            // Tip offset: slightly shift the base to create a tapered, non-symmetric leaf
            let tipBias = size * 0.06
            p.move(to: CGPoint(x: tipBias, y: -h / 2))
            p.addQuadCurve(
                to: CGPoint(x: -tipBias, y: h / 2),
                control: CGPoint(x: wRight, y: size * 0.1)
            )
            p.addQuadCurve(
                to: CGPoint(x: tipBias, y: -h / 2),
                control: CGPoint(x: -wLeft, y: -size * 0.05)
            )
        }
    }
}

// MARK: - SeededRNG

struct SeededRNG {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed)) ^ 0xA3B1945CAB68E3F7
    }

    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let bits = UInt32(truncatingIfNeeded: state >> 32)
        return Double(bits) / Double(UInt32.max)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

// MARK: - Position computation (functional model — no per-frame allocations)

struct ParticlePosition {
    var x: Double
    var y: Double
    var opacity: Double
    var rotation: Double
}

extension ParticlePosition {
    /// Computes position for downward-moving particles (leaves, snow, rain)
    static func computeDown(particle: Particle, elapsed: Double) -> ParticlePosition {
        var y = (particle.initialY + particle.speed * elapsed).truncatingRemainder(dividingBy: 1.0)
        if y < 0 { y += 1.0 }

        // Multi-frequency horizontal drift for organic, non-repetitive paths
        let sway1 = particle.drift  * sin(elapsed * 1.5 + particle.driftPhase)
        let sway2 = particle.driftAmplitude2 * sin(elapsed * particle.driftFrequency2 + particle.windPhase)
        // Micro-jitter third frequency (snow brownian-like)
        let sway3 = particle.drift * 0.15 * sin(elapsed * 4.3 + particle.driftPhase + 1.1)
        var x = particle.initialX + sway1 + sway2 + sway3
        x = x - floor(x)

        // Leaf flutter: rapid rotation oscillation overlaid on steady spin
        let steadySpin = particle.rotation + particle.rotationSpeed * elapsed
        let flutterAngle = particle.flutter * sin(elapsed * particle.flutterFreq + particle.driftPhase)
        let rot = steadySpin + flutterAngle

        // Depth-based opacity: far particles (depthLayer ≈ 0) are dimmer
        let depthOpacity = particle.opacity * (0.35 + 0.65 * particle.depthLayer)

        return ParticlePosition(x: x, y: y, opacity: depthOpacity, rotation: rot)
    }

    /// Computes position for upward-moving particles (bubbles)
    static func computeUp(particle: Particle, elapsed: Double) -> ParticlePosition {
        var y = (particle.initialY - particle.speed * elapsed).truncatingRemainder(dividingBy: 1.0)
        if y < 0 { y += 1.0 }

        // Wobble amplitude grows as bubble rises (capped so it doesn't go wild)
        let wobbleGrowth = min(1.0 + elapsed * 0.08, 2.2)
        let sway1 = particle.drift * wobbleGrowth * sin(elapsed * 1.2 + particle.driftPhase)
        let sway2 = particle.driftAmplitude2 * sin(elapsed * particle.driftFrequency2 + particle.windPhase)
        var x = particle.initialX + sway1 + sway2
        x = x - floor(x)

        let depthOpacity = particle.opacity * (0.4 + 0.6 * particle.depthLayer)
        return ParticlePosition(x: x, y: y, opacity: depthOpacity, rotation: 0)
    }

    /// Computes twinkle for stationary stars
    static func computeStationary(particle: Particle, elapsed: Double) -> ParticlePosition {
        let t = elapsed
        // Three-harmonic scintillation — each star has a unique beat pattern
        let h1 = 0.40 * abs(sin(t * particle.speed + particle.driftPhase))
        let h2 = 0.35 * abs(sin(t * particle.speed * 1.73 + particle.windPhase))
        let h3 = 0.25 * abs(sin(t * particle.speed * 0.47 + particle.driftPhase + 1.3))
        var twinkle = h1 + h2 + h3   // 0...1 range

        // Occasional bright pulse: smooth gradual activation to prevent synchronized
        // draw-call spikes across multiple stars with similar speeds.
        // Quadratic ease-in from 0.85 threshold (was hard-threshold at 0.92).
        let pulsePhase = sin(t * particle.speed * 0.31 + particle.flutter)
        let pulseActivation = max(0, (pulsePhase - 0.85) / 0.15)  // gradual 0→1 over top 15%
        let pulseIntensity = pulseActivation * pulseActivation      // quadratic ease — softer onset
        twinkle = min(twinkle + pulseIntensity * 0.6, 1.0)
        twinkle = max(0.08, twinkle)  // never fully invisible

        return ParticlePosition(x: particle.initialX, y: particle.initialY, opacity: twinkle, rotation: 0)
    }
}
