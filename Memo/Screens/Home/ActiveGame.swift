import Foundation

/// Gedeeld door het menu en de spelerskeuze: beide kunnen een spel openen —
/// het menu een bewaard spel, de spelerskeuze een nieuw.
struct ActiveGame: Identifiable {
    let id = UUID()
    let engine: GameEngine
}
