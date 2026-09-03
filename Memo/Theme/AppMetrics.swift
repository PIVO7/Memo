import SwiftUI

/// Alle maten op één plek, zodat een iPad niet dezelfde punten krijgt als een
/// iPhone. Wordt uit de horizontale grootteklasse afgeleid: `.regular` is een
/// iPad op vol scherm, `.compact` een iPhone of een smal deelvenster.
struct AppMetrics {
    /// Eén knoprol: hoogte, lettergrootte en diepte horen bij elkaar, zodat
    /// nergens meer losse vermenigvuldigers bijna-gelijke knoppen opleveren.
    struct ButtonRole {
        var height: CGFloat
        var textSize: CGFloat
        var depth: CGFloat
    }

    /// De sierstenen op het startscherm.
    var discSize: CGFloat
    /// Lucht tussen de gaatjes van het speelbord.
    var boardGap: CGFloat
    /// De rand van het bord rond het raster van gaatjes.
    var boardPadding: CGFloat

    var rowHeight: CGFloat
    var iconWidth: CGFloat

    // De vier vaste hoekrollen: kleine cellen en chips, knoppen, kaarten en
    // dialogen. Geen andere radii.
    var cellCorner: CGFloat
    var buttonCorner: CGFloat
    var cardCorner: CGFloat
    var dialogCorner: CGFloat

    // De drie vaste dieptes: ondiep (iconknoppen, chips), standaard
    // (kaarten en knoppen) en held (startknop, dialogen).
    var shallowDepth: CGFloat
    var depth: CGFloat
    var heroDepth: CGFloat

    var border: CGFloat
    var thinBorder: CGFloat

    // De vaste knoprollen: de held onderaan een scherm, de gewone knop, de
    // compacte knop in dialogen en lijsten. Iconknoppen zijn `tapTarget`
    // breed met `shallowDepth`.
    var heroButton: ButtonRole
    var defaultButton: ButtonRole
    var compactButton: ButtonRole

    var gutter: CGFloat
    var contentMaxWidth: CGFloat
    /// Breedte van het eindscherm; dat blijft een dialoog, geen volle pagina.
    var overlayMaxWidth: CGFloat
    var avatarSize: CGFloat

    /// Apple's ondergrens voor een aanraakvlak. Nooit kleiner maken.
    var tapTarget: CGFloat

    var brandSize: CGFloat
    var titleSize: CGFloat
    var displaySize: CGFloat
    var bodySize: CGFloat
    var captionSize: CGFloat

    static let phone = AppMetrics(
        discSize: 60, boardGap: 6, boardPadding: 12,
        rowHeight: 44, iconWidth: 44,
        cellCorner: 11, buttonCorner: 16, cardCorner: 20, dialogCorner: 24,
        shallowDepth: 3, depth: 5, heroDepth: 6,
        border: 3, thinBorder: 2,
        heroButton: ButtonRole(height: 60, textSize: 21, depth: 6),
        defaultButton: ButtonRole(height: 54, textSize: 18, depth: 5),
        compactButton: ButtonRole(height: 49, textSize: 17, depth: 5),
        gutter: 14, contentMaxWidth: .infinity, overlayMaxWidth: 460, avatarSize: 44,
        tapTarget: 44,
        brandSize: 52, titleSize: 40, displaySize: 30,
        bodySize: 17, captionSize: 12
    )

    static let pad = AppMetrics(
        discSize: 88, boardGap: 9, boardPadding: 18,
        rowHeight: 54, iconWidth: 54,
        cellCorner: 15, buttonCorner: 21, cardCorner: 26, dialogCorner: 30,
        shallowDepth: 4, depth: 7, heroDepth: 8,
        border: 4, thinBorder: 2.5,
        heroButton: ButtonRole(height: 78, textSize: 28, depth: 8),
        defaultButton: ButtonRole(height: 70, textSize: 24, depth: 7),
        compactButton: ButtonRole(height: 64, textSize: 21, depth: 7),
        gutter: 24, contentMaxWidth: 760, overlayMaxWidth: 520, avatarSize: 58,
        tapTarget: 52,
        brandSize: 78, titleSize: 56, displaySize: 44,
        bodySize: 21, captionSize: 15
    )

    static func resolve(_ sizeClass: UserInterfaceSizeClass?) -> AppMetrics {
        sizeClass == .regular ? .pad : .phone
    }

    /// Laat de maten meegroeien met de tekstgrootte van de gebruiker. Twee
    /// snelheden, want niet alles kan even hard groeien:
    ///
    /// - tekst mag ook krimpen als iemand een kleine letter kiest;
    /// - aanraakvlakken groeien mee maar zakken nooit onder de basismaat.
    ///
    /// Het bord zelf schaalt niet: dat vult sowieso de beschikbare breedte.
    func scaled(by factor: CGFloat) -> AppMetrics {
        let text = min(factor, 2)
        let touch = min(max(factor, 1), 2)

        var copy = self
        copy.brandSize *= text
        copy.titleSize *= text
        copy.displaySize *= text
        copy.bodySize *= text
        copy.captionSize *= text

        copy.tapTarget *= touch
        copy.avatarSize *= touch

        for keyPath in [\AppMetrics.heroButton, \.defaultButton, \.compactButton] {
            copy[keyPath: keyPath].textSize *= text
            copy[keyPath: keyPath].height *= touch
        }
        return copy
    }
}

extension EnvironmentValues {
    /// Alle maten komen hierlangs, zodat grootteklasse en tekstgrootte op één
    /// plek verwerkt worden in plaats van in elke view opnieuw.
    @Entry var metrics: AppMetrics = .phone
}

private struct MetricsProvider: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    /// Verhouding tussen de gekozen en de standaard tekstgrootte. Onze fonts
    /// hebben een vaste puntmaat en schalen dus niet vanzelf mee.
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .environment(\.metrics, AppMetrics.resolve(sizeClass).scaled(by: textScale))
            // Het systeemkleurenschema volgt het gekozen thema, niet de
            // instelling van het toestel: in donkere modus werden de
            // navigatietitel en placeholders anders wit op onze lichte
            // vlakken. Op elke presentatiewortel, want een blad erft het
            // schema niet van het scherm eronder.
            .preferredColorScheme(ThemeStore.shared.themeID == .nacht ? .dark : .light)
    }
}

extension View {
    /// Zet de maten klaar voor alles hieronder. Hoort op elke schermwortel,
    /// ook binnen een cover — die erft de omgeving niet altijd.
    func appMetrics() -> some View {
        modifier(MetricsProvider())
    }
}
