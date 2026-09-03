import SwiftUI

/// Eén profiel in de lijst. Het potloodje (en een tik op het bolletje) opent
/// de profieleditor voor naam, kleur en symbool tegelijk; de verwijdervraag
/// stelt de lijst zelf, in de eigen ToyDialog in plaats van het systeempaneel.
struct ProfileRowView: View {
    let profile: PlayerProfile
    /// Naam, kleurindex en symbool uit de editor, in die volgorde.
    let onEdit: (String, Int, String?) -> Void
    /// Vraagt de lijst om de verwijderbevestiging te tonen.
    let onDelete: () -> Void

    @Environment(\.metrics) private var m
    @State private var showEditor = false

    var body: some View {
        HStack(spacing: m.gutter * 0.9) {
            // Tik op het bolletje om het profiel aan te passen; op de naam
            // voor de statistieken.
            Button {
                showEditor = true
            } label: {
                AvatarBadge(profile: profile, size: m.avatarSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profiel van \(profile.name) aanpassen")
            .sheet(isPresented: $showEditor) {
                ProfileEditorView(profile: profile, onSave: onEdit)
                    .appMetrics()
            }

            NavigationLink(value: Destination.stats(profile.id)) {
                HStack(spacing: m.gutter * 0.9) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(AppTheme.rounded(m.bodySize + 2))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                        Text("\(profile.wins)× gewonnen · \(profile.gamesPlayed) gespeeld")
                            .font(AppTheme.rounded(m.captionSize, .bold))
                            .foregroundStyle(AppTheme.cardSoft)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(RowLinkStyle())
            .accessibilityHint("Toont de statistieken")

            editButton
            deleteButton
        }
        .padding(m.gutter * 0.9)
        .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
    }

    private var editButton: some View {
        Button {
            showEditor = true
        } label: {
            // Een Label en geen kale Image: de titel voedt VoiceOver én
            // Voice Control, ook al toont de knop alleen het icoon.
            Label("Profiel van \(profile.name) aanpassen", systemImage: "pencil")
                .labelStyle(.iconOnly)
                .font(.system(size: m.captionSize + 2, weight: .black))
                .foregroundStyle(AppTheme.ink)
                .frame(width: m.tapTarget, height: m.tapTarget)
        }
        .buttonStyle(ToyButtonStyle(fill: AppTheme.tintAmber, radius: m.cellCorner, depth: m.shallowDepth, border: m.thinBorder))
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Label("\(profile.name) verwijderen", systemImage: "trash")
                .labelStyle(.iconOnly)
                .font(.system(size: m.captionSize + 2, weight: .black))
                .foregroundStyle(AppTheme.ink)
                .frame(width: m.tapTarget, height: m.tapTarget)
        }
        .buttonStyle(ToyButtonStyle(fill: AppTheme.tintCoral, radius: m.cellCorner, depth: m.shallowDepth, border: m.thinBorder))
    }

    /// Zonder de automatische dim van de systeemknop: in de render-rooktest
    /// staat de rij buiten een NavigationStack en zou de naam er anders
    /// uitgegrijsd bijstaan.
    private struct RowLinkStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .opacity(configuration.isPressed ? 0.55 : 1)
        }
    }
}

#Preview {
    ProfileRowView(
        profile: PlayerProfile(name: "Lene", wins: 3, gamesPlayed: 7),
        onEdit: { _, _, _ in },
        onDelete: {}
    )
    .environment(EntitlementStore(previewUnlocked: true))
    .padding()
    .background(AppTheme.cream)
}
