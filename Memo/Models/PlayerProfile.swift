import Foundation

struct PlayerProfile: Identifiable, Equatable, Codable, Hashable {
    let id: UUID
    var name: String
    var wins: Int
    var gamesPlayed: Int
    var avatarColorIndex: Int
    /// SF Symbol op het bolletje; `nil` toont de initialen.
    var avatarSymbol: String?
    var createdAt: Date
    /// Alleen gezet voor computertegenstanders; `nil` betekent een mens.
    var computerLevel: ComputerLevel?

    // Statistieken, bijgehouden per afgerond spel.
    var draws: Int
    var currentStreak: Int
    var bestStreak: Int
    /// Meeste paren ooit in één potje; 0 betekent nog niet gespeeld.
    var mostPairs: Int
    /// De laatste potjes, voor het grafiekje op de statistiekenpagina.
    var history: [GameRecord]

    init(
        id: UUID = UUID(),
        name: String,
        wins: Int = 0,
        gamesPlayed: Int = 0,
        avatarColorIndex: Int = 0,
        avatarSymbol: String? = nil,
        createdAt: Date = .now,
        computerLevel: ComputerLevel? = nil,
        draws: Int = 0,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        mostPairs: Int = 0,
        history: [GameRecord] = []
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.wins = wins
        self.gamesPlayed = gamesPlayed
        self.avatarColorIndex = avatarColorIndex
        self.avatarSymbol = avatarSymbol
        self.createdAt = createdAt
        self.computerLevel = computerLevel
        self.draws = draws
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.mostPairs = mostPairs
        self.history = history
    }

    /// Met de hand, zodat oudere profielbestanden zonder de statistiekvelden
    /// gewoon blijven laden.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        wins = try container.decode(Int.self, forKey: .wins)
        gamesPlayed = try container.decode(Int.self, forKey: .gamesPlayed)
        avatarColorIndex = try container.decode(Int.self, forKey: .avatarColorIndex)
        avatarSymbol = try container.decodeIfPresent(String.self, forKey: .avatarSymbol)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        computerLevel = try container.decodeIfPresent(ComputerLevel.self, forKey: .computerLevel)
        draws = try container.decodeIfPresent(Int.self, forKey: .draws) ?? 0
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        bestStreak = try container.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        mostPairs = try container.decodeIfPresent(Int.self, forKey: .mostPairs) ?? 0
        history = try container.decodeIfPresent([GameRecord].self, forKey: .history) ?? []
    }

    /// Aantal kleuren in het avatarpalet; `AvatarBadge.palette` moet even
    /// lang zijn (een test bewaakt dat).
    static let avatarPaletteCount = 6

    /// Vaste id's, zodat een bewaard spel na een herstart dezelfde
    /// tegenstander terugvindt.
    static let computerIDs: [ComputerLevel: UUID] = [
        .easy: UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!,
        .medium: UUID(uuidString: "00000000-0000-0000-0000-0000000000C0")!,
        .hard: UUID(uuidString: "00000000-0000-0000-0000-0000000000C2")!
    ]

    static func computer(level: ComputerLevel) -> PlayerProfile {
        PlayerProfile(
            id: computerIDs[level]!,
            name: level.personaName,
            avatarColorIndex: level.avatarColorIndex,
            avatarSymbol: level.avatarSymbol,
            computerLevel: level
        )
    }

    var isComputer: Bool {
        // Op id én op niveau: oude bewaarde spellen kennen alleen het id.
        computerLevel != nil || Self.computerIDs.values.contains(id)
    }
}
