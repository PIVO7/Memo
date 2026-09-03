import XCTest
@testable import Memo

/// Eén potje op proef in een premiumthema: tijdelijk, niet bewaard, en na
/// het potje weer weg — tenzij er ondertussen gekocht is.
@MainActor
final class ThemeTrialTests: XCTestCase {
    private func makeStore() -> (ThemeStore, UserDefaults) {
        let defaults = UserDefaults(suiteName: "thema-test-\(UUID())")!
        return (ThemeStore(defaults: defaults), defaults)
    }

    func testTrialChangesTheActiveThemeWithoutSavingIt() {
        let (store, defaults) = makeStore()

        store.startTrial(.snoep)

        XCTAssertEqual(store.activeThemeID, .snoep)
        XCTAssertEqual(store.themeID, .klassiek)
        XCTAssertEqual(ThemeStore(defaults: defaults).themeID, .klassiek)
    }

    func testClassicCannotBeTriedAndEveryThemeOnlyOnce() {
        let (store, _) = makeStore()
        XCTAssertFalse(store.canTry(.klassiek))
        XCTAssertTrue(store.canTry(.snoep))

        store.startTrial(.snoep)
        XCTAssertFalse(store.canTry(.snoep))
        XCTAssertTrue(store.canTry(.oceaan))

        // Een tweede poging doet niets.
        store.select(.klassiek)
        store.startTrial(.snoep)
        XCTAssertNil(store.trialThemeID)
    }

    func testFinishedGameEndsTheTrialAndReportsItOnce() {
        let (store, _) = makeStore()
        store.startTrial(.oceaan)

        store.endTrialAfterFinishedGame()

        XCTAssertEqual(store.activeThemeID, .klassiek)
        XCTAssertNil(store.trialThemeID)
        XCTAssertEqual(store.consumeEndedTrial(), .oceaan)
        XCTAssertNil(store.consumeEndedTrial())
    }

    func testEndingWithoutATrialReportsNothing() {
        let (store, _) = makeStore()
        store.endTrialAfterFinishedGame()
        XCTAssertNil(store.consumeEndedTrial())
    }

    func testChoosingAThemeEndsTheTrialQuietly() {
        let (store, _) = makeStore()
        store.startTrial(.snoep)

        store.select(.klassiek)

        XCTAssertNil(store.trialThemeID)
        XCTAssertNil(store.consumeEndedTrial())
    }

    func testBuyingDuringTheTrialKeepsTheTheme() {
        let (store, defaults) = makeStore()
        store.startTrial(.nacht)

        store.adoptTrial()

        XCTAssertEqual(store.themeID, .nacht)
        XCTAssertNil(store.trialThemeID)
        XCTAssertEqual(ThemeStore(defaults: defaults).themeID, .nacht)
    }

    func testEnforcingTheFreeThemeLeavesATrialAlone() {
        let (store, _) = makeStore()
        store.select(.oceaan)
        store.startTrial(.nacht)

        store.enforceFreeTheme()

        XCTAssertEqual(store.themeID, .klassiek)
        XCTAssertEqual(store.activeThemeID, .nacht)
    }
}
