import XCTest
@testable import Memo

/// Tegen de klok: solo, een stopwatch die bij de eerste tik start, en een
/// snelste tijd per bord in plaats van winst of verlies.
@MainActor
final class TimeTrialTests: XCTestCase {
    private func makeEngine(boardSize: BoardSize = .small, seed: UInt64 = 7) -> GameEngine {
        GameEngine(
            mode: .timeTrial,
            profiles: [PlayerProfile(name: "Lene")],
            boardSize: boardSize,
            seed: seed
        )
    }

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

    func testClockStartsAtTheFirstFlip() {
        let engine = makeEngine()
        XCTAssertFalse(engine.isClockRunning)
        XCTAssertEqual(engine.elapsedSeconds, 0)

        engine.flip(at: 0)
        XCTAssertTrue(engine.isClockRunning)
    }

    /// Solo is er niemand om aan door te geven: een misser gaat dicht en
    /// dezelfde speler probeert opnieuw, zonder beurtwissel.
    func testMismatchKeepsTheSoloPlayer() {
        let engine = makeEngine()
        let (first, second) = mismatchIndices(in: engine)

        engine.flip(at: first)
        engine.flip(at: second)
        XCTAssertTrue(engine.isResolving)
        engine.finishMismatch()

        XCTAssertEqual(engine.currentPlayerIndex, 0)
        XCTAssertFalse(engine.turnJustChanged)
        XCTAssertTrue(engine.canFlip)
        XCTAssertTrue(engine.isClockRunning)
    }

    func testFinishingFreezesTheClockAndCrownsThePlayer() {
        let engine = makeEngine()
        while !engine.isFinished {
            let (first, second) = pairIndices(in: engine)
            engine.flip(at: first)
            engine.flip(at: second)
        }

        XCTAssertFalse(engine.isClockRunning)
        XCTAssertEqual(engine.winnerProfileIDs, [engine.players[0].profileID])
        XCTAssertFalse(engine.isDraw)
        XCTAssertEqual(engine.pairCount(of: 0), BoardSize.small.pairCount)
        // Eenmaal klaar staat de tijd stil.
        let frozen = engine.elapsedSeconds
        XCTAssertEqual(engine.elapsedSeconds, frozen)
    }

    func testSoloSnapshotIsResumableAndPausesTheClock() throws {
        let engine = makeEngine()
        let (first, second) = pairIndices(in: engine)
        engine.flip(at: first)
        engine.flip(at: second)

        let snapshot = engine.snapshot
        XCTAssertTrue(snapshot.isResumable)
        XCTAssertNotNil(snapshot.elapsedSeconds)
        XCTAssertTrue(snapshot.summaryTitle.contains(GameMode.timeTrial.title))

        let data = try JSONEncoder().encode(snapshot)
        let restored = GameEngine(snapshot: try JSONDecoder().decode(GameSnapshot.self, from: data))
        XCTAssertEqual(restored.mode, .timeTrial)
        XCTAssertEqual(restored.pairCount(of: 0), 1)
        // De klok wacht op de eerste tik na het hervatten.
        XCTAssertFalse(restored.isClockRunning)
        XCTAssertEqual(restored.elapsedSeconds, snapshot.elapsedSeconds)
    }

    /// Eén speler is alleen solo een geldig spel.
    func testTwoPlayerModesStillNeedTwoPlayers() {
        var snapshot = makeEngine().snapshot
        snapshot.mode = .versusFriends
        XCTAssertFalse(snapshot.isResumable)
    }

    func testTimeTrialRecordKeepsTheFastestTimePerBoard() {
        let store = ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "tt-\(UUID()).json"))
        store.addProfile(name: "Lene")
        let id = store.humanProfiles[0].id

        // Een eerste tijd is nog geen record.
        XCTAssertFalse(store.recordTimeTrial(profileID: id, boardSize: .small, seconds: 60))
        XCTAssertEqual(store.humanProfiles[0].bestTime(for: .small), 60)
        XCTAssertEqual(store.humanProfiles[0].gamesPlayed, 1)

        XCTAssertTrue(store.recordTimeTrial(profileID: id, boardSize: .small, seconds: 45))
        XCTAssertFalse(store.recordTimeTrial(profileID: id, boardSize: .small, seconds: 50))
        XCTAssertEqual(store.humanProfiles[0].bestTime(for: .small), 45)
        // Een ander bord is een aparte lijst.
        XCTAssertNil(store.humanProfiles[0].bestTime(for: .large))

        // Winst, reeks en grafiekje blijven ongemoeid.
        XCTAssertEqual(store.humanProfiles[0].wins, 0)
        XCTAssertEqual(store.humanProfiles[0].bestStreak, 0)
        XCTAssertTrue(store.humanProfiles[0].history.isEmpty)
        XCTAssertEqual(store.humanProfiles[0].gamesPlayed, 3)
    }

    func testGuestTimeIsNotRecorded() {
        let store = ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "tt-\(UUID()).json"))
        XCTAssertFalse(store.recordTimeTrial(profileID: UUID(), boardSize: .small, seconds: 30))
        XCTAssertTrue(store.humanProfiles.isEmpty)
    }

    /// Oudere profielbestanden kennen geen tijden en laden gewoon.
    func testProfileWithoutBestTimesDecodes() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Ellis","wins":2,"gamesPlayed":3,"avatarColorIndex":1,"createdAt":0}
        """
        let profile = try JSONDecoder().decode(PlayerProfile.self, from: Data(json.utf8))
        XCTAssertTrue(profile.bestTimes.isEmpty)
        XCTAssertNil(profile.bestTime(for: .medium))
    }

    func testClockTextFormatsMinutesAndSeconds() {
        XCTAssertEqual(ClockText.string(seconds: 0), "0:00")
        XCTAssertEqual(ClockText.string(seconds: 7), "0:07")
        XCTAssertEqual(ClockText.string(seconds: 83), "1:23")
        XCTAssertEqual(ClockText.string(seconds: -4), "0:00")
    }
}
