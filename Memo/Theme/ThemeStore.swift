import Foundation
import Observation

/// Houdt bij welk thema gekozen is en onthoudt dat over sessies heen.
/// `AppTheme` leest hier per kleur uit; doordat views die kleuren in hun
/// `body` aanraken, tekent alles vanzelf opnieuw zodra het thema wisselt.
@MainActor
@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    private(set) var themeID: ThemeID

    var palette: ThemePalette { themeID.palette }

    private static let key = "gekozen-thema"

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.key)
        self.themeID = saved.flatMap(ThemeID.init(rawValue:)) ?? .klassiek
    }

    func select(_ id: ThemeID) {
        themeID = id
        UserDefaults.standard.set(id.rawValue, forKey: Self.key)
    }

    /// Terug naar Klassiek wanneer de Gezinsversie er niet (meer) is — een
    /// premiumthema mag een terugbetaling niet overleven.
    func enforceFreeTheme() {
        if themeID != .klassiek {
            select(.klassiek)
        }
    }
}
