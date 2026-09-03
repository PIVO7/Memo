import Foundation
import Observation

/// Houdt bij welk thema gekozen is en onthoudt dat over sessies heen.
/// `AppTheme` leest hier per kleur uit; doordat views die kleuren in hun
/// `body` aanraken, tekent alles vanzelf opnieuw zodra het thema wisselt.
@MainActor
@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    /// Het gekozen én bewaarde thema.
    private(set) var themeID: ThemeID
    /// Eén potje op proef: een premiumthema dat tijdelijk meedoet zonder
    /// aankoop. Bewust niet bewaard — na een herstart is het gewoon weg.
    private(set) var trialThemeID: ThemeID?
    /// Het thema waarvan het proefpotje net afliep; het eerstvolgende scherm
    /// vraagt er één keer naar en maakt het weer leeg.
    private(set) var endedTrialThemeID: ThemeID?
    /// Elk thema is één keer per sessie te proberen; een tweede tik leidt
    /// naar de winkel.
    private var triedThemeIDs: Set<ThemeID> = []

    /// Wat er nu op het scherm staat: de proef als die loopt, anders de keuze.
    var activeThemeID: ThemeID { trialThemeID ?? themeID }

    var palette: ThemePalette { activeThemeID.palette }

    private static let key = "gekozen-thema"
    private let defaults: UserDefaults

    private convenience init() {
        self.init(defaults: .standard)
    }

    /// Test seam: eigen UserDefaults, zodat een test nooit aan de echte
    /// keuze komt.
    init(defaults: UserDefaults) {
        self.defaults = defaults
        let saved = defaults.string(forKey: Self.key)
        self.themeID = saved.flatMap(ThemeID.init(rawValue:)) ?? .klassiek
    }

    func select(_ id: ThemeID) {
        trialThemeID = nil
        themeID = id
        defaults.set(id.rawValue, forKey: Self.key)
    }

    /// Terug naar Klassiek wanneer de Gezinsversie er niet (meer) is — een
    /// premiumthema mag een terugbetaling niet overleven. Een lopende proef
    /// blijft staan: die is juist bedoeld zonder aankoop.
    func enforceFreeTheme() {
        guard themeID != .klassiek else { return }
        themeID = .klassiek
        defaults.set(ThemeID.klassiek.rawValue, forKey: Self.key)
    }

    // MARK: - Proefpotje

    func canTry(_ id: ThemeID) -> Bool {
        id != .klassiek && !triedThemeIDs.contains(id)
    }

    func startTrial(_ id: ThemeID) {
        guard canTry(id) else { return }
        trialThemeID = id
        triedThemeIDs.insert(id)
    }

    /// Het potje is uit en het spelscherm gaat dicht: de proef is voorbij en
    /// het bordje mag komen.
    func endTrialAfterFinishedGame() {
        guard let trialThemeID else { return }
        endedTrialThemeID = trialThemeID
        self.trialThemeID = nil
    }

    /// Haalt het afgelopen proefthema op en maakt het meteen leeg, zodat het
    /// bordje maar op één scherm verschijnt.
    func consumeEndedTrial() -> ThemeID? {
        defer { endedTrialThemeID = nil }
        return endedTrialThemeID
    }

    /// Gekocht tijdens de proef: het proefthema wordt gewoon hét thema.
    func adoptTrial() {
        if let trialThemeID {
            select(trialThemeID)
        }
    }
}
