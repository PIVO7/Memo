import SwiftUI


/// Knop die bij het indrukken echt inzakt: de schaduw krimpt terwijl de knop
/// evenveel naar beneden schuift, zodat de totale hoogte gelijk blijft.
@MainActor
struct ToyButtonStyle: ButtonStyle {
    var fill: Color
    var radius: CGFloat = 18
    var depth: CGFloat = 6
    var border: CGFloat = 3
    var borderColor: Color = AppTheme.ink

    func makeBody(configuration: Configuration) -> some View {
        // Bij depth 0 valt er niets in te zakken; dan blijft de knop stilstaan.
        // Anders zakt de knop helemaal tot op de grond: schaduw plat, en de
        // volle diepte naar beneden — ook een ondiep scorevakje geeft zo een
        // voelbare klik.
        let sunk = configuration.isPressed && depth > 0
        return configuration.label
            .toyBlock(fill: fill, radius: radius, depth: sunk ? 0 : depth, border: border, borderColor: borderColor)
            .offset(y: sunk ? depth : 0)
            .animation(.easeOut(duration: 0.08), value: sunk)
    }
}
