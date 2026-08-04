import Foundation

/// Eén afgerond potje in de geschiedenis van een profiel: genoeg voor het
/// grafiekje en de trofeeën, niet meer dan dat.
struct GameRecord: Codable, Equatable, Hashable {
    /// Aantal gevonden paren in dit potje.
    var pairs: Int
    var won: Bool
    var draw: Bool
    var date: Date
}
