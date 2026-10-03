import SwiftUI

/// Speelgoed-stijl: dikke inktranden, harde slagschaduwen zonder vervaging,
/// verzadigde kleuren. Alles moet eruitzien alsof je het kan indrukken.
///
/// De kleuren komen uit het gekozen thema in `ThemeStore`; de namen hier
/// blijven de vaste woordenschat van de app.
enum AppTheme {
    @MainActor private static var palette: ThemePalette { ThemeStore.shared.palette }

    // Grond en inkt
    @MainActor static var cream: Color { palette.cream }
    /// Kaarten, knoppen en speelstukken; wit behalve in het nachtthema.
    @MainActor static var card: Color { palette.card }
    @MainActor static var ink: Color { palette.ink }
    /// Voor tekst die rechtstreeks op de achtergrond staat; wijkt alleen in
    /// het nachtthema af van `ink`.
    @MainActor static var headline: Color { palette.headline }
    @MainActor static var sunk: Color { palette.sunk }

    // Accenten
    @MainActor static var amber: Color { palette.amber }
    @MainActor static var coral: Color { palette.coral }
    @MainActor static var mint: Color { palette.mint }
    @MainActor static var sky: Color { palette.sky }

    // Zachte vlakken achter iconen
    @MainActor static var tintAmber: Color { palette.tintAmber }
    @MainActor static var tintSky: Color { palette.tintSky }
    @MainActor static var tintCoral: Color { palette.tintCoral }
    @MainActor static var tintMint: Color { palette.tintMint }
    @MainActor static var tintStone: Color { palette.tintStone }

    // Tekst op de achtergrond
    @MainActor static var faint: Color { palette.faint }
    @MainActor static var soft: Color { palette.soft }
    @MainActor static var dim: Color { palette.dim }

    // Tekst óp een kaart: altijd inkt-gebaseerd. `soft` en `dim` zijn in het
    // nachtthema licht en verdwijnen daar tegen een lichte kaart.
    @MainActor static var cardSoft: Color { palette.ink.opacity(0.65) }
    @MainActor static var cardDim: Color { palette.ink.opacity(0.42) }

    // Uitgeschakeld
    @MainActor static var offFill: Color { palette.offFill }
    @MainActor static var offInk: Color { palette.offInk }

    /// Donkergroen voor winstcijfers op een kaart ("+21"): dit kán je erbij
    /// krijgen. Mint zelf is als tekstkleur te licht op wit; de kaarten zijn
    /// in elk thema licht, dus één vaste donkere tint leest overal.
    static let gain = Color(red: 0.05, green: 0.52, blue: 0.31)

    /// Alle tekst in de app komt hier langs; de maat komt uit `AppMetrics`,
    /// zodat een iPad grotere letters krijgt zonder aparte fontconstanten.
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
