import SwiftUI

/// Alle maten op één plek, zodat een iPad niet dezelfde punten krijgt als een
/// iPhone. Wordt uit de horizontale grootteklasse afgeleid: `.regular` is een
/// iPad op vol scherm, `.compact` een iPhone of een smal deelvenster.
struct AppMetrics {
    /// De sierstenen op het startscherm.
    var discSize: CGFloat
    /// Lucht tussen de gaatjes van het speelbord.
    var boardGap: CGFloat
    /// De rand van het bord rond het raster van gaatjes.
    var boardPadding: CGFloat

    var rowHeight: CGFloat
    var iconWidth: CGFloat
    var cellCorner: CGFloat

    var cardCorner: CGFloat
    var depth: CGFloat
    var border: CGFloat
    var thinBorder: CGFloat

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
    var buttonTextSize: CGFloat
    var buttonHeight: CGFloat

    static let phone = AppMetrics(
        discSize: 60, boardGap: 6, boardPadding: 12,
        rowHeight: 44, iconWidth: 44, cellCorner: 11,
        cardCorner: 20, depth: 5, border: 3, thinBorder: 2,
        gutter: 14, contentMaxWidth: .infinity, overlayMaxWidth: 460, avatarSize: 44,
        tapTarget: 44,
        brandSize: 52, titleSize: 40, displaySize: 30,
        bodySize: 17, captionSize: 12,
        buttonTextSize: 21, buttonHeight: 60
    )

    static let pad = AppMetrics(
        discSize: 88, boardGap: 9, boardPadding: 18,
        rowHeight: 54, iconWidth: 54, cellCorner: 15,
        cardCorner: 26, depth: 7, border: 4, thinBorder: 2.5,
        gutter: 24, contentMaxWidth: 760, overlayMaxWidth: 520, avatarSize: 58,
        tapTarget: 52,
        brandSize: 78, titleSize: 56, displaySize: 44,
        bodySize: 21, captionSize: 15,
        buttonTextSize: 28, buttonHeight: 78
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
        copy.buttonTextSize *= text

        copy.tapTarget *= touch
        copy.buttonHeight *= touch
        copy.avatarSize *= touch
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
