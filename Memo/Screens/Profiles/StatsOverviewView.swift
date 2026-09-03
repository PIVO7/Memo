import SwiftUI

/// De statistieken-etalage achter de starttegel: de spelers om door te
/// tikken naar hun eigen pagina, en daaronder de gezinsrecords. Zo zijn de
/// trofeeën en records vanaf het startscherm in één tik te vinden.
struct StatsOverviewView: View {
    @Environment(ProfileStore.self) private var profileStore
    @Environment(\.metrics) private var m

    var body: some View {
        ZStack {
            ThemedBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: m.gutter * 1.5) {
                    if profileStore.humanProfiles.isEmpty {
                        emptyCard
                    } else {
                        section("SPELERS") {
                            VStack(spacing: m.gutter * 0.6) {
                                ForEach(profileStore.humanProfiles) { profile in
                                    playerRow(profile)
                                }
                            }
                        }

                        // Records vergelijken heeft pas zin met z'n tweeën.
                        if profileStore.humanProfiles.count >= 2 {
                            section("GEZIN") {
                                familyRow
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
        .navigationTitle("Statistieken")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func playerRow(_ profile: PlayerProfile) -> some View {
        NavigationLink(value: Destination.stats(profile.id)) {
            HStack(spacing: m.gutter * 0.9) {
                AvatarBadge(profile: profile, size: m.avatarSize)

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

                Image(systemName: "chevron.right")
                    .font(.system(size: m.bodySize * 0.9, weight: .black))
                    .foregroundStyle(AppTheme.cardDim)
            }
            .padding(m.gutter * 0.9)
            .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Toont de statistieken")
    }

    private var familyRow: some View {
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

    private var emptyCard: some View {
        VStack(spacing: m.gutter) {
            Text("Nog geen profielen. Maak er een aan om te spelen.")
                .font(AppTheme.rounded(m.bodySize, .bold))
                .foregroundStyle(AppTheme.cardSoft)
                .frame(maxWidth: .infinity, alignment: .leading)

            NavigationLink(value: Destination.profiles) {
                Text("Naar profielen")
                    .font(AppTheme.rounded(m.compactButton.textSize))
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.compactButton.height)
            }
            .buttonStyle(ToyButtonStyle(
                fill: AppTheme.mint,
                radius: m.buttonCorner,
                depth: m.depth,
                border: m.border
            ))
        }
        .padding(m.gutter)
        .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
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
    let profiles = ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json"))
    let _ = profiles.addProfile(name: "Lene")
    let _ = profiles.addProfile(name: "Ellis")

    NavigationStack {
        StatsOverviewView()
    }
    .environment(profiles)
    .environment(EntitlementStore(previewUnlocked: true))
    .appMetrics()
}
