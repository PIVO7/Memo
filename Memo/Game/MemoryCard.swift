import Foundation

/// De voorkant van een kaartje: een vormpje met een kleur en een naam die
/// VoiceOver kan uitspreken. Twee kaarten met dezelfde voorkant zijn een paar.
struct CardFace: Codable, Equatable, Hashable {
    /// SF Symbol, kindherkenbaar (dieren en simpele vormen).
    var symbol: String
    /// Index in `AvatarBadge.palette`, dezelfde kleuren als de bolletjes.
    var colorIndex: Int
    /// Uitspreekbare naam ("Hond"), ook het onderscheid zonder kleur.
    var label: String

    /// De volledige kaartendoos. Zestien voorkanten is genoeg voor het
    /// grootste bord (twaalf paren) plus wat variatie tussen potjes.
    static let catalog: [CardFace] = [
        CardFace(symbol: "cat.fill", colorIndex: 4, label: String(localized: "Kat")),
        CardFace(symbol: "dog.fill", colorIndex: 5, label: String(localized: "Hond")),
        CardFace(symbol: "hare.fill", colorIndex: 0, label: String(localized: "Haas")),
        CardFace(symbol: "tortoise.fill", colorIndex: 3, label: String(localized: "Schildpad")),
        CardFace(symbol: "bird.fill", colorIndex: 1, label: String(localized: "Vogel")),
        CardFace(symbol: "fish.fill", colorIndex: 1, label: String(localized: "Vis")),
        CardFace(symbol: "ladybug.fill", colorIndex: 0, label: String(localized: "Lieveheersbeestje")),
        CardFace(symbol: "pawprint.fill", colorIndex: 5, label: String(localized: "Pootafdruk")),
        CardFace(symbol: "star.fill", colorIndex: 2, label: String(localized: "Ster")),
        CardFace(symbol: "heart.fill", colorIndex: 0, label: String(localized: "Hart")),
        CardFace(symbol: "bolt.fill", colorIndex: 2, label: String(localized: "Bliksem")),
        CardFace(symbol: "crown.fill", colorIndex: 2, label: String(localized: "Kroon")),
        CardFace(symbol: "sun.max.fill", colorIndex: 2, label: String(localized: "Zon")),
        CardFace(symbol: "moon.stars.fill", colorIndex: 4, label: String(localized: "Maan")),
        CardFace(symbol: "flame.fill", colorIndex: 5, label: String(localized: "Vlam")),
        CardFace(symbol: "leaf.fill", colorIndex: 3, label: String(localized: "Blad"))
    ]
}

/// Eén kaartje op tafel.
struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let face: CardFace
    var isFaceUp = false
    /// Spelerindex van wie het paar vond; `nil` zolang de kaart nog meedoet.
    var matchedBy: Int?

    var isMatched: Bool { matchedBy != nil }
}

/// De drie bordgroottes. Klein is voor de jongsten; groot is voor wie het
/// spelbord van tafel kent.
enum BoardSize: String, Codable, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var pairCount: Int {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        }
    }

    var title: String {
        switch self {
        case .small: return String(localized: "Klein")
        case .medium: return String(localized: "Middel")
        case .large: return String(localized: "Groot")
        }
    }

    var subtitle: String {
        String(localized: "\(pairCount) paren")
    }

    /// Kolommen in het raster; rechtop op een iPhone gemikt.
    var columns: Int {
        switch self {
        case .small: return 3
        case .medium: return 4
        case .large: return 4
        }
    }

    /// Bouwt een geschud kaartspel voor dit bord.
    static func deck(for size: BoardSize, using rng: inout SplitMix64) -> [MemoryCard] {
        let faces = CardFace.catalog.shuffled(using: &rng).prefix(size.pairCount)
        return (faces + faces).shuffled(using: &rng).map { MemoryCard(face: $0) }
    }
}
