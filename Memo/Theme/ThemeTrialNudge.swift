import SwiftUI

/// Het bordje na een proefpotje: het thema staat weer op Klassiek, en hier
/// is de weg naar de winkel. Verschijnt één keer, op het scherm waar het
/// spel naar terugkeert — en alleen daar, want dat scherm ziet zijn eigen
/// spelcover dichtgaan.
private struct ThemeTrialNudge: ViewModifier {
    let game: ActiveGame?

    @Environment(EntitlementStore.self) private var entitlements
    @State private var endedTheme: ThemeID?
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if let endedTheme {
                    ToyDialog(
                        title: String(localized: "Dat was \(endedTheme.title) op proef"),
                        message: String(localized: "Het thema staat weer op Klassiek. Met de Gezinsversie blijft \(endedTheme.title) gewoon aan — en de andere thema's ook."),
                        confirmTitle: String(localized: "Bekijk de Gezinsversie"),
                        cancelTitle: String(localized: "Oké"),
                        onConfirm: {
                            dismiss()
                            showPaywall = true
                        },
                        onCancel: dismiss
                    )
                }
            }
            .onChange(of: game?.id) { _, id in
                guard id == nil else { return }
                check()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(entitlements: entitlements)
                    .appMetrics()
            }
    }

    private func check() {
        guard endedTheme == nil, let ended = ThemeStore.shared.consumeEndedTrial() else { return }
        withAnimation(.easeOut(duration: 0.15)) {
            endedTheme = ended
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.15)) {
            endedTheme = nil
        }
    }
}

extension View {
    /// Toont het bordje na een proefpotje zodra deze spelcover dichtgaat.
    func themeTrialNudge(after game: ActiveGame?) -> some View {
        modifier(ThemeTrialNudge(game: game))
    }
}
