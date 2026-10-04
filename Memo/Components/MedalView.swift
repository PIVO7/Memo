import SwiftUI

/// Hoe zwaar een trofee was om te verdienen. De kast loopt van makkelijk
/// naar moeilijk: het eerste derde is brons, dan zilver, dan goud. Zo zie
/// je in één oogopslag hoe ver je al bent.
enum MedalTier: Equatable {
    case brons, zilver, goud

    init(rank: Int, of count: Int) {
        switch rank * 3 / max(count, 1) {
        case 0: self = .brons
        case 1: self = .zilver
        default: self = .goud
        }
    }

    /// Vaste metaalkleuren, in elk thema dezelfde: goud blijft goud.
    var rim: Color {
        switch self {
        case .brons: Color(red: 0.89, green: 0.57, blue: 0.34)
        case .zilver: Color(red: 0.72, green: 0.77, blue: 0.83)
        case .goud: Color(red: 1.00, green: 0.76, blue: 0.16)
        }
    }

    var face: Color {
        switch self {
        case .brons: Color(red: 0.98, green: 0.80, blue: 0.62)
        case .zilver: Color(red: 0.92, green: 0.94, blue: 0.97)
        case .goud: Color(red: 1.00, green: 0.89, blue: 0.52)
        }
    }
}

/// Een rozet in de speelgoedstijl: twee lintjes, een gekartelde rand in het
/// metaal van de trofee en een vlak met het symbool. Nog niet verdiend? Dan
/// staat hij er grijs en met een slotje, zodat er iets te verzamelen valt.
struct MedalView: View {
    var symbol: String
    var tier: MedalTier
    var isEarned: Bool
    /// Doorsnede van de rozet; de lintjes hangen er een kwart onder uit.
    var size: CGFloat
    var depth: CGFloat = 3

    private var line: CGFloat { max(size * 0.05, 1.5) }
    private var stroke: Color { isEarned ? AppTheme.ink : AppTheme.offInk }

    var body: some View {
        ZStack(alignment: .top) {
            ribbons
                .padding(.top, size * 0.5)
            disc
        }
        .frame(width: size, height: size * 1.25, alignment: .top)
        .accessibilityHidden(true)
    }

    private var ribbons: some View {
        HStack(spacing: -size * 0.04) {
            tail(isEarned ? AppTheme.coral : AppTheme.offFill)
                .rotationEffect(.degrees(18), anchor: .top)
            tail(isEarned ? AppTheme.sky : AppTheme.offFill)
                .rotationEffect(.degrees(-18), anchor: .top)
        }
    }

    private func tail(_ fill: Color) -> some View {
        RibbonTail()
            .fill(fill)
            .overlay {
                RibbonTail().stroke(stroke, style: StrokeStyle(lineWidth: line, lineJoin: .round))
            }
            .frame(width: size * 0.3, height: size * 0.66)
    }

    private var disc: some View {
        ZStack {
            MedalRim().fill(isEarned ? tier.rim : AppTheme.offFill)
            MedalRim().stroke(stroke, style: StrokeStyle(lineWidth: line, lineJoin: .round))

            Circle()
                .fill(isEarned ? tier.face : AppTheme.sunk)
                .overlay { Circle().strokeBorder(stroke, lineWidth: line * 0.8) }
                .frame(width: size * 0.64, height: size * 0.64)

            if isEarned {
                // Een glimlichtje linksboven: zonder dat leest metaal als verf.
                Capsule()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: size * 0.06, height: size * 0.16)
                    .rotationEffect(.degrees(40))
                    .offset(x: -size * 0.17, y: -size * 0.15)
            }

            Image(systemName: isEarned ? symbol : "lock.fill")
                .font(.system(size: size * 0.28, weight: .black))
                .foregroundStyle(stroke)
        }
        .frame(width: size, height: size)
        .background {
            MedalRim()
                .fill(stroke)
                .offset(y: isEarned ? depth : 0)
        }
    }
}

/// De gekartelde rand van een rozet: een cirkel met zachte bobbeltjes.
struct MedalRim: Shape {
    var bumps = 14

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.86
        let step = 2 * Double.pi / Double(bumps)

        func point(_ angle: Double, _ radius: CGFloat) -> CGPoint {
            CGPoint(x: center.x + radius * CGFloat(cos(angle)),
                    y: center.y + radius * CGFloat(sin(angle)))
        }

        var path = Path()
        for i in 0..<bumps {
            let start = Double(i) * step - Double.pi / 2
            if i == 0 { path.move(to: point(start, inner)) }
            path.addQuadCurve(to: point(start + step, inner),
                              control: point(start + step / 2, outer * 1.14))
        }
        path.closeSubpath()
        return path
    }
}

/// Een lintje met een inkeping onderaan, zoals bij een echte rozet.
struct RibbonTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.width * 0.45))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    HStack(spacing: 20) {
        MedalView(symbol: "crown.fill", tier: .brons, isEarned: true, size: 64)
        MedalView(symbol: "flame.fill", tier: .zilver, isEarned: true, size: 64)
        MedalView(symbol: "trophy.fill", tier: .goud, isEarned: true, size: 64)
        MedalView(symbol: "trophy.fill", tier: .goud, isEarned: false, size: 64)
    }
    .padding()
    .background(AppTheme.cream)
}
