import XCTest
@testable import Memo

@MainActor
final class ProfileStoreTests: XCTestCase {
    private var fileURL: URL!

    override func setUp() {
        super.setUp()
        fileURL = URL.temporaryDirectory.appending(path: "profiles-test-\(UUID()).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        super.tearDown()
    }

    func testAddAndPersistProfile() {
        let store = ProfileStore(fileURL: fileURL)
        store.addProfile(name: "  Lene ")
        XCTAssertEqual(store.humanProfiles.map(\.name), ["Lene"])

        let reloaded = ProfileStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.humanProfiles.map(\.name), ["Lene"])
    }

    func testLongNamesAreTruncated() {
        let store = ProfileStore(fileURL: fileURL)
        store.addProfile(name: String(repeating: "a", count: 60))
        XCTAssertEqual(store.humanProfiles[0].name.count, ProfileStore.maxNameLength)

        store.renameProfile(id: store.humanProfiles[0].id, to: String(repeating: "b", count: 99))
        XCTAssertEqual(store.humanProfiles[0].name.count, ProfileStore.maxNameLength)
    }

    func testRecordWinUpdatesStreakAndBestHaul() {
        let store = ProfileStore(fileURL: fileURL)
        store.addProfile(name: "Lene")
        store.addProfile(name: "Ellis")
        let lene = store.humanProfiles[0]
        let ellis = store.humanProfiles[1]
        let players = [GamePlayer(profile: lene), GamePlayer(profile: ellis)]

        store.recordGameResult(players: players, winnerProfileIDs: [lene.id], pairCounts: [5, 3])
        store.recordGameResult(players: players, winnerProfileIDs: [lene.id], pairCounts: [7, 1])

        let updated = store.humanProfiles[0]
        XCTAssertEqual(updated.wins, 2)
        XCTAssertEqual(updated.gamesPlayed, 2)
        XCTAssertEqual(updated.currentStreak, 2)
        XCTAssertEqual(updated.bestStreak, 2)
        XCTAssertEqual(updated.mostPairs, 7)

        // De verliezer telt mee als potje én houdt zijn beste vangst bij.
        let loser = store.humanProfiles[1]
        XCTAssertEqual(loser.wins, 0)
        XCTAssertEqual(loser.gamesPlayed, 2)
        XCTAssertEqual(loser.currentStreak, 0)
        XCTAssertEqual(loser.mostPairs, 3)
    }

    func testSmallerHaulKeepsTheRecord() {
        let store = ProfileStore(fileURL: fileURL)
        store.addProfile(name: "Lene")
        let lene = store.humanProfiles[0]
        let players = [GamePlayer(profile: lene)]

        store.recordGameResult(players: players, winnerProfileIDs: [lene.id], pairCounts: [8])
        store.recordGameResult(players: players, winnerProfileIDs: [lene.id], pairCounts: [4])
        XCTAssertEqual(store.humanProfiles[0].mostPairs, 8)
    }

    func testDrawCountsAndBreaksStreak() {
        let store = ProfileStore(fileURL: fileURL)
        store.addProfile(name: "Lene")
        let lene = store.humanProfiles[0]
        let players = [GamePlayer(profile: lene)]

        store.recordGameResult(players: players, winnerProfileIDs: [lene.id], pairCounts: [5])
        store.recordGameResult(players: players, winnerProfileIDs: [], pairCounts: [4])

        let updated = store.humanProfiles[0]
        XCTAssertEqual(updated.draws, 1)
        XCTAssertEqual(updated.currentStreak, 0)
        XCTAssertEqual(updated.bestStreak, 1)
    }

    func testComputerIsNeverRecorded() {
        let store = ProfileStore(fileURL: fileURL)
        store.addProfile(name: "Lene")
        let lene = store.humanProfiles[0]
        let robot = PlayerProfile.computer(level: .medium)
        let players = [GamePlayer(profile: lene), GamePlayer(profile: robot)]

        store.recordGameResult(players: players, winnerProfileIDs: [robot.id], pairCounts: [2, 6])
        XCTAssertEqual(store.profiles.count, 1)
        XCTAssertEqual(store.humanProfiles[0].gamesPlayed, 1)
        XCTAssertEqual(store.humanProfiles[0].wins, 0)
        XCTAssertEqual(store.humanProfiles[0].mostPairs, 2)
    }

    func testAvatarPaletteCountMatchesBadge() async {
        // De avatarkiezer telt op dit aantal; als het palet krimpt zonder
        // deze constante mee te nemen, crasht de modulo-logica niet maar
        // kiezen kinderen kleuren die er niet zijn.
        let count = await MainActor.run { AvatarBadge.palette.count }
        XCTAssertEqual(PlayerProfile.avatarPaletteCount, count)
    }
}
