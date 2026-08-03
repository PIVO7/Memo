import XCTest
import SwiftUI
@testable import Memo

/// Geen assert-tests maar een rooktest die de belangrijkste views naar PNG
/// rendert, zodat een build zonder simulator-interactie toch visueel te
/// controleren valt. De bestanden landen in de map uit RENDER_OUTPUT_DIR;
/// zonder die variabele slaat de test over.
@MainActor
final class RenderSmokeTests: XCTestCase {
    private var outputDirectory: URL? {
        ProcessInfo.processInfo.environment["RENDER_OUTPUT_DIR"].map {
            URL(fileURLWithPath: $0, isDirectory: true)
        }
    }

    func testRenderKeyScreens() throws {
        guard let outputDirectory else {
            throw XCTSkip("RENDER_OUTPUT_DIR niet gezet; rooktest alleen op verzoek.")
        }

        let engine = GameEngine(
            mode: .versusFriends,
            profiles: [
                PlayerProfile(name: "Lene"),
                PlayerProfile(name: "Ellis", avatarColorIndex: 1)
            ],
            boardSize: .medium,
            seed: 7
        )
        // Eén paar open, één paar gevonden: zo toont de render alle staten.
        for first in engine.cards.indices {
            if let second = engine.cards.indices.first(where: {
                $0 != first && engine.cards[$0].face == engine.cards[first].face
            }) {
                engine.flip(at: first)
                engine.flip(at: second)
                break
            }
        }
        engine.flip(at: engine.cards.indices.first(where: { !engine.cards[$0].isMatched })!)

        try render(
            CardGridView(
                cards: engine.cards,
                columns: engine.boardSize.columns,
                playerName: { engine.players[$0].name },
                isEnabled: true,
                onFlip: { _ in }
            )
            .padding(16)
            .frame(width: 390, height: 560)
            .background(AppTheme.cream),
            to: outputDirectory.appending(path: "cards.png")
        )

        try render(
            PaywallView(entitlements: EntitlementStore(previewUnlocked: false))
                .frame(width: 390, height: 760),
            to: outputDirectory.appending(path: "paywall.png")
        )

        try render(
            GameResultOverlay(
                players: engine.players,
                winnerProfileIDs: [engine.players[0].profileID],
                message: "Lene wint met 5 paren!",
                pairCounts: [5, 3],
                isNewRecord: true,
                onRematch: {},
                onClose: {}
            )
            .frame(width: 390, height: 760)
            .background(AppTheme.cream),
            to: outputDirectory.appending(path: "result.png")
        )
    }

    private func render(_ view: some View, to url: URL) throws {
        let renderer = ImageRenderer(content: view.environment(\.metrics, .phone))
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.uiImage, "Renderen mislukt voor \(url.lastPathComponent)")
        try XCTUnwrap(image.pngData()).write(to: url)
    }
}
