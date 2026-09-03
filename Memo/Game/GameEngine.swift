import Foundation
import Observation

@MainActor
@Observable
final class GameEngine {
    let mode: GameMode
    let boardSize: BoardSize
    private(set) var players: [GamePlayer]
    let startingPlayerIndex: Int
    private(set) var currentPlayerIndex: Int
    private(set) var cards: [MemoryCard]
    /// De kaarten die deze beurt open liggen en nog geen paar zijn (0–2).
    private(set) var faceUpIndices: [Int] = []
    /// Twee verkeerde kaarten liggen nog even te kijk; tikken is dan uit.
    private(set) var isResolving = false
    /// De computer "denkt na": kaarten zijn even niet aantikbaar.
    private(set) var isThinking = false
    private(set) var isFinished = false
    private(set) var isDraw = false
    private(set) var winnerProfileIDs: [UUID] = []
    private(set) var turnMessage: String = ""
    /// Bumps after meaningful state changes so de UI kan autosaven.
    private(set) var saveVersion = 0
    /// True kort nadat de beurt wisselde — UI toont de banner.
    private(set) var turnJustChanged = false
    /// Bumps bij een gevonden paar; de UI hangt er geluid en haptiek aan.
    private(set) var matchPulse = 0
    /// Bumps bij twee verkeerde kaarten.
    private(set) var mismatchPulse = 0
    /// Aantal pogingen (twee kaarten omdraaien) over alle spelers heen.
    private(set) var attempts = 0
    /// Het net gevonden paar, voor een korte highlight in het raster.
    private(set) var lastMatchIndices: [Int] = []

    private var rng: SplitMix64
    /// Het geheugen van de computerspeler; leeft zolang dit potje leeft.
    private let computerAI = ComputerAI()

    var currentPlayer: GamePlayer { players[currentPlayerIndex] }

    /// Het niveau van de computerspeler in dit potje, als die meedoet.
    private var computerLevel: ComputerLevel? {
        players.first(where: \.isComputer)?.computerLevel
    }

    var canFlip: Bool {
        !isFinished && !isResolving && !isThinking && !currentPlayer.isComputer && faceUpIndices.count < 2
    }

    /// Aantal paren dat deze speler al vond.
    func pairCount(of playerIndex: Int) -> Int {
        cards.count(where: { $0.matchedBy == playerIndex }) / 2
    }

    var pairsRemaining: Int {
        cards.count(where: { !$0.isMatched }) / 2
    }

    var snapshot: GameSnapshot {
        GameSnapshot(
            mode: mode,
            boardSize: boardSize,
            players: players,
            startingPlayerIndex: startingPlayerIndex,
            currentPlayerIndex: currentPlayerIndex,
            // Open kaarten gaan dicht de bewaring in: na een hervatting
            // begint de beurt gewoon opnieuw.
            cards: cards.map { GameSnapshot.SavedCard(face: $0.face, matchedBy: $0.matchedBy) },
            attempts: attempts,
            turnMessage: turnMessage,
            savedAt: .now
        )
    }

    init(
        mode: GameMode,
        profiles: [PlayerProfile],
        boardSize: BoardSize = .medium,
        startingPlayerIndex: Int = 0,
        seed: UInt64? = nil
    ) {
        self.mode = mode
        self.boardSize = boardSize
        self.players = profiles.map(GamePlayer.init)
        self.startingPlayerIndex = min(max(startingPlayerIndex, 0), max(profiles.count - 1, 0))
        self.currentPlayerIndex = self.startingPlayerIndex
        var rng = SplitMix64(seed: seed ?? UInt64.random(in: .min ... .max))
        self.cards = BoardSize.deck(for: boardSize, using: &rng)
        self.rng = rng
        self.turnMessage = String(localized: "\(currentPlayer.name) mag beginnen")
    }

    init(snapshot: GameSnapshot, seed: UInt64? = nil) {
        self.mode = snapshot.mode
        self.boardSize = snapshot.boardSize
        self.players = snapshot.players
        self.startingPlayerIndex = min(max(snapshot.startingPlayerIndex, 0), max(snapshot.players.count - 1, 0))
        self.currentPlayerIndex = min(max(snapshot.currentPlayerIndex, 0), max(snapshot.players.count - 1, 0))
        self.cards = snapshot.cards.map { saved in
            var card = MemoryCard(face: saved.face)
            card.matchedBy = saved.matchedBy
            return card
        }
        self.attempts = snapshot.attempts
        self.rng = SplitMix64(seed: seed ?? UInt64.random(in: .min ... .max))
        self.turnMessage = snapshot.turnMessage

        // Een bewaard spel dat toch al uit was, netjes afronden in plaats
        // van laten doorspelen.
        if cards.allSatisfy(\.isMatched) {
            finishGame()
        }
    }

