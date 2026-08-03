import SwiftUI

/// Een bevestigingsvraag in de eigen speelgoedstijl, in plaats van de grijze
/// systeemdialoog die uit de toon valt.
struct ToyDialog: View {
    let title: String
    let message: String
    let confirmTitle: String
    /// Zonder annuleerknop wordt het een mededeling met één knop.
    var cancelTitle: String?
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        ZStack {
            // Tikken om te sluiten is een extraatje voor ziende gebruikers;
            // VoiceOver krijgt de knoppen op de kaart, niet dit vlak.
            AppTheme.ink.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)
                .accessibilityHidden(true)

            VStack(spacing: m.gutter * 0.8) {
                Text(title)
                    .font(AppTheme.rounded(m.titleSize * 0.62))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppTheme.rounded(m.bodySize * 0.94, .bold))
                    .foregroundStyle(AppTheme.soft)
                    .multilineTextAlignment(.center)

                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(AppTheme.rounded(m.buttonTextSize * 0.8))
                        .foregroundStyle(AppTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: m.buttonHeight * 0.82)
                }
                .buttonStyle(ToyButtonStyle(
                    fill: AppTheme.coral,
                    radius: m.cardCorner * 0.8,
                    depth: m.depth,
                    border: m.border
                ))
                .padding(.top, 4)

                if let cancelTitle {
                    Button(action: onCancel) {
                        Text(cancelTitle)
                            .font(AppTheme.rounded(m.buttonTextSize * 0.8))
                            .foregroundStyle(AppTheme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: m.buttonHeight * 0.82)
                    }
                    .buttonStyle(ToyButtonStyle(
                        fill: .white,
                        radius: m.cardCorner * 0.8,
                        depth: m.depth,
                        border: m.border
                    ))
                }
            }
            .padding(m.gutter * 1.4)
            .toyBlock(fill: AppTheme.cream, radius: m.cardCorner + 4, depth: m.depth + 1, border: m.border)
            .frame(maxWidth: m.overlayMaxWidth * 0.82)
            .padding(m.gutter * 2)
            // Modaal voor VoiceOver: de spelknoppen eronder zijn even weg.
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.94)))
    }
}

#Preview {
    ToyDialog(
        title: "Spel verlaten?",
        message: "Je voortgang wordt bewaard.",
        confirmTitle: "Verlaten",
        cancelTitle: "Doorspelen",
        onConfirm: {},
        onCancel: {}
    )
    .background(AppTheme.cream)
    .appMetrics()
}
