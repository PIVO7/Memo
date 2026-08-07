import XCTest
@testable import Memo

/// De statistiekmodellen achter de trofeeënkast en de gezinsrecords.
@MainActor
final class StatsModelTests: XCTestCase {
    private func profile(
        name: String,
        wins: Int = 0,
        games: Int = 0,
        draws: Int = 0,
        bestStreak: Int = 0,
        mostPairs: Int = 0
    ) -> PlayerProfile {
        PlayerProfile(
            name: name,
            wins: wins,
            gamesPlayed: games,
            draws: draws,
            currentStreak: 0,
            bestStreak: bestStreak,
            mostPairs: mostPairs
        )
    }

    // MARK: - Trofeeën

    func testFreshProfileEarnsNothing() {
        let badges = ProfileBadge.collection(for: profile(name: "Lene"))
        XCTAssertFalse(badges.isEmpty)
        XCTAssertTrue(badges.allSatisfy { !$0.isEarned })
    }

    func testBadgeThresholds() {
        let speler = profile(name: "Lene", wins: 5, games: 10, draws: 1, bestStreak: 3, mostPairs: 5)
        let earned = Set(ProfileBadge.collection(for: speler).filter(\.isEarned).map(\.id))
        XCTAssertTrue(earned.isSuperset(of: [
            "eerste-potje", "winnaar", "even-sterk", "hattrick",
            "parenjager", "speelvogel", "winmachine"
        ]))
        // Nét niet gehaald: 8 paren, 5 op rij, 10 winsten, 25 en 50 potjes.
        XCTAssertTrue(earned.isDisjoint(with: [
            "geheugenkanjer", "onverslaanbaar", "sterspeler", "kampioen", "memolegende"
        ]))
    }

    // MARK: - Gezinsrecords

    func testHighestValueWinsAndTiesShareTheRecord() {
        let lene = profile(name: "Lene", wins: 4, games: 6)
        let ellis = profile(name: "Ellis", wins: 4, games: 5)
        let noah = profile(name: "Noah", wins: 2, games: 4)

        let record = FamilyRecordMath.record(in: [lene, ellis, noah], value: { $0.wins })
        XCTAssertEqual(record?.value, 4)
        XCTAssertEqual(record?.holders.map(\.name), ["Lene", "Ellis"])
    }

    func testProfilesWithoutGamesDoNotCompete() {
        let spook = profile(name: "Spook", wins: 99, games: 0)
        let lene = profile(name: "Lene", wins: 1, games: 1)

        let record = FamilyRecordMath.record(in: [spook, lene], value: { $0.wins })
        XCTAssertEqual(record?.holders.map(\.name), ["Lene"])
        XCTAssertEqual(record?.value, 1)
    }

    func testZeroIsNoRecord() {
        let lene = profile(name: "Lene", games: 2)
        XCTAssertNil(FamilyRecordMath.record(in: [lene], value: { $0.wins }))
    }

    func testBestHaulRecord() {
        let lene = profile(name: "Lene", wins: 1, games: 3, mostPairs: 6)
        let ellis = profile(name: "Ellis", games: 3, mostPairs: 8)

        let record = FamilyRecordMath.record(in: [lene, ellis], value: { $0.mostPairs })
        XCTAssertEqual(record?.value, 8)
        XCTAssertEqual(record?.holders.map(\.name), ["Ellis"])
    }
}
