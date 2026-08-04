import SwiftUI

/// De spelregels op kindhoogte: hoe een beurt werkt en hoe je wint.
struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m

    var body: some View {
        ZStack {
            ThemedBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: m.gutter * 1.4) {
                    HStack {
                        Text("Hoe werkt het?")
                            .font(AppTheme.rounded(m.titleSize * 0.62))
                            .foregroundStyle(AppTheme.headline)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Label("Sluiten", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                                .font(.system(size: m.captionSize + 2, weight: .black))
                                .foregroundStyle(AppTheme.ink)
                                .frame(width: m.tapTarget, height: m.tapTarget)
                        }
                        .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cellCorner, depth: 3, border: m.thinBorder))
                    }

                    section("ZO SPEEL JE") {
                        card {
                            bullet("hand.tap.fill", String(localized: "Draai twee kaartjes om. Zelfde plaatje? Dan is het paar voor jou!"))
                            bullet("arrow.clockwise", String(localized: "Een paar gevonden? Dan mag je meteen nog een keer."))
                            bullet("arrow.triangle.2.circlepath", String(localized: "Geen paar? De kaartjes gaan weer dicht en de ander mag."))
                        }
                    }

                    section("ZO WIN JE") {
                        card {
                            bullet("checkmark.circle.fill", String(localized: "Zijn alle kaartjes op? Dan telt iedereen zijn paren."))
                            bullet("crown.fill", String(localized: "Wie de meeste paren heeft, wint het potje."))
                            bullet("equal.circle.fill", String(localized: "Evenveel paren? Dan is het gelijkspel."))
                        }
                    }

                    section("SLIMME TRUCJES") {
                        card {
                            bullet("brain.head.profile", String(localized: "Onthoud goed wáár een kaartje lag — daar draait alles om."))
                            bullet("eye.fill", String(localized: "Kijk ook mee als de ander draait: dat zijn gratis hints!"))
                            bullet("sparkle.magnifyingglass", String(localized: "Begin met kaartjes die nog niemand heeft gezien; zo leer je het bord kennen."))
                        }
                    }
                }
                .padding(.horizontal, m.gutter * 1.3)
                .padding(.top, m.gutter)
                .padding(.bottom, m.gutter * 2)
                .frame(maxWidth: m.overlayMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func section(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: m.gutter * 0.6) {
            Text(title)
                .font(AppTheme.rounded(m.captionSize * 0.9))
                .kerning(1.4)
                .foregroundStyle(AppTheme.faint)
            content()
        }
    }

    private func card(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: m.gutter * 0.9) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(m.gutter)
        .toyBlock(fill: AppTheme.card, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
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
}

#Preview {
    RulesView()
        .appMetrics()
}
