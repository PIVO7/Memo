import Foundation

struct GamePlayer: Identifiable, Equatable, Codable {
    let id: UUID
    let profileID: UUID
    let name: String
    let isComputer: Bool
    /// Alleen voor computerspelers; reist mee in de snapshot zodat een
    /// hervat spel dezelfde tegenstander heeft.
    var computerLevel: ComputerLevel?
    var avatarColorIndex: Int
    /// SF Symbol op het bolletje; `nil` toont de initialen.
    var avatarSymbol: String?

    init(profile: PlayerProfile) {
        self.id = UUID()
        self.profileID = profile.id
        self.name = profile.name
        self.isComputer = profile.isComputer
        self.computerLevel = profile.computerLevel
        self.avatarColorIndex = profile.avatarColorIndex
        self.avatarSymbol = profile.avatarSymbol
    }
}
