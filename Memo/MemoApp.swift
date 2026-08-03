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
                    if !unlocked {
                        ThemeStore.shared.enforceFreeTheme()
                    }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            // Naar de achtergrond: eerst de wachtrij met zetten op schijf
            // laten landen, zodat een snelle force-quit niets verliest.
            if phase == .background {
                Task { await gameStore.flush() }
            }
        }
    }
}
