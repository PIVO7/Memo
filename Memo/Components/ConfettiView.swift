import SwiftUI

/// Vallende confetti in de accentkleuren van het thema. Puur decor: geen
/// hit-testing, en bij Verminder beweging tekent hij helemaal niets. De
/// eigenaar haalt de view weg wanneer het feestje voorbij is.
struct ConfettiView: View {
    var particleCount = 28

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    private struct Particle {
        let x0: Double
        let vx: Double
        let fall: Double
        let delay: Double
        let spin: Double
        let colorIndex: Int
        let width: Double
        let height: Double
    }

    /// Deterministisch "willekeurig" per stukje, zodat de view geen eigen
    /// toestand hoeft bij te houden.
    private var particles: [Particle] {
        (0..<particleCount).map { index in
            var rng = SplitMix64(seed: UInt64(index) &* 0x9E3779B97F4A7C15 &+ 7)
            func unit() -> Double { Double(rng.next() % 1000) / 1000 }
            return Particle(
                x0: unit(),
                vx: (unit() - 0.5) * 0.25,
                fall: 240 + unit() * 200,
                delay: unit() * 0.5,
                spin: (unit() - 0.5) * 10,
                colorIndex: Int(rng.next() % 4),
                width: 7 + unit() * 5,
                height: 10 + unit() * 6
            )
        }
    }

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation) { context in
                Canvas { graphics, size in
                    let colors = [AppTheme.coral, AppTheme.amber, AppTheme.mint, AppTheme.sky]
                    let elapsed = context.date.timeIntervalSince(start)

                    for particle in particles {
                        let t = elapsed - particle.delay
                        guard t > 0, t < 1.8 else { continue }

                        let x = (particle.x0 + particle.vx * t) * size.width
                        let y = -24 + particle.fall * t * t * 0.9 + 60 * t
                        guard y < size.height + 30 else { continue }

                        var ctx = graphics
                        ctx.opacity = t > 1.3 ? max(0, (1.8 - t) / 0.5) : 1
                        ctx.translateBy(x: x, y: y)
                        ctx.rotate(by: .radians(particle.spin * t))
                        let rect = CGRect(
                            x: -particle.width / 2,
                            y: -particle.height / 2,
                            width: particle.width,
                            height: particle.height
                        )
                        ctx.fill(
                            Path(roundedRect: rect, cornerRadius: 2.5),
                            with: .color(colors[particle.colorIndex])
                        )
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

#Preview {
    ConfettiView()
        .frame(width: 380, height: 500)
        .background(AppTheme.cream)
}
