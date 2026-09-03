import SwiftUI

/// Het anker van het startscherm: twee grote kaartjes boven de titel.
/// Tikken draait ze om en laat ze wiebelen — puur voor de fun.
struct HomeHeroView: View {
    @Environment(\.metrics) private var m
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var flipped = false
    @State private var wiggle = 0

    var body: some View {
        Button(action: tumble) {
            HStack(spacing: -m.discSize * 0.18) {
                heroCard(face: CardFace.catalog[8], tilt: -9)
                    .zIndex(1)
                heroCard(face: CardFace.catalog[9], tilt: 8)
                    .offset(y: m.discSize * 0.16)
            }
            .rotationEffect(.degrees(wiggle.isMultiple(of: 2) ? 0 : 3))
            .animation(.spring(response: 0.3, dampingFraction: 0.35), value: wiggle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Twee memokaartjes")
        .accessibilityHint("Tik om ze om te draaien")
    }

    private func heroCard(face: CardFace, tilt: Double) -> some View {
        var card = MemoryCard(face: face)
        card.isFaceUp = flipped
        // Losstaande kaartjes op de hero krijgen dikte, net als de andere
        // losse toy blocks.
        return MemoryCardView(card: card, size: m.discSize * 1.15, depth: m.shallowDepth)
            .rotationEffect(.degrees(tilt))
    }

    private func tumble() {
        flipped.toggle()
        if !reduceMotion {
            wiggle += 1
        }
        SoundPlayer.shared.play(.drop)
    }
}

#Preview {
    HomeHeroView()
        .padding(40)
        .background(AppTheme.cream)
        .appMetrics()
}
