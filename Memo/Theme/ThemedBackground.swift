import SwiftUI

/// De schermachtergrond: het effen themavlak, met per thema een handvol
/// subtiele decoraties erbovenop — sterren in de nacht, snoepjes bij Snoep,
/// zeedieren in de Oceaan. Klassiek blijft bewust effen: dat is de rustige
/// standaard. Alles staat op vaste plekken langs de randen, zodat er bij
/// hertekenen niets verspringt en geen knop in de weg zit.
struct ThemedBackground: View {
    var body: some View {
        ZStack {
            AppTheme.cream
            switch ThemeStore.shared.themeID {
            case .klassiek:
                EmptyView()
            case .snoep:
                CandyFieldView()
            case .oceaan:
                OceanLifeView()
            case .nacht:
                NightSkyView()
            }
        }
        .ignoresSafeArea()
    }
}

/// Een rustige sterrenhemel op vaste plekken.
private struct NightSkyView: View {
    /// Posities als fractie van het scherm, met per ster een eigen maat en
    /// helderheid. Vooral langs de randen, waar de minste knoppen staan.
    private static let stars: [(x: CGFloat, y: CGFloat, scale: CGFloat, opacity: CGFloat)] = [
        (0.08, 0.05, 1.0, 0.30), (0.30, 0.09, 0.6, 0.20), (0.87, 0.04, 0.8, 0.28),
        (0.66, 0.07, 0.5, 0.16), (0.13, 0.20, 0.55, 0.18), (0.94, 0.17, 0.6, 0.22),
        (0.04, 0.38, 0.7, 0.24), (0.96, 0.34, 0.5, 0.16), (0.09, 0.56, 0.5, 0.15),
        (0.93, 0.52, 0.75, 0.22), (0.05, 0.74, 0.6, 0.20), (0.95, 0.71, 0.5, 0.16),
        (0.12, 0.90, 0.8, 0.24), (0.55, 0.94, 0.55, 0.16), (0.88, 0.90, 0.65, 0.20),
        (0.42, 0.03, 0.45, 0.14)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(Self.stars.enumerated()), id: \.offset) { index, star in
                    Image(systemName: index.isMultiple(of: 3) ? "sparkle" : "star.fill")
                        .font(.system(size: 13 * star.scale, weight: .bold))
                        .foregroundStyle(.white.opacity(star.opacity))
                        .position(x: geo.size.width * star.x, y: geo.size.height * star.y)
                }

