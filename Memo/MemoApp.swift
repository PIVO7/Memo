import SwiftUI

@main
struct MemoApp: App {
    @State private var profileStore = ProfileStore()
    @State private var gameStore = GameStore()
    @State private var entitlements = EntitlementStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(profileStore)
                .environment(gameStore)
                .environment(entitlements)
                .appMetrics()
                .task {
                    // Bij de start opnieuw toetsen: na een terugbetaling mag
                    // een premiumthema niet blijven hangen.
                    await entitlements.load()
                    if !entitlements.isFamilyUnlocked {
                        ThemeStore.shared.enforceFreeTheme()
                    }
                }
                .onChange(of: entitlements.isFamilyUnlocked) { _, unlocked in
                    // Gekocht tijdens een proefpotje: dat thema blijft gewoon aan.
                    if unlocked {
                        ThemeStore.shared.adoptTrial()
                    }
                    if !unlocked {
                        ThemeStore.shared.enforceFreeTheme()
                    }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            // Meteen naar schijf zodra de app uit beeld raakt: een kind dat
            // direct daarna de app wegveegt, raakt anders de laatste zet kwijt.
            if phase == .background || phase == .inactive {
                gameStore.persistNow()
            }
        }
    }
}
