import Foundation

/// Serialiseerbare snapshot van een lopend spel, zodat kids kunnen hervatten.
/// Open kaarten worden dicht bewaard: na een hervatting begint de beurt
/// gewoon opnieuw, dat is eerlijker dan half omgedraaide kaarten.
struct GameSnapshot: Codable, Equatable {
    struct SavedCard: Codable, Equatable {
        var face: CardFace
        var matchedBy: Int?
    }

    var mode: GameMode
    var boardSize: BoardSize
    var players: [GamePlayer]
    var startingPlayerIndex: Int
    var currentPlayerIndex: Int
    var cards: [SavedCard]
    var attempts: Int
    var turnMessage: String
    var savedAt: Date

    /// Alleen een geldig, nog niet afgelopen spel is het hervatten waard.
    var isResumable: Bool {
        guard players.count == 2,
              (0..<players.count).contains(startingPlayerIndex),
              (0..<players.count).contains(currentPlayerIndex),
              cards.count >= 8, cards.count.isMultiple(of: 2),
              cards.contains(where: { $0.matchedBy == nil }) else {
            return false
        }
        // Elke voorkant hoort precies twee keer voor te komen, en gevonden
        // kaarten horen bij een echte speler.
        let faceCounts = Dictionary(grouping: cards, by: \.face).mapValues(\.count)
        guard faceCounts.values.allSatisfy({ $0 == 2 }) else { return false }
        return cards.allSatisfy { card in
            card.matchedBy.map { (0..<players.count).contains($0) } ?? true
        }
    }

    var summaryTitle: String {
        let names = players.filter { !$0.isComputer }.map(\.name)
        switch mode {
        case .versusComputer:
            return names.first.map { String(localized: "\($0) vs Computer") } ?? mode.title
        case .versusFriends:
            return names.joined(separator: " · ")
        }
    }
}
