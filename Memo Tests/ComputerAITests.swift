import XCTest
@testable import Memo

@MainActor
final class ComputerAITests: XCTestCase {
    private func makeCards() -> [MemoryCard] {
        var rng = SplitMix64(seed: 3)
        return BoardSize.deck(for: .small, using: &rng)
    }

    private func partner(of index: Int, in cards: [MemoryCard]) -> Int {
        cards.indices.first { $0 != index && cards[$0].face == cards[index].face }!
    }

    func testProfessorRemembersASeenPair() {
        let cards = makeCards()
        let ai = ComputerAI()
        var rng = SplitMix64(seed: 1)
        let first = 0
        let second = partner(of: first, in: cards)

        // De professor zag beide helften voorbijkomen.
        ai.note(index: first, face: cards[first].face, level: .hard, using: &rng)
        ai.note(index: second, face: cards[second].face, level: .hard, using: &rng)

        let choice = ai.chooseFirstCard(cards: cards, using: &rng)
        XCTAssertTrue(choice == first || choice == second)
        let follow = ai.chooseSecondCard(cards: cards, firstIndex: choice!, level: .hard, using: &rng)
        XCTAssertEqual(follow, choice == first ? second : first)
    }

    func testProfessorFindsTheMatchOfAnOpenCard() {
        var cards = makeCards()
        let ai = ComputerAI()
        var rng = SplitMix64(seed: 2)
        let first = 4
        let second = partner(of: first, in: cards)

        ai.note(index: second, face: cards[second].face, level: .hard, using: &rng)
        cards[first].isFaceUp = true

        XCTAssertEqual(
            ai.chooseSecondCard(cards: cards, firstIndex: first, level: .hard, using: &rng),
            second
        )
    }

    func testMatchedCardsLeaveTheMemory() {
        var cards = makeCards()
        let ai = ComputerAI()
        var rng = SplitMix64(seed: 5)
        let first = 0
        let second = partner(of: first, in: cards)

        ai.note(index: first, face: cards[first].face, level: .hard, using: &rng)
        ai.note(index: second, face: cards[second].face, level: .hard, using: &rng)
        cards[first].matchedBy = 0
        cards[second].matchedBy = 0

        // Het gevonden paar mag nooit meer gekozen worden.
        for _ in 0..<20 {
            if let choice = ai.chooseFirstCard(cards: cards, using: &rng) {
                XCTAssertNotEqual(choice, first)
                XCTAssertNotEqual(choice, second)
            }
        }
    }

    func testChoicesAlwaysLandOnPlayableCards() {
        var cards = makeCards()
        let ai = ComputerAI()
        var rng = SplitMix64(seed: 8)
        // Een halfleeg bord met een open kaart erbij.
        cards[0].matchedBy = 0
        cards[partner(of: 0, in: cards)].matchedBy = 0
        cards[5].isFaceUp = true

        for seed in 0..<25 {
            var rolls = SplitMix64(seed: UInt64(seed))
            if let first = ai.chooseFirstCard(cards: cards, using: &rolls) {
                XCTAssertFalse(cards[first].isMatched)
                XCTAssertFalse(cards[first].isFaceUp)
                if let second = ai.chooseSecondCard(cards: cards, firstIndex: first, level: .easy, using: &rolls) {
                    XCTAssertNotEqual(second, first)
                    XCTAssertFalse(cards[second].isMatched)
                }
            }
        }
        _ = rng
    }

    func testFullSoloGameAgainstTheProfessorEndsCleanly() {
        // Integratie zonder wachttijden: we spelen de computerbeurt met de
        // hand na — kies, onthul via de engine-snapshotweg is hier niet
        // nodig; de AI-keuzes moeten op elk bord tot een einde leiden.
        var cards = makeCards()
        let ai = ComputerAI()
        var rng = SplitMix64(seed: 11)
        var safety = 200

        while cards.contains(where: { !$0.isMatched }), safety > 0 {
            safety -= 1
            guard let first = ai.chooseFirstCard(cards: cards, using: &rng) else { break }
            cards[first].isFaceUp = true
            ai.note(index: first, face: cards[first].face, level: .hard, using: &rng)
            guard let second = ai.chooseSecondCard(cards: cards, firstIndex: first, level: .hard, using: &rng) else { break }
            cards[second].isFaceUp = true
            ai.note(index: second, face: cards[second].face, level: .hard, using: &rng)

            if cards[first].face == cards[second].face {
                cards[first].matchedBy = 0
                cards[second].matchedBy = 0
                ai.forget(indices: [first, second])
            } else {
                cards[first].isFaceUp = false
                cards[second].isFaceUp = false
            }
        }

        XCTAssertTrue(cards.allSatisfy(\.isMatched), "De professor moet elk bord leeg krijgen")
        XCTAssertGreaterThan(safety, 0)
    }
}
