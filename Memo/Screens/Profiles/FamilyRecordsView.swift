import SwiftUI

/// De gezinsrecords: wie het record heeft, per categorie. Bewust alleen
/// hoogtepunten — nooit wie ergens de minste in is.
struct FamilyRecordsView: View {
    @Environment(ProfileStore.self) private var profileStore
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.metrics) private var m

    @State private var showPaywall = false

    /// Alleen profielen die al gespeeld hebben doen mee.
    private var contenders: [PlayerProfile] {
        profileStore.humanProfiles.filter { $0.gamesPlayed > 0 }
    }

    var body: some View {
        ZStack {
            ThemedBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: m.gutter) {
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: m.titleSize * 0.9, weight: .black))
                            .foregroundStyle(AppTheme.amber)
                        Text("Gezinsrecords")
                            .font(AppTheme.rounded(m.titleSize * 0.6))
                            .foregroundStyle(AppTheme.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, m.gutter * 0.5)

                    if !entitlements.isFamilyUnlocked {
                        lockedCard
                    } else if contenders.isEmpty {
                        Text("Speel eerst een potje — daarna staan hier de records van het gezin.")
                            .font(AppTheme.rounded(m.bodySize, .bold))
                            .foregroundStyle(AppTheme.cardSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(m.gutter)
                            .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
                    } else {
                        recordRow(
                            title: String(localized: "Meeste overwinningen"),
                            icon: "crown.fill",
                            value: { $0.wins },
                            format: { String(localized: "\($0) keer gewonnen") }
                        )
                        recordRow(
                            title: String(localized: "Langste winreeks"),
                            icon: "flame.fill",
                            value: { $0.bestStreak },
                            format: { String(localized: "\($0) op rij") }
                        )
                        recordRow(
                            title: String(localized: "Meeste paren in één potje"),
                            icon: "square.fill.on.square.fill",
                            value: { $0.mostPairs },
                            format: { String(localized: "\($0) paren") }
                        )
                        recordRow(
                            title: String(localized: "Meeste potjes"),
                            icon: "rectangle.grid.2x2.fill",
                            value: { $0.gamesPlayed },
                            format: { String(localized: "\($0) potjes") }
                        )
                        // Tegen de klok wint juist de kléinste tijd, per bord.
                        ForEach(BoardSize.allCases) { size in
                            recordRow(
                                title: String(localized: "Snelste tijd · \(size.title)"),
                                icon: "stopwatch.fill",
                                value: { $0.bestTime(for: size) ?? 0 },
                                best: FamilyRecordMath.lowestPositive,
                                format: { ClockText.string(seconds: $0) }
                            )
                        }
                    }
                }
                .padding(.horizontal, m.gutter * 1.5)
                .padding(.bottom, m.gutter * 2)
                .frame(maxWidth: m.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Gezinsrecords")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(entitlements: entitlements)
                .appMetrics()
        }
    }

    /// Eén record: de titel, de recordhouder(s) met hun bolletje en de
    /// waarde. Bij een gelijke stand staan ze er allebei — samen een record
    /// hebben is ook leuk.
    @ViewBuilder
    private func recordRow(
        title: String,
        icon: String,
        value: (PlayerProfile) -> Int,
        best: @escaping ([Int]) -> Int? = { $0.max() },
        format: (Int) -> String
    ) -> some View {
        // De rekensom staat in FamilyRecordMath; een record van nul is nog
        // geen record en die rij wacht dan stilletjes.
        if let (best, holders) = FamilyRecordMath.record(in: contenders, value: value, best: best) {
            HStack(spacing: m.gutter * 0.8) {
                Image(systemName: icon)
                    .font(.system(size: m.bodySize, weight: .black))
                    .foregroundStyle(AppTheme.coral)
                    .frame(width: m.bodySize * 1.6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.rounded(m.captionSize, .bold))
                        .foregroundStyle(AppTheme.cardSoft)
                    Text(format(best))
                        .font(AppTheme.rounded(m.bodySize + 2))
                        .foregroundStyle(AppTheme.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: -m.avatarSize * 0.25) {
                    ForEach(holders) { holder in
                        AvatarBadge(profile: holder, size: m.avatarSize * 0.85)
                    }
                }
            }
            .padding(.horizontal, m.gutter)
            .padding(.vertical, m.gutter * 0.7)
            .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.shallowDepth, border: m.thinBorder + 0.5)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "\(title): \(format(best)), \(holders.map(\.name).formatted(.list(type: .and)))"
            )
        }
    }

    private var lockedCard: some View {
        VStack(spacing: m.gutter) {
            Image(systemName: "lock.fill")
                .font(.system(size: m.titleSize * 0.6, weight: .black))
                .foregroundStyle(AppTheme.offInk)

            Text("De gezinsrecords horen bij de Gezinsversie.")
                .font(AppTheme.rounded(m.captionSize + 2, .bold))
                .foregroundStyle(AppTheme.cardSoft)
                .multilineTextAlignment(.center)

            Button {
                showPaywall = true
            } label: {
                Text("Ontgrendel de Gezinsversie")
                    .font(AppTheme.rounded(m.compactButton.textSize))
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.compactButton.height)
            }
            .buttonStyle(ToyButtonStyle(
                fill: AppTheme.mint,
                radius: m.buttonCorner,
                depth: m.compactButton.depth,
                border: m.border
            ))
        }
        .padding(m.gutter)
        .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
    }
}

#Preview {
    let profiles = ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json"))
    let _ = profiles.addProfile(name: "Lene")
    let _ = profiles.addProfile(name: "Ellis")

    NavigationStack {
        FamilyRecordsView()
    }
    .environment(profiles)
    .environment(EntitlementStore(previewUnlocked: true))
    .appMetrics()
}
