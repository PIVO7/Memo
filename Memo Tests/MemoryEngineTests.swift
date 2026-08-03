import XCTest
@testable import Memo

@MainActor
final class MemoryEngineTests: XCTestCase {
    private func makeEngine(boardSize: BoardSize = .small, seed: UInt64 = 7) -> GameEngine {
        GameEngine(
            mode: .versusFriends,
            profiles: [
                PlayerProfile(name: "Lene"),
                PlayerProfile(name: "Ellis", avatarColorIndex: 1)
            ],
            boardSize: boardSize,
            seed: seed
        )
    }

    /// Indexen van het eerste paar dichte kaarten met dezelfde voorkant.
    private func pairIndices(in engine: GameEngine) -> (Int, Int) {
        let cards = engine.cards
        for first in cards.indices where !cards[first].isMatched && !cards[first].isFaceUp {
            for second in cards.indices
            where second != first && !cards[second].isMatched && !cards[second].isFaceUp
                && cards[second].face == cards[first].face {
                return (first, second)
            }
        }
        XCTFail("Geen dicht paar meer over")
        return (0, 0)
    }

    /// Twee dichte kaarten met verschíllende voorkanten.
    private func mismatchIndices(in engine: GameEngine) -> (Int, Int) {
        let cards = engine.cards
        for first in cards.indices where !cards[first].isMatched && !cards[first].isFaceUp {
            for second in cards.indices
            where second != first && !cards[second].isMatched && !cards[second].isFaceUp
                && cards[second].face != cards[first].face {
                return (first, second)
            }
        }
        XCTFail("Geen misser meer te vinden")
        return (0, 0)
    }

    func testDeckHasEveryFaceExactlyTwice() {
        let engine = makeEngine(boardSize: .large)
        XCTAssertEqual(engine.cards.count, BoardSize.large.pairCount * 2)
        let counts = Dictionary(grouping: engine.cards, by: \.face).mapValues(\.count)
        XCTAssertTrue(counts.values.allSatisfy { $0 == 2 })
    }

    func testMatchKeepsTheTurn() {
        let engine = makeEngine()
        let (first, second) = pairIndices(in: engine)

        XCTAssertTrue(engine.flip(at: first))
        XCTAssertTrue(engine.flip(at: second))

        XCTAssertEqual(engine.currentPlayerIndex, 0)
        XCTAssertEqual(engine.pairCount(of: 0), 1)
        XCTAssertFalse(engine.isResolving)
        XCTAssertEqual(engine.matchPulse, 1)
        XCTAssertEqual(engine.attempts, 1)
    }

    func testMismatchFlipsBackAndPassesTheTurn() {
        let engine = makeEngine()
        let (first, second) = mismatchIndices(in: engine)

        engine.flip(at: first)
        engine.flip(at: second)
        XCTAssertTrue(engine.isResolving)
        // Zolang de misser open ligt, valt er niets te tikken.
        XCTAssertFalse(engine.canFlip)

        engine.finishMismatch()
        XCTAssertFalse(engine.cards[first].isFaceUp)
        XCTAssertFalse(engine.cards[second].isFaceUp)
        XCTAssertEqual(engine.currentPlayerIndex, 1)
        XCTAssertTrue(engine.turnJustChanged)
    }

    func testOpenOrMatchedCardsCannotFlipAgain() {
        let engine = makeEngine()
        let (first, second) = pairIndices(in: engine)

        engine.flip(at: first)
        XCTAssertFalse(engine.flip(at: first))
        engine.flip(at: second)
        // Het paar is binnen; nogmaals tikken doet niets.
        XCTAssertFalse(engine.flip(at: first))
    }

    func testFindingEveryPairFinishesTheGame() {
        let engine = makeEngine()
        // Speler 0 raapt alles op: een match geeft immers een nieuwe beurt.
        while !engine.isFinished {
            let (first, second) = pairIndices(in: engine)
            engine.flip(at: first)
            engine.flip(at: second)
        }
        XCTAssertEqual(engine.pairCount(of: 0), BoardSize.small.pairCount)
        XCTAssertEqual(engine.winnerProfileIDs, [engine.players[0].profileID])
        XCTAssertFalse(engine.isDraw)
        XCTAssertEqual(engine.pairsRemaining, 0)
    }

    func testSnapshotRoundtripKeepsScoreAndTurn() {
        let engine = makeEngine()
        let (first, second) = pairIndices(in: engine)
        engine.flip(at: first)
        engine.flip(at: second)
        let (a, b) = mismatchIndices(in: engine)
        engine.flip(at: a)
        engine.flip(at: b)
        engine.finishMismatch()

        let restored = GameEngine(snapshot: engine.snapshot, seed: 99)
        XCTAssertEqual(restored.pairCount(of: 0), 1)
        XCTAssertEqual(restored.currentPlayerIndex, 1)
        XCTAssertEqual(restored.attempts, 2)
        // Open kaarten gaan dicht de bewaring in.
        XCTAssertTrue(restored.cards.allSatisfy { !$0.isFaceUp || $0.isMatched })
        XCTAssertFalse(restored.isFinished)
    }

    func testFinishedSnapshotIsNotResumable() {
        let engine = makeEngine()
        while !engine.isFinished {
            let (first, second) = pairIndices(in: engine)
            engine.flip(at: first)
            engine.flip(at: second)
        }
        XCTAssertFalse(engine.snapshot.isResumable)
        // En wie hem toch laadt, krijgt meteen de eindstand.
        XCTAssertTrue(GameEngine(snapshot: engine.snapshot).isFinished)
    }

    func testCorruptSnapshotIsNotResumable() {
        var snapshot = makeEngine().snapshot
        // Drie keer dezelfde voorkant kan nooit een eerlijk spel zijn.
        snapshot.cards[0] = snapshot.cards[1]
        XCTAssertFalse(snapshot.isResumable)
    }
}
