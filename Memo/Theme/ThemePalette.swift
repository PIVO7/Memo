import SwiftUI

/// Eén kleurenstel voor de hele app. `AppTheme` leest hieruit, dus elke view
/// kleurt vanzelf mee met het gekozen thema.
struct ThemePalette {
    /// De achtergrond van elk scherm.
    let cream: Color
    /// Randen, slagschaduwen en tekst óp witte kaarten. Blijft in elk thema
    /// donker, want de kaarten blijven wit.
    let ink: Color
    /// Tekst die rechtstreeks op de achtergrond staat; in het nachtthema
    /// licht waar `ink` donker blijft.
    let headline: Color
    let sunk: Color

    let amber: Color
    let coral: Color
    let mint: Color
    let sky: Color

    let tintAmber: Color
    let tintSky: Color
    let tintCoral: Color
    let tintStone: Color

    let faint: Color
    let soft: Color
    let dim: Color

    let offFill: Color
    let offInk: Color
}

/// De thema's waaruit een speler kan kiezen.
enum ThemeID: String, CaseIterable, Identifiable {
    case klassiek
    case snoep
    case oceaan
    case nacht

    var id: String { rawValue }

    var title: String {
        switch self {
        case .klassiek: return String(localized: "Klassiek")
        case .snoep: return String(localized: "Snoep")
        case .oceaan: return String(localized: "Oceaan")
        case .nacht: return String(localized: "Nacht")
        }
    }

    var palette: ThemePalette {
        switch self {
        case .klassiek: return .klassiek
        case .snoep: return .snoep
        case .oceaan: return .oceaan
        case .nacht: return .nacht
        }
    }
}

extension ThemePalette {
    static let klassiek = ThemePalette(
        cream: Color(red: 1.00, green: 0.98, blue: 0.95),
        ink: Color(red: 0.13, green: 0.13, blue: 0.11),
        headline: Color(red: 0.13, green: 0.13, blue: 0.11),
        sunk: Color(red: 0.97, green: 0.95, blue: 0.89),
        amber: Color(red: 1.00, green: 0.79, blue: 0.24),
        coral: Color(red: 1.00, green: 0.42, blue: 0.29),
        mint: Color(red: 0.24, green: 0.84, blue: 0.55),
        sky: Color(red: 0.29, green: 0.62, blue: 1.00),
        tintAmber: Color(red: 1.00, green: 0.95, blue: 0.81),
        tintSky: Color(red: 0.89, green: 0.96, blue: 1.00),
        tintCoral: Color(red: 1.00, green: 0.87, blue: 0.83),
        tintStone: Color(red: 0.93, green: 0.89, blue: 0.82),
        faint: Color(red: 0.49, green: 0.43, blue: 0.35),
        soft: Color(red: 0.45, green: 0.39, blue: 0.31),
        dim: Color(red: 0.66, green: 0.60, blue: 0.51),
        offFill: Color(red: 0.86, green: 0.83, blue: 0.76),
        offInk: Color(red: 0.70, green: 0.66, blue: 0.59)
    )

    /// Snoepwinkel: roze als basis, maar met geel en lila ertussen — anders
    /// versmelt alles tot één roze vlak.
    static let snoep = ThemePalette(
        cream: Color(red: 0.99, green: 0.94, blue: 0.97),
        ink: Color(red: 0.17, green: 0.12, blue: 0.15),
        headline: Color(red: 0.17, green: 0.12, blue: 0.15),
        sunk: Color(red: 0.95, green: 0.93, blue: 0.89),
        amber: Color(red: 1.00, green: 0.76, blue: 0.30),
        coral: Color(red: 0.94, green: 0.34, blue: 0.61),
        mint: Color(red: 0.27, green: 0.84, blue: 0.65),
        sky: Color(red: 0.69, green: 0.42, blue: 0.91),
        tintAmber: Color(red: 1.00, green: 0.93, blue: 0.76),
        tintSky: Color(red: 0.93, green: 0.88, blue: 1.00),
        tintCoral: Color(red: 1.00, green: 0.80, blue: 0.88),
        tintStone: Color(red: 0.93, green: 0.89, blue: 0.84),
        faint: Color(red: 0.52, green: 0.36, blue: 0.45),
        soft: Color(red: 0.51, green: 0.35, blue: 0.44),
        dim: Color(red: 0.68, green: 0.54, blue: 0.62),
        offFill: Color(red: 0.89, green: 0.83, blue: 0.86),
        offInk: Color(red: 0.69, green: 0.59, blue: 0.64)
    )

    static let oceaan = ThemePalette(
        cream: Color(red: 0.92, green: 0.96, blue: 0.97),
        ink: Color(red: 0.11, green: 0.17, blue: 0.20),
        headline: Color(red: 0.11, green: 0.17, blue: 0.20),
        sunk: Color(red: 0.93, green: 0.96, blue: 0.94),
        amber: Color(red: 1.00, green: 0.82, blue: 0.40),
        coral: Color(red: 1.00, green: 0.48, blue: 0.33),
        mint: Color(red: 0.18, green: 0.79, blue: 0.65),
        sky: Color(red: 0.18, green: 0.61, blue: 0.91),
        tintAmber: Color(red: 1.00, green: 0.94, blue: 0.82),
        tintSky: Color(red: 0.87, green: 0.95, blue: 0.99),
        tintCoral: Color(red: 1.00, green: 0.88, blue: 0.84),
        tintStone: Color(red: 0.89, green: 0.93, blue: 0.92),
        faint: Color(red: 0.31, green: 0.43, blue: 0.47),
        soft: Color(red: 0.29, green: 0.42, blue: 0.46),
        dim: Color(red: 0.48, green: 0.59, blue: 0.62),
        offFill: Color(red: 0.84, green: 0.89, blue: 0.88),
        offInk: Color(red: 0.58, green: 0.66, blue: 0.66)
    )

    /// De kaarten en het scoreblad blijven wit met donkere inkt; alleen de
    /// wereld eromheen wordt donker. Zo blijft het spel zelf even leesbaar
    /// als overdag.
    static let nacht = ThemePalette(
        cream: Color(red: 0.14, green: 0.16, blue: 0.24),
        ink: Color(red: 0.13, green: 0.13, blue: 0.11),
        headline: Color(red: 0.97, green: 0.95, blue: 0.91),
        sunk: Color(red: 0.97, green: 0.95, blue: 0.89),
        amber: Color(red: 1.00, green: 0.79, blue: 0.24),
        coral: Color(red: 1.00, green: 0.46, blue: 0.36),
        mint: Color(red: 0.28, green: 0.87, blue: 0.60),
        sky: Color(red: 0.40, green: 0.68, blue: 1.00),
        tintAmber: Color(red: 1.00, green: 0.95, blue: 0.81),
        tintSky: Color(red: 0.89, green: 0.96, blue: 1.00),
        tintCoral: Color(red: 1.00, green: 0.87, blue: 0.83),
        tintStone: Color(red: 0.93, green: 0.89, blue: 0.82),
        faint: Color(red: 0.62, green: 0.66, blue: 0.77),
        soft: Color(red: 0.72, green: 0.76, blue: 0.85),
        dim: Color(red: 0.52, green: 0.56, blue: 0.67),
        offFill: Color(red: 0.29, green: 0.32, blue: 0.41),
        offInk: Color(red: 0.55, green: 0.58, blue: 0.68)
    )
}
