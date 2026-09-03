import SwiftUI

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
        // De eigen knop verliest de ingebouwde waarde van Toggle; zonder
        // deze regel hoort VoiceOver niet of de schakelaar aan staat.
        .accessibilityValue(configuration.isOn ? Text("Aan") : Text("Uit"))
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
                .overlay { Circle().strokeBorder(AppTheme.ink, lineWidth: m.thinBorder) }
                .background { Circle().fill(AppTheme.ink).offset(y: 2) }
                .frame(width: knob, height: knob)
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
        }
        .frame(width: width, height: height)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isOn)
    }
}
