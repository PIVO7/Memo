import Foundation

enum Destination: Hashable {
    case profiles
    case setup(GameMode)
    /// De statistiekenpagina van één profiel, op id zodat de pagina de
    /// actuele stand uit de store leest.
    case stats(UUID)
    case familyRecords
}
