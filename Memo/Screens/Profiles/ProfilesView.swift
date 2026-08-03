import SwiftUI

struct ProfilesView: View {
    @Environment(ProfileStore.self) private var profileStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.metrics) private var m
    @State private var newName = ""

    /// Op een iPad past er een tweede kolom naast; op een iPhone niet.
    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: m.gutter), count: count)
    }

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: m.gutter * 1.5) {
                    section("NIEUW PROFIEL") {
                        HStack(spacing: 10) {
                            TextField("Naam van je kind", text: $newName)
                                .font(AppTheme.rounded(m.bodySize, .bold))
                                .foregroundStyle(AppTheme.ink)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .onSubmit(addProfile)

                            Button("Voeg toe", action: addProfile)
                                .font(AppTheme.rounded(m.captionSize, .bold))
                                .foregroundStyle(canAdd ? AppTheme.ink : AppTheme.offInk)
                                .padding(.horizontal, 14)
                                .frame(minHeight: m.tapTarget)
                                .toyBlock(
                                    fill: canAdd ? AppTheme.mint : AppTheme.offFill,
                                    radius: m.cellCorner + 1,
                                    depth: 3,
                                    border: m.thinBorder + 0.5,
                                    borderColor: canAdd ? AppTheme.ink : AppTheme.offInk,
                                    shadowColor: canAdd ? AppTheme.ink : AppTheme.offInk
                                )
                                .disabled(!canAdd)
                        }
                        .padding(m.gutter)
                        .toyBlock(fill: .white, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
                    }

                    section("SPELERS") {
                        if profileStore.humanProfiles.isEmpty {
                            Text("Nog geen profielen. Maak er een aan om te spelen.")
                                .font(AppTheme.rounded(m.bodySize, .bold))
                                .foregroundStyle(AppTheme.soft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(m.gutter)
                                .toyBlock(fill: .white, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
                        } else {
                            LazyVGrid(columns: columns, spacing: m.gutter) {
                                ForEach(profileStore.humanProfiles) { profile in
                                    ProfileRowView(
                                        profile: profile,
                                        onRename: { profileStore.renameProfile(id: profile.id, to: $0) },
                                        onDelete: { profileStore.deleteProfile(id: profile.id) },
                                        onAvatarChange: { profileStore.updateAvatar(id: profile.id, colorIndex: $0, symbol: $1) }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, m.gutter * 1.3)
                .padding(.top, 8)
                .padding(.bottom, m.gutter * 2)
                .frame(maxWidth: m.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Profielen")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canAdd: Bool {
        !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addProfile() {
        guard canAdd else { return }
        profileStore.addProfile(name: newName)
        newName = ""
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
