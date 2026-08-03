import SwiftUI

/// De avatarkiezer: een kleur en een symbooltje voor op je bolletje — half
/// de fun van een eigen profiel.
struct AvatarPickerView: View {
    let profile: PlayerProfile
    let onSave: (Int, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m

    @State private var colorIndex: Int
    @State private var symbol: String?

    /// Kindvriendelijke symbolen met een uitspreekbare naam; de eerste keuze
    /// is "gewoon je letters".
    static let symbols: [(name: String, label: String)] = [
        ("cat.fill", String(localized: "Kat")), ("dog.fill", String(localized: "Hond")),
        ("hare.fill", String(localized: "Haas")), ("tortoise.fill", String(localized: "Schildpad")),
        ("bird.fill", String(localized: "Vogel")), ("fish.fill", String(localized: "Vis")),
        ("ladybug.fill", String(localized: "Lieveheersbeestje")), ("pawprint.fill", String(localized: "Pootafdruk")),
        ("star.fill", String(localized: "Ster")), ("heart.fill", String(localized: "Hart")),
        ("bolt.fill", String(localized: "Bliksem")), ("crown.fill", String(localized: "Kroon")),
        ("sun.max.fill", String(localized: "Zon")), ("moon.stars.fill", String(localized: "Maan")),
        ("flame.fill", String(localized: "Vlam")), ("leaf.fill", String(localized: "Blad"))
    ]

    private static let colorNames = [
        String(localized: "Koraal"), String(localized: "Blauw"), String(localized: "Geel"),
        String(localized: "Mint"), String(localized: "Paars"), String(localized: "Oranje")
    ]

    init(profile: PlayerProfile, onSave: @escaping (Int, String?) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _colorIndex = State(initialValue: profile.avatarColorIndex)
        _symbol = State(initialValue: profile.avatarSymbol)
    }

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            VStack(spacing: m.gutter) {
                AvatarBadge(name: profile.name, colorIndex: colorIndex, symbol: symbol, size: m.avatarSize * 1.6)
                    .padding(.top, m.gutter * 1.4)

                Text(profile.name)
                    .font(AppTheme.rounded(m.titleSize * 0.55))
                    .foregroundStyle(AppTheme.headline)

                sectionTitle("KLEUR")
                HStack(spacing: m.gutter * 0.7) {
                    ForEach(Array(AvatarBadge.palette.enumerated()), id: \.offset) { index, color in
                        Button {
                            colorIndex = index
                        } label: {
                            Circle()
                                .fill(color)
                                .overlay {
                                    Circle().strokeBorder(
                                        AppTheme.ink,
                                        lineWidth: colorIndex == index ? 3.5 : 1.5
                                    )
                                }
                                .frame(width: m.tapTarget * 0.8, height: m.tapTarget * 0.8)
                                .scaleEffect(colorIndex == index ? 1.12 : 1)
                                // Het bolletje blijft visueel klein, maar het
                                // tikvlak haalt de 44-puntsgrens.
                                .frame(minWidth: m.tapTarget, minHeight: m.tapTarget)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .animation(.easeOut(duration: 0.12), value: colorIndex)
                        .accessibilityLabel(String(localized: "Kleur \(Self.colorNames[index % Self.colorNames.count])"))
                        .accessibilityAddTraits(colorIndex == index ? .isSelected : [])
                    }
                }

                sectionTitle("SYMBOOL")
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                    spacing: 8
                ) {
                    symbolCell(nil, label: String(localized: "Initialen"))
                    ForEach(Self.symbols, id: \.name) { symbol in
                        symbolCell(symbol.name, label: symbol.label)
                    }
                }

                Spacer(minLength: 0)

                Button {
                    onSave(colorIndex, symbol)
                    dismiss()
                } label: {
                    Text("Klaar!")
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
                .padding(.bottom, m.gutter)
            }
            .padding(.horizontal, m.gutter * 1.4)
            .frame(maxWidth: m.overlayMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private func symbolCell(_ name: String?, label: String) -> some View {
        let picked = symbol == name
        return Button {
            symbol = name
        } label: {
            Group {
                if let name {
                    Image(systemName: name)
                        .font(.system(size: m.bodySize + 2, weight: .black))
                } else {
                    Text("ABC")
                        .font(AppTheme.rounded(m.captionSize * 0.9))
                }
            }
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: m.tapTarget)
        }
        .buttonStyle(ToyButtonStyle(
            fill: picked ? AppTheme.coral : .white,
            radius: m.cellCorner,
            depth: picked ? 3 : 2,
            border: m.thinBorder
        ))
        .accessibilityLabel(label)
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(AppTheme.rounded(m.captionSize * 0.9))
            .kerning(1.4)
            .foregroundStyle(AppTheme.faint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, m.gutter * 0.4)
    }
}

#Preview {
    AvatarPickerView(
        profile: PlayerProfile(name: "Lene", avatarColorIndex: 0, avatarSymbol: "cat.fill"),
        onSave: { _, _ in }
    )
    .appMetrics()
}
