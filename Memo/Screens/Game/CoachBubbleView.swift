import SwiftUI

/// Onthoudt of de eerste-keer-uitleg al doorlopen is; herstelbaar via
/// Instellingen.
enum CoachTour {
    private static let key = "uitleg-gezien"

    static var seen: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

/// Eén hint uit de eerste-keer-uitleg: een gele bubbel die op het juiste
/// moment verschijnt en met een tik verdwijnt.
struct CoachBubbleView: View {
    let text: String
    let icon: String
    let onDismiss: () -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        Button(action: onDismiss) {
            HStack(spacing: m.gutter * 0.6) {
                Image(systemName: icon)
                    .font(.system(size: m.bodySize + 6, weight: .black))
                    .foregroundStyle(AppTheme.coral)

                Text(text)
                    .font(AppTheme.rounded(m.captionSize + 2, .bold))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, m.gutter)
            .padding(.vertical, m.gutter * 0.75)
        }
        .buttonStyle(ToyButtonStyle(
            fill: AppTheme.tintAmber,
            radius: m.cardCorner,
            depth: m.depth,
            border: m.border
        ))
        .frame(maxWidth: 360)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
        .accessibilityHint("Tik om de uitleg te sluiten")
    }
}

#Preview {
    VStack(spacing: 16) {
        CoachBubbleView(
            text: "Tik op een kaartje om het om te draaien.",
            icon: "hand.tap.fill",
            onDismiss: {}
        )
        CoachBubbleView(
            text: "Niet hetzelfde? Onthoud waar ze liggen, ze draaien weer om.",
            icon: "brain.head.profile",
            onDismiss: {}
        )
    }
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
