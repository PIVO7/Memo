import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class ProfileStore {
    private(set) var profiles: [PlayerProfile] = []

    /// Langer wordt het invoerveld én het spelbord onleesbaar; de opslag
    /// knipt af zodat ook een plak-actie netjes blijft.
    static let maxNameLength = 24
    /// Genoeg voor het grafiekje (tien) met wat marge.
    static let maxHistoryLength = 20

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let logger = Logger(subsystem: "com.pivo7.memo", category: "profielen")

    init(filename: String = "memo-profiles.json") {
        self.fileURL = URL.documentsDirectory.appending(path: filename)
        load()
    }

    /// Test seam.
    init(fileURL: URL) {
        self.fileURL = fileURL
        load()
    }

    var humanProfiles: [PlayerProfile] {
        profiles.filter { !$0.isComputer }.sorted { $0.createdAt < $1.createdAt }
    }

    func addProfile(name: String, colorIndex: Int? = nil, symbol: String? = nil) {
        let trimmed = cleaned(name)
        guard !trimmed.isEmpty else { return }
        let color = colorIndex ?? profiles.count % PlayerProfile.avatarPaletteCount
        let profile = PlayerProfile(name: trimmed, avatarColorIndex: color, avatarSymbol: symbol)
        profiles.append(profile)
        save()
    }

    func renameProfile(id: UUID, to name: String) {
        let trimmed = cleaned(name)
        guard !trimmed.isEmpty,
              let index = profiles.firstIndex(where: { $0.id == id && !$0.isComputer }) else { return }
        profiles[index].name = trimmed
        save()
    }

    /// Alles uit de profieleditor in één keer; een lege naam laat de oude
    /// naam staan zodat een half ingevuld scherm nooit een naam wist.
    func updateProfile(id: UUID, name: String, colorIndex: Int, symbol: String?) {
        guard let index = profiles.firstIndex(where: { $0.id == id && !$0.isComputer }) else { return }
        let trimmed = cleaned(name)
        if !trimmed.isEmpty {
            profiles[index].name = trimmed
        }
        profiles[index].avatarColorIndex = colorIndex
        profiles[index].avatarSymbol = symbol
        save()
    }

    func updateAvatar(id: UUID, colorIndex: Int, symbol: String?) {
        guard let index = profiles.firstIndex(where: { $0.id == id && !$0.isComputer }) else { return }
        profiles[index].avatarColorIndex = colorIndex
        profiles[index].avatarSymbol = symbol
        save()
    }

    func deleteProfile(id: UUID) {
        profiles.removeAll { $0.id == id && !$0.isComputer }
        save()
    }

    /// Werkt na een afgerond spel de statistieken van alle menselijke
    /// deelnemers bij: potjes, winst, gelijkspel, winreeks en de beste
    /// vangst. `pairCounts` is het aantal gevonden paren per deelnemer, in
    /// dezelfde volgorde als `players` — ook de verliezer kan immers zijn
    /// persoonlijke record verbeteren.
    func recordGameResult(players: [GamePlayer], winnerProfileIDs: [UUID], pairCounts: [Int]) {
        for (playerIndex, player) in players.enumerated() where !player.isComputer {
            guard let index = profiles.firstIndex(where: { $0.id == player.profileID }) else { continue }
            profiles[index].gamesPlayed += 1
            let pairs = pairCounts.indices.contains(playerIndex) ? pairCounts[playerIndex] : 0
            profiles[index].mostPairs = max(profiles[index].mostPairs, pairs)
            if winnerProfileIDs.isEmpty {
                profiles[index].draws += 1
                profiles[index].currentStreak = 0
            } else if winnerProfileIDs.contains(player.profileID) {
                profiles[index].wins += 1
                profiles[index].currentStreak += 1
                profiles[index].bestStreak = max(profiles[index].bestStreak, profiles[index].currentStreak)
            } else {
                profiles[index].currentStreak = 0
            }
            // Voor het grafiekje op de statistiekenpagina; afgetopt zodat het
            // profielbestand niet meegroeit met elke speelavond.
            let won = winnerProfileIDs.contains(player.profileID)
            profiles[index].history.append(GameRecord(
                pairs: pairs,
                won: won,
                draw: winnerProfileIDs.isEmpty,
                date: .now
            ))
            profiles[index].history = Array(profiles[index].history.suffix(Self.maxHistoryLength))
        }
        save()
    }

    private func cleaned(_ name: String) -> String {
        String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxNameLength))
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            profiles = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            profiles = try decoder.decode([PlayerProfile].self, from: data)
                .filter { !$0.isComputer }
        } catch {
            // Geen dialoog voor een kind, maar wel een spoor voor de
            // ontwikkelaar.
            logger.error("Profielen laden mislukt: \(error.localizedDescription, privacy: .public)")
            profiles = []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(profiles.filter { !$0.isComputer })
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            logger.error("Profielen bewaren mislukt: \(error.localizedDescription, privacy: .public)")
        }
    }
}
