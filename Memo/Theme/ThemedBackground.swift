import SwiftUI

/// De schermachtergrond: het effen themavlak, en in het nachtthema een
/// handvol sterren erbovenop — anders is "Nacht" gewoon donker in plaats
/// van nacht.
struct ThemedBackground: View {
    var body: some View {
        ZStack {
            AppTheme.cream
            if ThemeStore.shared.themeID == .nacht {
                NightSkyView()
            }
        }
        .ignoresSafeArea()
    }
}

/// Een rustige sterrenhemel op vaste plekken: geen willekeur, zodat er bij
/// elke hertekening niets verspringt of flikkert.
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

#Preview {
    ThemedBackground()
}
