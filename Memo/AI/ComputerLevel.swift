import Foundation

/// De drie computertegenstanders. Geen kale moeilijkheidsgraden maar
/// persona's met een naam en een gezicht: dezelfde drie als in Dobbel, zodat
/// de tegenstanders over de PIVO7-spelletjes heen bekenden worden.
enum ComputerLevel: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var personaName: String {
        switch self {
        case .easy: return String(localized: "Dommel")
        case .medium: return String(localized: "Robbie")
        case .hard: return String(localized: "Professor Punt")
        }
    }

    var subtitle: String {
        switch self {
        case .easy: return String(localized: "vergeet bijna alles")
        case .medium: return String(localized: "onthoudt best veel")
        case .hard: return String(localized: "vergeet nooit iets")
        }
    }

    var avatarColorIndex: Int {
        switch self {
        case .easy: return 2
        case .medium: return 5
        case .hard: return 4
        }
    }

    /// Elk persona een eigen gezichtje op het bolletje.
    var avatarSymbol: String {
        switch self {
        case .easy: return "tortoise.fill"
        case .medium: return "gamecontroller.fill"
        case .hard: return "graduationcap.fill"
        }
    }
}
