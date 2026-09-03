import Foundation

enum GameMode: String, CaseIterable, Identifiable, Codable {
    case versusFriends
    case versusComputer
    /// Solo, met een stopwatch: alle paren zo snel mogelijk. Er valt niets
    /// te verliezen — je bent altijd klaar — alleen je eigen tijd te kloppen.
    case timeTrial

    var id: String { rawValue }

    var title: String {
        switch self {
        case .versusFriends: return String(localized: "Tegen elkaar")
        case .versusComputer: return String(localized: "Tegen de computer")
        case .timeTrial: return String(localized: "Tegen de klok")
        }
    }

    var subtitle: String {
        switch self {
        case .versusFriends: return String(localized: "Twee spelers, één toestel")
        case .versusComputer: return String(localized: "Solo tegen een slimme tegenstander")
        case .timeTrial: return String(localized: "Solo: alle paren zo snel mogelijk")
        }
    }

    /// Eén speler aan tafel, zonder tegenstander.
    var isSolo: Bool { self == .timeTrial }

    /// Tegen de klok hoort bij de Gezinsversie.
    var isPremium: Bool { self == .timeTrial }
}