                // Een maantje net onder de statusbalk, links van de knoppen
                // die daar meestal staan.
                Image(systemName: "moon.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.amber.opacity(0.20))
                    .rotationEffect(.degrees(-18))
                    .position(x: geo.size.width * 0.70, y: geo.size.height * 0.095)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Gestrooide smarties en hartjes, met één ingepakt snoepje als blikvanger —
/// de tegenhanger van de maan in het nachtthema.
private struct CandyFieldView: View {
    /// Stipjes (smarties) en hartjes op vaste plekken langs de randen;
    /// kleurindex wijst in `palette` hieronder.
    private static let sweets: [(x: CGFloat, y: CGFloat, scale: CGFloat, opacity: CGFloat, heart: Bool, color: Int)] = [
        (0.07, 0.06, 0.9, 0.30, false, 0), (0.30, 0.09, 0.6, 0.22, true, 2),
        (0.88, 0.05, 0.8, 0.28, false, 3), (0.65, 0.07, 0.5, 0.20, false, 1),
        (0.94, 0.18, 0.6, 0.24, true, 0), (0.12, 0.21, 0.55, 0.20, false, 2),
        (0.04, 0.39, 0.7, 0.26, false, 1), (0.96, 0.35, 0.5, 0.18, false, 2),
        (0.08, 0.57, 0.5, 0.17, true, 3), (0.93, 0.53, 0.75, 0.24, false, 0),
        (0.05, 0.75, 0.6, 0.22, false, 3), (0.95, 0.72, 0.5, 0.18, true, 1),
        (0.11, 0.91, 0.8, 0.26, false, 1), (0.55, 0.94, 0.55, 0.18, false, 0),
        (0.89, 0.90, 0.65, 0.22, false, 2)
    ]

    @MainActor private static var palette: [Color] {
        [AppTheme.coral, AppTheme.amber, AppTheme.sky, AppTheme.mint]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(Self.sweets.enumerated()), id: \.offset) { _, sweet in
                    Image(systemName: sweet.heart ? "heart.fill" : "circle.fill")
                        .font(.system(size: 12 * sweet.scale, weight: .bold))
                        .foregroundStyle(Self.palette[sweet.color].opacity(sweet.opacity))
                        .position(x: geo.size.width * sweet.x, y: geo.size.height * sweet.y)
                }

                WrappedCandyView(size: 17, color: AppTheme.coral.opacity(0.28))
                    .rotationEffect(.degrees(-16))
                    .position(x: geo.size.width * 0.70, y: geo.size.height * 0.095)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Eén snoepje in wikkel: een bolletje met twee gedraaide puntjes.
private struct WrappedCandyView: View {
    let size: CGFloat
    let color: Color

    var body: some View {
        HStack(spacing: -size * 0.06) {
            WrapperTip()
                .fill(color)
                .frame(width: size * 0.5, height: size * 0.78)
                .scaleEffect(x: -1)
            Circle()
                .fill(color)
                .frame(width: size, height: size)
            WrapperTip()
                .fill(color)
                .frame(width: size * 0.5, height: size * 0.78)
        }
    }

    /// Het puntje van de wikkel: een driehoek met de punt naar het snoepje.
    private struct WrapperTip: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }
}

/// Visjes, een schildpad en wat golfjes — de zee op de achtergrond, even
/// rustig als de sterrenhemel.
private struct OceanLifeView: View {
    /// Visjes op vaste plekken; `flipped` laat ze de andere kant op zwemmen.
    private static let fish: [(x: CGFloat, y: CGFloat, scale: CGFloat, opacity: CGFloat, flipped: Bool)] = [
        (0.09, 0.07, 0.9, 0.26, false), (0.90, 0.13, 0.7, 0.22, true),
        (0.06, 0.36, 0.6, 0.20, false), (0.95, 0.42, 0.8, 0.24, true),
        (0.08, 0.62, 0.7, 0.22, true), (0.93, 0.68, 0.55, 0.18, false),
        (0.12, 0.88, 0.75, 0.24, false), (0.60, 0.94, 0.5, 0.16, true)
    ]

    /// Golfjes langs de onderrand en bovenin.
    private static let waves: [(x: CGFloat, y: CGFloat, scale: CGFloat, opacity: CGFloat)] = [
        (0.32, 0.05, 0.7, 0.16), (0.88, 0.55, 0.6, 0.14),
        (0.05, 0.50, 0.55, 0.13), (0.35, 0.96, 0.7, 0.16)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(Self.fish.enumerated()), id: \.offset) { _, fish in
                    Image(systemName: "fish.fill")
                        .font(.system(size: 15 * fish.scale, weight: .bold))
                        .foregroundStyle(AppTheme.sky.opacity(fish.opacity))
                        .scaleEffect(x: fish.flipped ? -1 : 1)
                        .position(x: geo.size.width * fish.x, y: geo.size.height * fish.y)
                }

                ForEach(Array(Self.waves.enumerated()), id: \.offset) { _, wave in
                    Image(systemName: "water.waves")
                        .font(.system(size: 15 * wave.scale, weight: .bold))
                        .foregroundStyle(AppTheme.mint.opacity(wave.opacity))
                        .position(x: geo.size.width * wave.x, y: geo.size.height * wave.y)
                }

                // De schildpad zwemt bovenin, op de vaste blikvangerplek.
                Image(systemName: "tortoise.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.mint.opacity(0.26))
                    .scaleEffect(x: -1)
                    .rotationEffect(.degrees(6))
                    .position(x: geo.size.width * 0.70, y: geo.size.height * 0.095)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

#Preview("Snoep") {
    ThemedBackground()
        .onAppear { ThemeStore.shared.select(.snoep) }
}

#Preview("Oceaan") {
    ThemedBackground()
        .onAppear { ThemeStore.shared.select(.oceaan) }
}

#Preview("Nacht") {
    ThemedBackground()
        .onAppear { ThemeStore.shared.select(.nacht) }
}
