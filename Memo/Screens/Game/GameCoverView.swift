import SwiftUI

/// De volledige-schermcover met een lopend spel. Eén plek voor het
/// rematch-ritueel (verse engine met dezelfde deelnemers, meteen bewaren),
/// zodat start- en beginscherm niet elk hun eigen kopie dragen.
struct GameCoverView: View {
    let game: ActiveGame
    let profileStore: ProfileStore
    let gameStore: GameStore
    @Binding var activeGame: ActiveGame?

    var body: some View {
        GameView(
            engine: game.engine,
            onRematch: {
                // Wie vorige keer tweede was, mag nu beginnen.
                let engine = GameEngine(
                    mode: game.engine.mode,
                    profiles: game.engine.rematchProfiles(),
                    startingPlayerIndex: (game.engine.startingPlayerIndex + 1) % max(game.engine.players.count, 1)
                )
                gameStore.save(engine.snapshot)
                activeGame = ActiveGame(engine: engine)
            },
            onClose: { activeGame = nil }
        )
        .environment(profileStore)
        .environment(gameStore)
        .appMetrics()
    }
}
