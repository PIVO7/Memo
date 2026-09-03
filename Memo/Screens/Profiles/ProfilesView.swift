import SwiftUI

struct ProfilesView: View {
    @Environment(ProfileStore.self) private var profileStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.metrics) private var m
    @State private var showNewProfile = false
    /// Het profiel dat op de verwijderbevestiging wacht.
    @State private var deletingProfile: PlayerProfile?

    /// Op een iPad past er een tweede kolom naast; op een iPhone niet.
    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: m.gutter), count: count)
    }

    var body: some View {
        ZStack {
            ThemedBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: m.gutter * 1.5) {
                    // Eén knop die naar de volledige editor leidt: naam,
                    // kleur en symbool in één keer, in plaats van een los
                    // naamveld waarna niemand de avatarkiezer nog vond.
                    NewProfileButton { showNewProfile = true }

                    section("SPELERS") {
                        if profileStore.humanProfiles.isEmpty {
                            Text("Nog geen profielen. Maak er een aan om te spelen.")
                                .font(AppTheme.rounded(m.bodySize, .bold))
                                .foregroundStyle(AppTheme.cardSoft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(m.gutter)
                                .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
                        } else {
                            LazyVGrid(columns: columns, spacing: m.gutter) {
                                ForEach(profileStore.humanProfiles) { profile in
                                    ProfileRowView(
                                        profile: profile,
                                        onEdit: { profileStore.updateProfile(id: profile.id, name: $0, colorIndex: $1, symbol: $2) },
                                        onDelete: {
                                            withAnimation(.easeOut(duration: 0.15)) {
                                                deletingProfile = profile
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // Records vergelijken heeft pas zin met z'n tweeën.
                    if profileStore.humanProfiles.count >= 2 {
                        section("GEZIN") {
                            NavigationLink(value: Destination.familyRecords) {
                                HStack(spacing: m.gutter * 0.9) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: m.bodySize + 2, weight: .black))
                                        .foregroundStyle(AppTheme.amber)
                                        .frame(width: m.avatarSize, height: m.avatarSize)
                                        .background(Circle().fill(AppTheme.tintAmber))
                                        .overlay { Circle().strokeBorder(AppTheme.ink, lineWidth: m.thinBorder + 0.5) }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Gezinsrecords")
                                            .font(AppTheme.rounded(m.bodySize + 2))
                                            .foregroundStyle(AppTheme.ink)
                                        Text("Wie heeft het record in huis?")
                                            .font(AppTheme.rounded(m.captionSize, .bold))
                                            .foregroundStyle(AppTheme.cardSoft)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: m.bodySize * 0.9, weight: .black))
                                        .foregroundStyle(AppTheme.cardDim)
                                }
                                .padding(m.gutter * 0.9)
                                .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, m.gutter * 1.3)
                .padding(.top, 8)
                .padding(.bottom, m.gutter * 2)
                .frame(maxWidth: m.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }

            // Eigen dialoog in de speelgoedstijl in plaats van het grijze
            // systeempaneel.
            if let profile = deletingProfile {
                ToyDialog(
                    title: String(localized: "\(profile.name) verwijderen?"),
                    message: String(localized: "De overwinningen van dit profiel gaan verloren."),
                    confirmTitle: String(localized: "Verwijderen"),
                    cancelTitle: String(localized: "Annuleer"),
                    onConfirm: {
                        profileStore.deleteProfile(id: profile.id)
                        deletingProfile = nil
                    },
                    onCancel: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            deletingProfile = nil
                        }
                    }
                )
                .zIndex(5)
            }
        }
        .navigationTitle("Profielen")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNewProfile) {
            ProfileEditorView(
                profile: nil,
                // Elke nieuwe speler start alvast met een eigen kleur.
                suggestedColorIndex: profileStore.humanProfiles.count % PlayerProfile.avatarPaletteCount,
                onSave: { name, colorIndex, symbol in
                    profileStore.addProfile(name: name, colorIndex: colorIndex, symbol: symbol)
                }
            )
            .appMetrics()
        }
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

/// De grote aanmaakknop bovenaan de profielenlijst. Een eigen struct zodat
/// de render-rooktest hem samen met de rijen kan stapelen.
struct NewProfileButton: View {
    let action: () -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        Button(action: action) {
            Label("Nieuw profiel", systemImage: "plus")
                .font(AppTheme.rounded(m.bodySize + 1))
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(minHeight: m.compactButton.height)
        }
        .buttonStyle(ToyButtonStyle(
            fill: AppTheme.mint,
            radius: m.buttonCorner,
            depth: m.depth,
            border: m.border
        ))
    }
}

#Preview {
    // Tijdelijk bestand, zodat de preview nooit aan echte spelersdata komt.
    let profiles = ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json"))
    let _ = profiles.addProfile(name: "Lene")
    let _ = profiles.addProfile(name: "Ellis")

    NavigationStack {
        ProfilesView()
    }
    .environment(profiles)
    .environment(EntitlementStore(previewUnlocked: true))
    .appMetrics()
}
