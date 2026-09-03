import SwiftUI

/// Eén scherm voor het hele profiel: naam, kleur en symbool samen. Dient
/// zowel voor een nieuw profiel als voor het aanpassen van een bestaand —
/// zo ziet iedereen bij het aanmaken meteen dat er naast de naam ook een
/// kleur en een symbooltje te kiezen valt.
struct ProfileEditorView: View {
    /// Nil bij een nieuw profiel.
    let profile: PlayerProfile?
    let onSave: (String, Int, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m

    @State private var name: String
    @State private var colorIndex: Int
    @State private var symbol: String?

    /// - Parameter suggestedColorIndex: startkleur voor een nieuw profiel,
    ///   zodat elke nieuwe speler alvast een eigen kleur krijgt.
    init(
        profile: PlayerProfile?,
        suggestedColorIndex: Int = 0,
        onSave: @escaping (String, Int, String?) -> Void
    ) {
        self.profile = profile
        self.onSave = onSave
        _name = State(initialValue: profile?.name ?? "")
        _colorIndex = State(initialValue: profile?.avatarColorIndex ?? suggestedColorIndex)
        _symbol = State(initialValue: profile?.avatarSymbol)
    }

    var body: some View {
        ZStack {
            ThemedBackground()

            ScrollView {
                ProfileEditorFormView(name: $name, colorIndex: $colorIndex, symbol: $symbol)
                    .padding(.horizontal, m.gutter * 1.4)
                    .padding(.bottom, m.gutter)
                    .frame(maxWidth: m.overlayMaxWidth)
                    .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: saveAndClose) {
                Text("Klaar!")
                    .font(AppTheme.rounded(m.defaultButton.textSize))
                    .foregroundStyle(canSave ? AppTheme.ink : AppTheme.offInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.defaultButton.height)
            }
            .buttonStyle(ToyButtonStyle(
                fill: canSave ? AppTheme.mint : AppTheme.offFill,
                radius: m.buttonCorner,
                depth: m.defaultButton.depth,
                border: m.border,
                borderColor: canSave ? AppTheme.ink : AppTheme.offInk
            ))
            .disabled(!canSave)
            .padding(.horizontal, m.gutter * 1.4)
            .padding(.bottom, m.gutter)
            .frame(maxWidth: m.overlayMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveAndClose() {
        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), colorIndex, symbol)
        dismiss()
    }
}

/// De invulvelden van de profieleditor: het meelevende bolletje met daaronder
/// naam, kleur en symbool. Los van de ScrollView zodat de render-rooktest
/// precies dit kan stapelen (ImageRenderer kan geen ScrollView aan).
struct ProfileEditorFormView: View {
    @Binding var name: String
    @Binding var colorIndex: Int
    @Binding var symbol: String?
    /// ImageRenderer kan het echte tekstveld niet renderen; de rooktest zet
    /// dit aan voor een statische naamregel in dezelfde opmaak.
    var staticNameForRender = false

    @Environment(\.metrics) private var m

    /// Kindvriendelijke symbolen met een uitspreekbare naam; de eerste keuze
    /// is "gewoon je letters".
    static let symbols: [(name: String, label: String)] = [
        ("cat.fill", String(localized: "Kat")), ("dog.fill", String(localized: "Hond")),
        ("hare.fill", String(localized: "Haas")), ("tortoise.fill", String(localized: "Schildpad")),
        ("bird.fill", String(localized: "Vogel")), ("fish.fill", String(localized: "Vis")),
        ("ladybug.fill", String(localized: "Lieveheersbeestje")), ("pawprint.fill", String(localized: "Pootafdruk")),
        ("star.fill", String(localized: "Ster")), ("heart.fill", String(localized: "Hart")),
        ("basketball.fill", String(localized: "Basketbal")),
        ("bolt.fill", String(localized: "Bliksem")), ("crown.fill", String(localized: "Kroon")),
        ("sun.max.fill", String(localized: "Zon")), ("moon.stars.fill", String(localized: "Maan")),
        ("flame.fill", String(localized: "Vlam")), ("leaf.fill", String(localized: "Blad"))
    ]

    private static let colorNames = [
        String(localized: "Koraal"), String(localized: "Blauw"), String(localized: "Geel"),
        String(localized: "Mint"), String(localized: "Paars"), String(localized: "Oranje"),
        String(localized: "Roze")
    ]

    var body: some View {
        VStack(spacing: m.gutter) {
            // Het bolletje leeft mee met elke keuze hieronder.
            AvatarBadge(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                colorIndex: colorIndex,
                symbol: symbol,
                size: m.avatarSize * 1.6
            )
            .padding(.top, m.gutter * 1.4)

            sectionTitle("NAAM")
            Group {
                if staticNameForRender {
                    Text(name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    TextField(
                        "Naam van je kind",
                        text: $name,
                        // Eigen promptkleur: de systeemplaceholder kleurt met
                        // het toestelschema mee en werd in donkere modus wit
                        // op de witte kaart.
                        prompt: Text("Naam van je kind").foregroundStyle(AppTheme.ink.opacity(0.42))
                    )
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                }
            }
            .font(AppTheme.rounded(m.bodySize, .bold))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, m.gutter)
            .frame(minHeight: m.tapTarget + 8)
            .toyBlock(fill: AppTheme.card, radius: m.cellCorner, depth: m.shallowDepth, border: m.thinBorder + 0.5)

            sectionTitle("KLEUR")
            // Kleine vaste tussenruimte en flexibele cellen: zo passen ook
            // zeven bolletjes naast elkaar op een iPhone.
            HStack(spacing: 6) {
                ForEach(Array(AvatarBadge.palette.enumerated()), id: \.offset) { index, color in
                    colorCell(index: index, color: color)
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
        }
    }

    private func colorCell(index: Int, color: Color) -> some View {
        Button {
            colorIndex = index
        } label: {
            Circle()
                .fill(color)
                .overlay {
                    // De ring in `headline` en niet `ink`: in het nachtthema
                    // is inkt onzichtbaar op de donkere achtergrond.
                    Circle().strokeBorder(
                        colorIndex == index ? AppTheme.headline : AppTheme.ink,
                        lineWidth: colorIndex == index ? 3.5 : 1.5
                    )
                }
                .overlay {
                    if colorIndex == index {
                        Image(systemName: "checkmark")
                            .font(.system(size: m.captionSize + 2, weight: .black))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 0, x: 0, y: 1.5)
                    }
                }
                .frame(width: m.tapTarget * 0.8, height: m.tapTarget * 0.8)
                .scaleEffect(colorIndex == index ? 1.12 : 1)
                // Het bolletje blijft visueel klein, maar het tikvlak vult
                // de hele beschikbare celbreedte.
                .frame(maxWidth: .infinity, minHeight: m.tapTarget)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.12), value: colorIndex)
        .accessibilityLabel(String(localized: "Kleur \(Self.colorNames[index % Self.colorNames.count])"))
        .accessibilityAddTraits(colorIndex == index ? .isSelected : [])
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
            fill: picked ? AppTheme.tintCoral : AppTheme.card,
            radius: m.cellCorner,
            depth: m.shallowDepth,
            border: m.thinBorder,
            borderColor: picked ? AppTheme.coral : AppTheme.ink
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

#Preview("Nieuw profiel") {
    ProfileEditorView(profile: nil, suggestedColorIndex: 2, onSave: { _, _, _ in })
        .appMetrics()
}

#Preview("Bestaand profiel") {
    ProfileEditorView(
        profile: PlayerProfile(name: "Lene", avatarColorIndex: 0, avatarSymbol: "cat.fill"),
        onSave: { _, _, _ in }
    )
    .appMetrics()
}
