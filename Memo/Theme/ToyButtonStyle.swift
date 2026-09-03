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
/// De speelgoed-schakelaar: een capsule met inktrand en een knop met eigen
/// dikte — de vervanger van de iOS-toggle, die als enig systeemelement
/// tussen de toy blocks uit de toon viel.
@MainActor
struct ToyToggleStyle: ToggleStyle {
    @Environment(\.metrics) private var m

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer(minLength: m.gutter)
                track(isOn: configuration.isOn)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
    }

    private func track(isOn: Bool) -> some View {
        let height = m.tapTarget * 0.72
        let width = height * 1.75
        let knob = height - 9

        return ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? AppTheme.mint : AppTheme.offFill)
            Capsule()
                .strokeBorder(AppTheme.ink, lineWidth: m.thinBorder)

            // De knop als mini toy block: wit met inktrand en depth 2.
            Circle()
                .fill(AppTheme.card)
                .overlay(Circle().strokeBorder(AppTheme.ink, lineWidth: m.thinBorder))
                .background(Circle().fill(AppTheme.ink).offset(y: 2))
                .frame(width: knob, height: knob)
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
        }
        .frame(width: width, height: height)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isOn)
    }
}
