import SwiftUI

@main
struct MemoApp: App {
    @State private var profileStore = ProfileStore()
    @State private var gameStore = GameStore()
    @State private var entitlements = EntitlementStore()
    @Environment(\.scenePhase) private var scenePhase

    /// DEBUG-hulp voor demo's en screenshots: start de app met
    /// `-demoThema snoep` (of `oceaan`, `nacht`) om een premiumthema te
    /// bekijken zonder aankoop. In releasebuilds bestaat dit luik niet.
    private var demoThema: ThemeID? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-demoThema"),
              arguments.indices.contains(index + 1) else { return nil }
        return ThemeID(rawValue: arguments[index + 1])
        #else
        return nil
        #endif
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(profileStore)
                .environment(gameStore)
                .environment(entitlements)
                .appMetrics()
                .task {
                    if let demoThema {
                        ThemeStore.shared.select(demoThema)
                    }
                    // Bij de start opnieuw toetsen: na een terugbetaling mag
                    // een premiumthema niet blijven hangen.
                    await entitlements.load()
                    if !entitlements.isFamilyUnlocked, demoThema == nil {
                        ThemeStore.shared.enforceFreeTheme()
                    }
                }
                .onChange(of: entitlements.isFamilyUnlocked) { _, unlocked in
                    // Gekocht tijdens een proefpotje: dat thema blijft gewoon aan.
                    if unlocked {
                        ThemeStore.shared.adoptTrial()
                    }
                    if !unlocked, demoThema == nil {
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
