import SwiftUI

/// Eén profiel in de lijst, met de knoppen om te hernoemen of te verwijderen.
/// De rij houdt zijn eigen dialoogtoestand bij: bij gedeelde toestand zou elke
/// rij dezelfde vlag volgen en zouden er meerdere dialogen tegelijk openen.
struct ProfileRowView: View {
    let profile: PlayerProfile
    let onRename: (String) -> Void
    let onDelete: () -> Void
    let onAvatarChange: (Int, String?) -> Void

    @Environment(\.metrics) private var m
    @State private var renameText = ""
    @State private var isRenaming = false
    @State private var isDeleting = false
    @State private var showAvatarPicker = false

    var body: some View {
        HStack(spacing: m.gutter * 0.9) {
            // Tik op het bolletje om het aan te passen; op de naam voor de
            // statistieken.
            Button {
                showAvatarPicker = true
            } label: {
                AvatarBadge(profile: profile, size: m.avatarSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Avatar van \(profile.name) aanpassen")
            .sheet(isPresented: $showAvatarPicker) {
                AvatarPickerView(profile: profile, onSave: onAvatarChange)
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
            .buttonStyle(.plain)
            .accessibilityHint("Toont de statistieken")

            renameButton
            deleteButton
        }
        .padding(m.gutter * 0.9)
        .toyBlock(fill: AppTheme.card, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
    }

    private var renameButton: some View {
        Button(action: beginRename) {
            // Een Label en geen kale Image: de titel voedt VoiceOver én
            // Voice Control, ook al toont de knop alleen het icoon.
            Label("\(profile.name) hernoemen", systemImage: "pencil")
                .labelStyle(.iconOnly)
                .font(.system(size: m.captionSize + 2, weight: .black))
                .foregroundStyle(AppTheme.ink)
                .frame(width: m.tapTarget, height: m.tapTarget)
        }
        .buttonStyle(ToyButtonStyle(fill: AppTheme.tintAmber, radius: m.cellCorner, depth: 3, border: m.thinBorder))
        // De dialoog hangt aan de knop die hem opent, niet aan het scherm,
        // zodat de animatie vanaf de juiste plek vertrekt.
        .alert("Naam wijzigen", isPresented: $isRenaming) {
            TextField("Naam", text: $renameText)
            Button("Bewaar") { onRename(renameText) }
            Button("Annuleer", role: .cancel) {}
        }
    }

    private var deleteButton: some View {
        Button(action: beginDelete) {
            Label("\(profile.name) verwijderen", systemImage: "trash")
                .labelStyle(.iconOnly)
                .font(.system(size: m.captionSize + 2, weight: .black))
                .foregroundStyle(AppTheme.ink)
                .frame(width: m.tapTarget, height: m.tapTarget)
        }
        .buttonStyle(ToyButtonStyle(fill: AppTheme.tintCoral, radius: m.cellCorner, depth: 3, border: m.thinBorder))
        .confirmationDialog(
            "\(profile.name) verwijderen?",
            isPresented: $isDeleting,
            titleVisibility: .visible
        ) {
            Button("Verwijderen", role: .destructive, action: onDelete)
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("De overwinningen van dit profiel gaan verloren.")
        }
    }

    private func beginRename() {
        renameText = profile.name
        isRenaming = true
    }

    private func beginDelete() {
        isDeleting = true
    }
}

#Preview {
    ProfileRowView(
        profile: PlayerProfile(name: "Lene", wins: 3, gamesPlayed: 7),
        onRename: { _ in },
        onDelete: {},
        onAvatarChange: { _, _ in }
    )
    .environment(EntitlementStore(previewUnlocked: true))
    .padding()
    .background(AppTheme.cream)
}
