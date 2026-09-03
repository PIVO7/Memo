import SwiftUI

/// Instellingen: het thema en het geluid. Bewust klein gehouden — een
/// kinderapp hoort weinig knoppen te hebben.
struct SettingsView: View {
    let entitlements: EntitlementStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m

    @State private var soundOn = SoundPlayer.shared.isEnabled
    @State private var showRules = false
    @State private var showPaywall = false
    /// Het thema waar de proefvraag over gaat.
    @State private var trialCandidate: ThemeID?

    private var themeStore: ThemeStore { .shared }

    var body: some View {
        ZStack {
            ThemedBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: m.gutter * 1.4) {
                    HStack {
                        Text("Instellingen")
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

                    section("THEMA") {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: m.gutter), GridItem(.flexible(), spacing: m.gutter)],
                            spacing: m.gutter
                        ) {
                            ForEach(ThemeID.allCases) { theme in
                                themeCard(theme)
                            }
                        }
                    }

                    section("GELUID") {
                        Toggle(isOn: $soundOn) {
                            Text("Geluidseffecten")
                                .font(AppTheme.rounded(m.bodySize, .bold))
                                .foregroundStyle(AppTheme.ink)
                        }
                        .toggleStyle(ToyToggleStyle())
                        .padding(m.gutter)
                        .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
                        .onChange(of: soundOn) { _, isOn in
                            SoundPlayer.shared.isEnabled = isOn
                            if isOn {
                                SoundPlayer.shared.play(.drop)
                            }
                        }
                    }

                    section("UITLEG") {
                        Button {
                            showRules = true
                        } label: {
                            HStack {
                                Text("Hoe werkt Memo?")
                                    .font(AppTheme.rounded(m.bodySize, .bold))
                                    .foregroundStyle(AppTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "book.fill")
                                    .font(.system(size: m.bodySize, weight: .black))
                                    .foregroundStyle(AppTheme.sky)
                            }
                            .padding(m.gutter)
                        }
                        .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border))
                        .sheet(isPresented: $showRules) {
                            RulesView()
                                .appMetrics()
                        }
                        .sheet(isPresented: $showPaywall) {
                            PaywallView(entitlements: entitlements)
                                .appMetrics()
                        }
                    }

                    section("GEZINSVERSIE") {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Text(entitlements.isFamilyUnlocked
                                     ? LocalizedStringKey("Ontgrendeld — veel plezier!")
                                     : LocalizedStringKey("Alles ontgrendelen"))
                                    .font(AppTheme.rounded(m.bodySize, .bold))
                                    .foregroundStyle(AppTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: entitlements.isFamilyUnlocked ? "checkmark.seal.fill" : "figure.2.and.child.holdinghands")
                                    .font(.system(size: m.bodySize, weight: .black))
                                    .foregroundStyle(entitlements.isFamilyUnlocked ? AppTheme.mint : AppTheme.coral)
                            }
                            .padding(m.gutter)
                        }
                        .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border))
                    }
                }
                .padding(.horizontal, m.gutter * 1.3)
                .padding(.top, m.gutter)
                .padding(.bottom, m.gutter * 2)
                .frame(maxWidth: m.overlayMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .overlay {
            if let trialCandidate {
                trialDialog(for: trialCandidate)
            }
        }
    }

    /// Eerst proberen, dan kopen: één potje in het thema, daarna springt
    /// het vanzelf terug. De winkel volgt na dat potje.
    private func trialDialog(for theme: ThemeID) -> some View {
        ToyDialog(
            title: String(localized: "\(theme.title) proberen?"),
            message: String(localized: "Speel één potje in dit thema. Daarna springt het terug naar Klassiek."),
            confirmTitle: String(localized: "Probeer één potje"),
            cancelTitle: String(localized: "Niet nu"),
            onConfirm: {
                withAnimation(.easeOut(duration: 0.15)) {
                    trialCandidate = nil
                }
                themeStore.startTrial(theme)
            },
            onCancel: {
                withAnimation(.easeOut(duration: 0.15)) {
                    trialCandidate = nil
                }
            }
        )
    }

    /// Eén themakaart: de achtergrondkleur van het thema met zijn accenten
    /// als bolletjes, zodat je ziet wat je kiest voor je tikt.
    private func themeCard(_ theme: ThemeID) -> some View {
        let palette = theme.palette
        let picked = themeStore.activeThemeID == theme
        let locked = theme != .klassiek && !entitlements.isFamilyUnlocked

        return Button {
            if locked {
                // Eerst proberen, dan kopen; wie het al probeerde gaat naar
                // de winkel.
                if themeStore.canTry(theme) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        trialCandidate = theme
                    }
                } else {
                    showPaywall = true
                }
            } else {
                themeStore.select(theme)
            }
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(Array([palette.coral, palette.amber, palette.mint, palette.sky].enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .overlay { Circle().strokeBorder(palette.ink, lineWidth: 1.5) }
                            .frame(width: m.captionSize + 4, height: m.captionSize + 4)
                    }
                }

                Group {
                    if locked {
                        Label(theme.title, systemImage: "lock.fill")
                    } else {
                        Text(theme.title)
                    }
                }
                .font(AppTheme.rounded(m.captionSize + 1, .bold))
                .foregroundStyle(theme == .nacht ? palette.headline : palette.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, m.gutter * 0.9)
        }
        .buttonStyle(ToyButtonStyle(
            fill: palette.cream,
            radius: m.cardCorner,
            depth: picked ? m.depth : m.shallowDepth,
            border: m.border,
            borderColor: picked ? AppTheme.coral : AppTheme.ink
        ))
        .accessibilityLabel(
            locked
                ? String(localized: "Thema \(theme.title), Gezinsversie nodig")
                : String(localized: "Thema \(theme.title)")
        )
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    @ViewBuilder
    private func section<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppTheme.rounded(m.captionSize * 0.9))
                .kerning(1.4)
                .foregroundStyle(AppTheme.faint)
                .padding(.leading, 4)
            content()
        }
    }
}

#Preview {
    SettingsView(entitlements: EntitlementStore(previewUnlocked: false))
        .appMetrics()
}
