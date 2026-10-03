import SwiftUI

/// De privacyverklaring, gewoon in de app: de App Store eist een makkelijk
/// bereikbare verklaring, en bij een kinderapp is een pagina zónder externe
/// links de veiligste vorm. Het contactadres staat er als tekst — geen
/// tikbare link die een kind de app uit stuurt.
struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m

    var body: some View {
        ZStack {
            ThemedBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: m.gutter) {
                    HStack {
                        Text("Privacy en contact")
                            .font(AppTheme.rounded(m.titleSize * 0.7))
                            .foregroundStyle(AppTheme.headline)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Label("Sluiten", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                                .font(.system(size: m.captionSize + 2, weight: .black))
                                .foregroundStyle(AppTheme.ink)
                                .frame(width: m.tapTarget, height: m.tapTarget)
                        }
                        .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cellCorner, depth: m.shallowDepth, border: m.thinBorder))
                    }

                    VStack(alignment: .leading, spacing: m.gutter * 0.8) {
                        paragraph(
                            "iphone",
                            String(localized: "Alles blijft op dit toestel"),
                            String(localized: "Memo! werkt zonder account en zonder internet. Profielen, scores en instellingen worden alleen op dit toestel bewaard en verlaten het niet.")
                        )
                        paragraph(
                            "eye.slash.fill",
                            String(localized: "Niets dat meekijkt"),
                            String(localized: "Geen reclame, geen volgcodes, geen analyse door derden. Wij sturen geen gegevens naar eigen servers — die hebben we niet.")
                        )
                        paragraph(
                            "cart.fill",
                            String(localized: "Kopen via de App Store"),
                            String(localized: "De aankoop van de Gezinsversie loopt volledig via Apple. De app zelf ziet geen betaalgegevens.")
                        )
                        paragraph(
                            "trash.fill",
                            String(localized: "Wissen is wissen"),
                            String(localized: "Verwijder je de app, dan zijn ook alle spelersgegevens weg.")
                        )
                    }
                    .padding(m.gutter)
                    .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vragen?")
                            .font(AppTheme.rounded(m.captionSize + 2))
                            .foregroundStyle(AppTheme.ink)
                        Text(verbatim: "PIVO7 · jelle@pivo7.be")
                            .font(AppTheme.rounded(m.captionSize, .bold))
                            .foregroundStyle(AppTheme.cardSoft)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(m.gutter)
                    .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
                }
                .padding(.horizontal, m.gutter * 1.3)
                .padding(.top, m.gutter)
                .padding(.bottom, m.gutter * 2)
                .frame(maxWidth: m.overlayMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func paragraph(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: m.gutter * 0.6) {
            Image(systemName: icon)
                .font(.system(size: m.bodySize, weight: .black))
                .foregroundStyle(AppTheme.sky)
                .frame(width: m.bodySize * 1.6)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.rounded(m.captionSize + 2))
                    .foregroundStyle(AppTheme.ink)
                Text(body)
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.cardSoft)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PrivacyView()
        .appMetrics()
}
