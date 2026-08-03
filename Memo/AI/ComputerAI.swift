import Foundation

/// De computerspeler met een menselijk geheugen: hij kijkt mee met elke
/// kaart die opengaat en onthoudt hem met een kans die bij zijn persona
/// past. Dommel vergeet bijna alles, Professor Punt niets — zo voelt elk
/// niveau eerlijk in plaats van "de computer gluurt onder de kaartjes".
@MainActor
final class ComputerAI {
    /// Kaartindex → voorkant, opgebouwd uit wat er open heeft gelegen.
    private var memory: [Int: CardFace] = [:]

    /// Registreert een open kaart, met de vergeetachtigheid van het niveau.
    func note(index: Int, face: CardFace, level: ComputerLevel, using rng: inout SplitMix64) {
        if memory[index] != nil {
            memory[index] = face
            return
        }
        guard Double.random(in: 0..<1, using: &rng) < level.memoryChance else { return }
        memory[index] = face
        // Een vol hoofd: boven de capaciteit valt er willekeurig iets uit.
        while memory.count > level.memoryCapacity {
            guard let victim = memory.keys.randomElement(using: &rng) else { break }
            memory.removeValue(forKey: victim)
        }
    }

    /// Gevonden paren hoeven geen geheugen meer te kosten.
    func forget(indices: [Int]) {
        for index in indices {
            memory.removeValue(forKey: index)
        }
    }

    /// De eerste kaart van de beurt: een bekend paar als dat er is, anders
    /// liefst een kaart die hij nog niet kent — daar valt wat te leren.
    func chooseFirstCard(cards: [MemoryCard], using rng: inout SplitMix64) -> Int? {
        prune(cards: cards)
        if let pair = knownPair(cards: cards) {
            return pair.0
        }
        let hidden = hiddenIndices(cards: cards)
        let unknown = hidden.filter { memory[$0] == nil }
        return (unknown.isEmpty ? hidden : unknown).randomElement(using: &rng)
    }

    /// De tweede kaart: de match uit het geheugen als hij die kent, anders
    /// weer een onbekende kaart. Een bekende níet-passende kaart omdraaien
    /// zou zonde van de beurt zijn.
    func chooseSecondCard(cards: [MemoryCard], firstIndex: Int, level: ComputerLevel, using rng: inout SplitMix64) -> Int? {
        prune(cards: cards)
        guard cards.indices.contains(firstIndex) else { return nil }
        let face = cards[firstIndex].face
        // Herinnert hij zich de wederhelft? Ook dat herinneren mag mislukken
        // op de lagere niveaus.
        if let match = memory
            .filter({ $0.key != firstIndex && $0.value == face && isPlayable(cards: cards, index: $0.key) })
            .keys.sorted().first,
           Double.random(in: 0..<1, using: &rng) < level.recallChance {
            return match
        }
        let hidden = hiddenIndices(cards: cards).filter { $0 != firstIndex }
        let unknown = hidden.filter { memory[$0] == nil }
        return (unknown.isEmpty ? hidden : unknown).randomElement(using: &rng)
    }

    // MARK: - Privé

    /// Twee verschillende dichte kaarten waarvan hij weet dat ze een paar
    /// vormen.
    private func knownPair(cards: [MemoryCard]) -> (Int, Int)? {
        var seen: [CardFace: Int] = [:]
        for (index, face) in memory.sorted(by: { $0.key < $1.key }) {
            guard isPlayable(cards: cards, index: index) else { continue }
            if let partner = seen[face] {
                return (partner, index)
            }
            seen[face] = index
        }
        return nil
    }

    private func hiddenIndices(cards: [MemoryCard]) -> [Int] {
        cards.indices.filter { isPlayable(cards: cards, index: $0) }
    }

    private func isPlayable(cards: [MemoryCard], index: Int) -> Bool {
        cards.indices.contains(index) && !cards[index].isMatched && !cards[index].isFaceUp
    }

    /// Gooit herinneringen weg aan kaarten die inmiddels van tafel zijn.
    private func prune(cards: [MemoryCard]) {
        memory = memory.filter { index, _ in
            cards.indices.contains(index) && !cards[index].isMatched
        }
    }
}

extension ComputerLevel {
    /// Kans dat een gezien kaartje het geheugen haalt.
    var memoryChance: Double {
        switch self {
        case .easy: return 0.3
        case .medium: return 0.65
        case .hard: return 1.0
        }
    }

    /// Kans dat een onthouden wederhelft ook echt boven komt.
    var recallChance: Double {
        switch self {
        case .easy: return 0.5
        case .medium: return 0.8
        case .hard: return 1.0
        }
    }

    /// Hoeveel kaartjes er tegelijk in het hoofd passen.
    var memoryCapacity: Int {
        switch self {
        case .easy: return 4
        case .medium: return 12
        case .hard: return .max
        }
    }
}
