import SwiftUI

/// Het speelveld: alle kaartjes in een raster op een blauw tafelblad. De
/// maat van de kaartjes volgt uit de beschikbare ruimte, zodat ook het
/// grote bord zonder scrollen past.
struct CardGridView: View {
    let cards: [MemoryCard]
    let columns: Int
    /// Naam van de vinder, voor VoiceOver op gevonden paren.
    let playerName: (Int) -> String
    let isEnabled: Bool
    let onFlip: (Int) -> Void

    @Environment(\.metrics) private var m

    private var rows: Int {
        columns > 0 ? Int(ceil(Double(cards.count) / Double(columns))) : 0
    }

    var body: some View {
        GeometryReader { proxy in
            let gap = m.boardGap
            let padding = m.boardPadding
            let width = (proxy.size.width - padding * 2 - gap * CGFloat(columns - 1)) / CGFloat(columns)
            let height = (proxy.size.height - padding * 2 - gap * CGFloat(max(rows, 1) - 1)) / CGFloat(max(rows, 1))
            let side = max(min(width, height), 10)
            let gridWidth = side * CGFloat(columns) + gap * CGFloat(columns - 1) + padding * 2

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(side), spacing: gap), count: columns),
                spacing: gap
            ) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    cardButton(index: index, card: card, side: side)
                }
            }
            .padding(padding)
            .toyBlock(fill: AppTheme.sky, radius: m.cardCorner, depth: m.depth + 1, border: m.border)
            .frame(width: gridWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func cardButton(index: Int, card: MemoryCard, side: CGFloat) -> some View {
        Button {
            onFlip(index)
        } label: {
            MemoryCardView(card: card, size: side)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || card.isFaceUp || card.isMatched)
        .accessibilityLabel(accessibilityLabel(for: card, number: index + 1))
        // Geen hint op kaarten die toch niet reageren; dat scheelt VoiceOver
        // een hoop geruis.
        .accessibilityHint(
            isEnabled && !card.isFaceUp && !card.isMatched
                ? Text("Draai om")
                : Text(verbatim: "")
        )
    }

    private func accessibilityLabel(for card: MemoryCard, number: Int) -> String {
        if let finder = card.matchedBy {
            return String(localized: "\(card.face.label), paar van \(playerName(finder))")
        }
        if card.isFaceUp {
            return String(localized: "Kaart \(number), open: \(card.face.label)")
        }
        return String(localized: "Kaart \(number), dicht")
    }
}

#Preview {
    var rng = SplitMix64(seed: 7)
    var cards = BoardSize.deck(for: .medium, using: &rng)
    let _ = cards[3].isFaceUp = true
    let _ = { cards[5].matchedBy = 0; cards[9].matchedBy = 0 }()

    return CardGridView(
        cards: cards,
        columns: BoardSize.medium.columns,
        playerName: { _ in "Lene" },
        isEnabled: true,
        onFlip: { _ in }
    )
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
