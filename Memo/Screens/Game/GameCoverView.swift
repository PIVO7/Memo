import SwiftUI

/// De volledige-schermcover met een lopend spel. Eén plek voor het
/// rematch-ritueel (verse engine met dezelfde deelnemers, meteen bewaren),
/// zodat start- en beginscherm niet elk hun eigen kopie dragen.
struct GameCoverView: View {
    let game: ActiveGame
    let profileStore: ProfileStore
    let gameStore: GameStore
    @Binding var activeGame: ActiveGame?

    /// Bij een rematch wisselt alleen de engine en blijft de cover staan.
    /// Het cover-item vervangen liet iOS de inhoud ter plekke bijwerken,
    /// waardoor de view-state (met het eindscherm) bleef hangen.
    @State private var rematchEngine: GameEngine?

    var body: some View {
        let engine = rematchEngine ?? game.engine
        GameView(
            engine: engine,
            onRematch: {
                // Wie vorige keer tweede was, mag nu beginnen.
                let fresh = GameEngine(
                    mode: engine.mode,
                    profiles: engine.rematchProfiles(),
                    boardSize: engine.boardSize,
                    startingPlayerIndex: (engine.startingPlayerIndex + 1) % max(engine.players.count, 1)
                )
                gameStore.save(fresh.snapshot)
                rematchEngine = fresh
            },
            onClose: { activeGame = nil }
        )
        // Verse engine, verse view-state: het eindscherm, de banners en de
        // record-vlag beginnen bij een rematch opnieuw.
        .id(ObjectIdentifier(engine))
        .environment(profileStore)
        .environment(gameStore)
        .appMetrics()
    }
}
