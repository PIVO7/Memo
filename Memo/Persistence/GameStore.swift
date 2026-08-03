import Foundation
import Observation
import OSLog

/// Buiten de actor, zodat de losgekoppelde schrijftaken hem ook mogen
/// gebruiken; `Logger` is Sendable.
private let opslagLogger = Logger(subsystem: "com.pivo7.memo", category: "spelstand")

@MainActor
@Observable
final class GameStore {
    private(set) var savedGame: GameSnapshot?

    private let fileURL: URL
    private let decoder = JSONDecoder()
    /// De laatste schrijfactie; elke volgende wacht hierop, zodat een oudere
    /// zet nooit ná een nieuwere op schijf kan landen.
    private var pendingWrite: Task<Void, Never>?

    init(filename: String = "memo-saved-game.json") {
        self.fileURL = URL.documentsDirectory.appending(path: filename)
        load()
    }

    /// Test seam.
    init(fileURL: URL) {
        self.fileURL = fileURL
        load()
    }

    var hasSavedGame: Bool { savedGame != nil }

    func save(_ snapshot: GameSnapshot) {
        guard !snapshot.players.isEmpty else { return }
        savedGame = snapshot
        // Elke zet komt hierlangs. Schrijven gebeurt daarom naast de main
        // actor, in volgorde.
        let url = fileURL
        let previous = pendingWrite
        pendingWrite = Task.detached(priority: .utility) {
            await previous?.value
            do {
                try JSONEncoder().encode(snapshot).write(to: url, options: [.atomic])
            } catch {
                // Geen dialoog voor een kind, wel een spoor voor de
                // ontwikkelaar.
                opslagLogger.error("Spelstand bewaren mislukt: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func clear() {
        savedGame = nil
        let url = fileURL
        let previous = pendingWrite
        pendingWrite = Task.detached(priority: .utility) {
            await previous?.value
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Wacht tot alle schrijfacties op schijf staan. Voor tests, die meteen
    /// na een `save` of `clear` het bestand willen inspecteren.
    func flush() async {
        await pendingWrite?.value
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            savedGame = nil
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let snapshot = try decoder.decode(GameSnapshot.self, from: data)
            // Afgeronde of corrupte snapshots niet hervatten.
            guard snapshot.isResumable else {
                clear()
                return
            }
            savedGame = snapshot
        } catch {
            opslagLogger.error("Spelstand laden mislukt: \(error.localizedDescription, privacy: .public)")
            savedGame = nil
        }
    }
}