    /// Draait een kaart om voor de speler aan zet. Meldt of er echt iets
    /// gebeurde, zodat de UI geen geluid afvuurt bij een loze tik.
    @discardableResult
    func flip(at index: Int) -> Bool {
        guard canFlip else { return false }
        return reveal(at: index)
    }

    /// Legt twee verkeerde kaarten weer dicht en geeft de beurt door. De UI
    /// (of de computerlus) roept dit aan nadat de speler even mocht kijken.
    func finishMismatch() {
        guard isResolving else { return }
        for index in faceUpIndices {
            cards[index].isFaceUp = false
        }
        faceUpIndices = []
        isResolving = false
        advanceTurn()
        markDirty()
    }

    func acknowledgeTurnChange() {
        turnJustChanged = false
    }

    func playComputerTurnIfNeeded() async {
        // Expliciet annuleerbaar: als het spel dichtgaat stopt de lus, in
        // plaats van in de achtergrond het potje uit te spelen.
        while !Task.isCancelled, !isFinished, currentPlayer.isComputer {
            isThinking = true
            turnMessage = String(localized: "\(currentPlayer.name) denkt na…")
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled, !isFinished, currentPlayer.isComputer else {
                isThinking = false
                return
            }
            let level = currentPlayer.computerLevel ?? .medium
            guard let first = computerAI.chooseFirstCard(cards: cards, using: &rng) else {
                isThinking = false
                return
            }
            reveal(at: first)
            // De eerste kaart even laten zien voor de tweede omgaat.
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled, !isFinished else {
                isThinking = false
                return
            }
            if let second = computerAI.chooseSecondCard(cards: cards, firstIndex: first, level: level, using: &rng) {
                reveal(at: second)
            }
            isThinking = false
            if isResolving {
                // Ook een kind wil zien wát de computer omdraaide.
                try? await Task.sleep(for: .milliseconds(1300))
                guard !Task.isCancelled else { return }
                finishMismatch()
            } else {
                // Raak: even vieren, daarna mag hij nog een keer.
                try? await Task.sleep(for: .milliseconds(900))
            }
        }
    }

    /// De deelnemers van dit spel als profielen, voor een rematch met
    /// dezelfde spelers en hetzelfde computerniveau.
    func rematchProfiles() -> [PlayerProfile] {
        players.map { player in
            PlayerProfile(
                id: player.profileID,
                name: player.name,
                avatarColorIndex: player.avatarColorIndex,
                avatarSymbol: player.avatarSymbol,
                computerLevel: player.computerLevel
            )
        }
    }

    // MARK: - Privé

    /// Draait een kaart om, voor mens én computer, en beoordeelt het paar
    /// zodra er twee open liggen.
    @discardableResult
    private func reveal(at index: Int) -> Bool {
        guard cards.indices.contains(index),
              !cards[index].isFaceUp,
              !cards[index].isMatched,
              faceUpIndices.count < 2 else { return false }

        cards[index].isFaceUp = true
        faceUpIndices.append(index)
        // De computer kijkt met élke open kaart mee, ook die van de mens —
        // precies zoals aan tafel.
        if let computerLevel {
            computerAI.note(index: index, face: cards[index].face, level: computerLevel, using: &rng)
        }

        if faceUpIndices.count == 2 {
            attempts += 1
            evaluatePair()
        }
        markDirty()
        return true
    }

    private func evaluatePair() {
        let first = faceUpIndices[0]
        let second = faceUpIndices[1]
        if cards[first].face == cards[second].face {
            cards[first].matchedBy = currentPlayerIndex
            cards[second].matchedBy = currentPlayerIndex
            lastMatchIndices = [first, second]
            faceUpIndices = []
            computerAI.forget(indices: [first, second])
            matchPulse += 1
            if cards.allSatisfy(\.isMatched) {
                finishGame()
            } else {
                turnMessage = String(localized: "Een paar! \(currentPlayer.name) mag nog een keer")
            }
        } else {
            isResolving = true
            mismatchPulse += 1
            turnMessage = String(localized: "Helaas, geen paar…")
        }
    }

    private func advanceTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        turnMessage = String(localized: "\(currentPlayer.name) is aan de beurt")
        turnJustChanged = true
    }

    private func finishGame() {
        isFinished = true
        let counts = players.indices.map(pairCount(of:))
        let best = counts.max() ?? 0
        let winners = players.indices.filter { counts[$0] == best }
        if winners.count == 1, let winnerIndex = winners.first {
            let winner = players[winnerIndex]
            winnerProfileIDs = [winner.profileID]
            isDraw = false
            turnMessage = String(localized: "\(winner.name) wint met \(best) paren!")
        } else {
            winnerProfileIDs = []
            isDraw = true
            turnMessage = String(localized: "Gelijkspel — evenveel paren!")
        }
    }

    private func markDirty() {
        saveVersion += 1
    }
}
