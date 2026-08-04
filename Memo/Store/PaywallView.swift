import SwiftUI

/// Het aankoopscherm van de Gezinsversie: wat je krijgt, één prijs, en een
/// ouder-poort vóór de kassa.
struct PaywallView: View {
    let entitlements: EntitlementStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m

    @State private var gateQuestion: ParentalGateQuestion?
    @State private var pendingAction: (() async -> Void)?
    @State private var isBusy = false
    /// Uitleg wanneer een aankoop niet doorging; annuleren blijft stil.
    @State private var purchaseNotice: String?

    private var priceText: String {
        entitlements.familyProduct?.displayPrice ?? "…"
    }

    var body: some View {
        ZStack {
            ThemedBackground()

            ScrollView {
                VStack(spacing: m.gutter) {
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.system(size: m.titleSize, weight: .black))
                        .foregroundStyle(AppTheme.coral)

                    Text("Gezinsversie")
                        .font(AppTheme.rounded(m.titleSize * 0.7))
                        .foregroundStyle(AppTheme.headline)

                    Text("Eén keer kopen, voor het hele gezin — ook via Delen met gezin.")
                        .font(AppTheme.rounded(m.captionSize + 2, .bold))
                        .foregroundStyle(AppTheme.soft)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: m.gutter * 0.7) {
                        feature("graduationcap.fill", "Alle drie de tegenstanders: Dommel, Robbie en Professor Punt")
                        feature("paintpalette.fill", "Alle kleurenthema's: Snoep, Oceaan en Nacht")
                        feature("chart.bar.fill", "Statistieken per speler, met winreeks en beste vangst")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(m.gutter)
                    .toyBlock(fill: AppTheme.card, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)

                    if entitlements.isFamilyUnlocked {
                        Label("Ontgrendeld — veel plezier!", systemImage: "checkmark.seal.fill")
                            .font(AppTheme.rounded(m.bodySize))
                            .foregroundStyle(AppTheme.mint)
                            .padding(.top, m.gutter)
                    } else {
                        Button {
                            askParent { await purchase() }
                        } label: {
                            Text("Ontgrendel voor \(priceText)")
                                .font(AppTheme.rounded(m.buttonTextSize * 0.8))
                                .foregroundStyle(AppTheme.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: m.buttonHeight * 0.85)
                        }
                        .buttonStyle(ToyButtonStyle(
                            fill: AppTheme.mint,
                            radius: m.cardCorner * 0.9,
                            depth: m.depth,
                            border: m.border
                        ))
                        .disabled(isBusy)

                        Button {
                            askParent { await entitlements.restorePurchases() }
                        } label: {
                            Text("Eerder gekocht? Zet terug")
                                .font(AppTheme.rounded(m.captionSize, .bold))
                                .foregroundStyle(AppTheme.soft)
                                .frame(minHeight: m.tapTarget)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .disabled(isBusy)
                    }
                }
                .padding(.horizontal, m.gutter * 1.4)
                .padding(.top, m.gutter)
                .padding(.bottom, m.gutter * 2)
                .frame(maxWidth: m.overlayMaxWidth)
                .frame(maxWidth: .infinity)
            }
            // De sluitknop hoort in de hoek van het vénster, niet in de
            // hoek van de smallere tekstkolom — op iPad zweefde hij anders
            // ergens halverwege.
            .overlay(alignment: .topTrailing) {
                Button(action: { dismiss() }) {
                    Label("Sluiten", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .font(.system(size: m.captionSize + 2, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: m.tapTarget, height: m.tapTarget)
                }
                .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cellCorner, depth: 3, border: m.thinBorder))
                .padding(.top, m.gutter)
                .padding(.trailing, m.gutter)
            }

            // De ouder-poort: verplicht voor de kindercategorie, en eerlijk
            // gezegd gewoon verstandig.
            if let question = gateQuestion {
                gateOverlay(question)
            }

            if let purchaseNotice {
                ToyDialog(
                    title: String(localized: "Dat lukte niet"),
                    message: purchaseNotice,
                    confirmTitle: String(localized: "Oké"),
                    onConfirm: dismissNotice,
                    onCancel: dismissNotice
                )
            }
        }
        .interactiveDismissDisabled(isBusy)
    }

    private func feature(_ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: m.gutter * 0.6) {
            Image(systemName: icon)
                .font(.system(size: m.bodySize, weight: .black))
                .foregroundStyle(AppTheme.coral)
                .frame(width: m.bodySize * 1.6)
            Text(text)
                .font(AppTheme.rounded(m.captionSize + 2, .bold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func gateOverlay(_ question: ParentalGateQuestion) -> some View {
        ZStack {
            // Tikken om te sluiten is een extraatje voor ziende gebruikers;
            // VoiceOver krijgt de opties op de kaart, niet dit vlak.
            AppTheme.ink.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { closeGate() }
                .accessibilityHidden(true)

            VStack(spacing: m.gutter * 0.8) {
                Text("Vraag even aan papa of mama")
                    .font(AppTheme.rounded(m.bodySize + 2))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)

                Text(question.text)
                    .font(AppTheme.rounded(m.titleSize * 0.6))
                    .foregroundStyle(AppTheme.coral)

                HStack(spacing: m.gutter * 0.7) {
                    ForEach(question.options, id: \.self) { option in
                        Button {
                            answerGate(with: option, question: question)
                        } label: {
                            Text("\(option)")
                                .font(AppTheme.rounded(m.bodySize + 2))
                                .foregroundStyle(AppTheme.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: m.tapTarget)
                        }
                        .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cellCorner, depth: 3, border: m.thinBorder))
                    }
                }
            }
            .padding(m.gutter * 1.4)
            .toyBlock(fill: AppTheme.card, radius: m.cardCorner + 4, depth: m.depth + 1, border: m.border)
            .frame(maxWidth: m.overlayMaxWidth * 0.82)
            .padding(m.gutter * 2)
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity)
    }

    private func askParent(_ action: @escaping () async -> Void) {
        pendingAction = action
        withAnimation(.easeOut(duration: 0.15)) {
            gateQuestion = .make()
        }
    }

    private func answerGate(with option: Int, question: ParentalGateQuestion) {
        guard option == question.answer else {
            // Fout: nieuwe vraag, zodat gokken niet loont.
            gateQuestion = .make()
            return
        }
        let action = pendingAction
        closeGate()
        isBusy = true
        Task {
            await action?()
            isBusy = false
        }
    }

    private func closeGate() {
        withAnimation(.easeOut(duration: 0.15)) {
            gateQuestion = nil
        }
        pendingAction = nil
    }

    /// Annuleren is een keuze en blijft stil; mislukken en wachten-op-ouder
    /// verdienen uitleg — anders lijkt de knop gewoon kapot.
    private func purchase() async {
        switch await entitlements.purchaseFamily() {
        case .success, .cancelled:
            break
        case .pending:
            showNotice(String(localized: "De aankoop wacht nog op goedkeuring van een ouder."))
        case .failed:
            showNotice(String(localized: "Kopen is niet gelukt. Controleer de internetverbinding en probeer het straks nog eens."))
        }
    }

    private func showNotice(_ text: String) {
        withAnimation(.easeOut(duration: 0.15)) {
            purchaseNotice = text
        }
    }

    private func dismissNotice() {
        withAnimation(.easeOut(duration: 0.15)) {
            purchaseNotice = nil
        }
    }
}

#Preview {
    PaywallView(entitlements: EntitlementStore(previewUnlocked: false))
        .appMetrics()
}
