import XCTest
import SwiftUI
@testable import Memo

/// Rendert het volledige spelscherm naar PNG, zodat een indeling zonder
/// simulator te beoordelen valt. Slaat over zonder RENDER_OUTPUT_DIR.
@MainActor
final class GameScreenRenderTests: XCTestCase {
    private var outputDirectory: URL? {
        ProcessInfo.processInfo.environment["RENDER_OUTPUT_DIR"].map {
            URL(fileURLWithPath: $0, isDirectory: true)
        }
    }

    func testRenderGameScreen() throws {
        guard let outputDirectory else {
            throw XCTSkip("RENDER_OUTPUT_DIR niet gezet; rooktest alleen op verzoek.")
        }

        let engine = GameEngine(
            mode: .versusFriends,
            profiles: [
                PlayerProfile(name: "Lene", avatarColorIndex: 4, avatarSymbol: "heart.fill"),
                PlayerProfile(name: "Papa", avatarColorIndex: 1, avatarSymbol: "star.fill")
            ],
            boardSize: .medium,
            seed: 7
        )
        // Eén paar gevonden en één kaart open: alle staten in beeld.
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

        let view = GameView(engine: engine, onRematch: {}, onClose: {})
            .environment(ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "render-\(UUID()).json")))
            .environment(GameStore(fileURL: URL.temporaryDirectory.appending(path: "render-\(UUID()).json")))
            .environment(\.metrics, .phone)
            .frame(width: 393, height: 852)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.uiImage)
        try XCTUnwrap(image.pngData())
            .write(to: outputDirectory.appending(path: "spelscherm.png"))
    }
}
