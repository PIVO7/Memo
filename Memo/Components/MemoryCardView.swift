import SwiftUI

/// Eén kaartje in de speelgoedstijl: dichte kant met een vraagteken op
/// koraal, open kant met een groot vormpje. Het omdraaien is een echte
/// 3D-flip; bij Verminder beweging kruist hij zonder draai.
struct MemoryCardView: View {
    let card: MemoryCard
    /// De zijde van het (vierkante) kaartje. Expliciet meegegeven — het
    /// raster kent zijn maat toch al, en zo staat er geen GeometryReader
    /// per kaart.
    var size: CGFloat
    /// Losstaande kaartjes (de hero op het startscherm) krijgen dikte;
    /// kaartjes in het raster of óp een gekleurd blok blijven plat — de
    /// dichte kant tekent daar zijn eigen dikte al.
    var depth: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var showsFace: Bool { card.isFaceUp || card.isMatched }
    private var corner: CGFloat { size * 0.18 }

    var body: some View {
        ZStack {
            front
                .opacity(showsFace ? 1 : 0)
                .rotation3DEffect(.degrees(showsFace || reduceMotion ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            back
                .opacity(showsFace ? 0 : 1)
                .rotation3DEffect(.degrees(!showsFace || reduceMotion ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .background {
            if depth > 0 {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(AppTheme.ink)
                    .offset(y: depth)
            }
        }
        // Gevonden paren blijven zichtbaar maar treden terug, zodat je in
        // één oogopslag ziet wat nog meedoet.
        .opacity(card.isMatched ? 0.45 : 1)
        .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.4, dampingFraction: 0.75), value: showsFace)
        .animation(.easeOut(duration: 0.3), value: card.isMatched)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var front: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(AppTheme.card)
            Image(systemName: card.face.symbol)
                .font(.system(size: size * 0.44, weight: .black))
                .foregroundStyle(AvatarBadge.palette[card.face.colorIndex % AvatarBadge.palette.count])
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(AppTheme.ink, lineWidth: max(size * 0.045, 1.5))
        }
    }

    private var back: some View {
        ZStack {
            if !card.isMatched {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(AppTheme.ink)
                    .offset(y: max(size * 0.045, 2))
            }
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(AppTheme.coral)
            Image(systemName: "questionmark")
                .font(.system(size: size * 0.4, weight: .black))
                .foregroundStyle(AppTheme.ink.opacity(0.5))
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(AppTheme.ink, lineWidth: max(size * 0.045, 1.5))
        }
    }
}

#Preview {
    var open = MemoryCard(face: CardFace.catalog[1])
    let _ = open.isFaceUp = true
    var matched = MemoryCard(face: CardFace.catalog[8])
    let _ = matched.matchedBy = 0

    return HStack(spacing: 16) {
        MemoryCardView(card: MemoryCard(face: CardFace.catalog[0]), size: 80)
        MemoryCardView(card: open, size: 80)
        MemoryCardView(card: matched, size: 80)
    }
    .padding()
    .background(AppTheme.cream)
}
