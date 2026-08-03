import XCTest
@testable import Memo

@MainActor
final class GameStoreTests: XCTestCase {
    private var fileURL: URL!

    override func setUp() {
        super.setUp()
        fileURL = URL.temporaryDirectory.appending(path: "game-test-\(UUID()).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        super.tearDown()
    }

    private func makeEngine(seed: UInt64 = 7) -> GameEngine {
        GameEngine(
            mode: .versusFriends,
            profiles: [
                PlayerProfile(name: "Lene"),
                PlayerProfile(name: "Ellis", avatarColorIndex: 1)
            ],
            boardSize: .small,
            seed: seed
        )
    }

    /// Laat de speler aan zet één nog liggend paar vinden, zodat elke
    /// aanroep de stand echt verandert.
    private func findOnePair(in engine: GameEngine) {
        let cards = engine.cards
        for first in cards.indices where !cards[first].isMatched {
            for second in cards.indices
            where second != first && !cards[second].isMatched && cards[second].face == cards[first].face {
                engine.flip(at: first)
                engine.flip(at: second)
                return
            }
        }
    }

    func testSaveAndReload() async {
        let engine = makeEngine()
        findOnePair(in: engine)
        let store = GameStore(fileURL: fileURL)
        store.save(engine.snapshot)
        await store.flush()

        let reloaded = GameStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.savedGame?.attempts, 1)
        XCTAssertEqual(reloaded.savedGame?.summaryTitle, "Lene · Ellis")
        XCTAssertEqual(reloaded.savedGame?.cards.count(where: { $0.matchedBy != nil }), 2)
    }

    func testClearRemovesFile() async {
        let store = GameStore(fileURL: fileURL)
        store.save(makeEngine().snapshot)
        await store.flush()
        store.clear()
        await store.flush()

        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertNil(GameStore(fileURL: fileURL).savedGame)
    }

    func testFinishedGameIsNotResumed() async {
        let engine = makeEngine()
        while !engine.isFinished {
            findOnePair(in: engine)
        }
        let store = GameStore(fileURL: fileURL)
        store.save(engine.snapshot)
        await store.flush()

        XCTAssertNil(GameStore(fileURL: fileURL).savedGame)
    }

    func testCorruptDeckIsNotResumed() async {
        var snapshot = makeEngine().snapshot
        // Drie keer dezelfde voorkant: dat spel klopt niet meer.
        snapshot.cards[0] = snapshot.cards[1]
        let store = GameStore(fileURL: fileURL)
        store.save(snapshot)
        await store.flush()

        XCTAssertNil(GameStore(fileURL: fileURL).savedGame)
    }

    func testLatestWriteWins() async {
        let engine = makeEngine()
        let store = GameStore(fileURL: fileURL)
        store.save(engine.snapshot)
        findOnePair(in: engine)
        store.save(engine.snapshot)
        findOnePair(in: engine)
        store.save(engine.snapshot)
        await store.flush()

        XCTAssertEqual(GameStore(fileURL: fileURL).savedGame?.attempts, 2)
    }
}
