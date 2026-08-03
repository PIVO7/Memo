import Foundation

enum GameMode: String, CaseIterable, Identifiable, Codable {
    case versusFriends
    case versusComputer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .versusFriends: return String(localized: "Tegen elkaar")
        case .versusComputer: return String(localized: "Tegen de computer")
        }
    }

    var subtitle: String {
        switch self {
        case .versusFriends: return String(localized: "Twee spelers, één toestel")
        case .versusComputer: return String(localized: "Solo tegen een slimme tegenstander")
        }
    }
}
