import SwiftUI

/// De statistiekenpagina van één profiel: cijfers, het parengrafiekje van de
/// laatste potjes en de trofeeënkast. Zonder Gezinsversie blijft het bij een
/// voorproefje met een vriendelijke uitnodiging.
struct ProfileStatsView: View {
    let profileID: UUID

    @Environment(ProfileStore.self) private var profileStore
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.metrics) private var m

    @State private var showPaywall = false

    private var profile: PlayerProfile? {
        profileStore.humanProfiles.first { $0.id == profileID }
    }

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            if let profile {
                content(for: profile)
            }
        }
        .navigationTitle("Statistieken")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(entitlements: entitlements)
                .appMetrics()
        }
    }

    private func content(for profile: PlayerProfile) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: m.gutter * 1.4) {
                VStack(spacing: 8) {
                    AvatarBadge(profile: profile, size: m.avatarSize * 1.4)
                    Text(profile.name)
                        .font(AppTheme.rounded(m.titleSize * 0.6))
                        .foregroundStyle(AppTheme.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, m.gutter * 0.5)

                if entitlements.isFamilyUnlocked {
                    section("CIJFERS") {
                        numbers(for: profile)
                    }
                    section("LAATSTE POTJES") {
                        historyChart(for: profile)
                    }
                    section("TROFEEËN") {
                        trophyCase(for: profile)
                    }
                } else {
                    section("CIJFERS") {
                        VStack(spacing: m.gutter * 0.6) {
                            statRow(String(localized: "Gespeeld"), "\(profile.gamesPlayed)", icon: "rectangle.grid.2x2.fill")
                            statRow(String(localized: "Gewonnen"), "\(profile.wins)", icon: "crown.fill")
                        }
                    }
                    section("TROFEEËN") {
                        lockedTeaser
                    }
                }
            }
            .padding(.horizontal, m.gutter * 1.5)
            .padding(.bottom, m.gutter * 2)
            .frame(maxWidth: m.overlayMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Cijfers

    private func numbers(for profile: PlayerProfile) -> some View {
        VStack(spacing: m.gutter * 0.6) {
            statRow(String(localized: "Gespeeld"), "\(profile.gamesPlayed)", icon: "rectangle.grid.2x2.fill")
            statRow(String(localized: "Gewonnen"), "\(profile.wins)", icon: "crown.fill")
            statRow(String(localized: "Gelijkgespeeld"), "\(profile.draws)", icon: "equal.circle.fill")
            statRow(
                String(localized: "Winreeks"),
                profile.currentStreak > 0
                    ? String(localized: "\(profile.currentStreak) op rij · beste \(profile.bestStreak)")
                    : String(localized: "beste \(profile.bestStreak)"),
                icon: "flame.fill"
            )
            statRow(
                String(localized: "Meeste paren in één potje"),
                "\(profile.mostPairs)",
                icon: "square.fill.on.square.fill"
            )
        }
    }

    private func statRow(_ title: String, _ value: String, icon: String) -> some View {
        HStack(spacing: m.gutter * 0.8) {
            Image(systemName: icon)
                .font(.system(size: m.bodySize, weight: .black))
                .foregroundStyle(AppTheme.coral)
                .frame(width: m.bodySize * 1.6)

            Text(title)
                .font(AppTheme.rounded(m.bodySize, .bold))
                .foregroundStyle(AppTheme.cardSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(AppTheme.rounded(m.bodySize + 3))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.horizontal, m.gutter)
        .padding(.vertical, m.gutter * 0.7)
        .toyBlock(fill: AppTheme.card, radius: m.cardCorner * 0.8, depth: 3, border: m.thinBorder + 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Grafiekje

    private func historyChart(for profile: PlayerProfile) -> some View {
        let games = Array(profile.history.suffix(10))
        let top = max(games.map(\.pairs).max() ?? 1, 1)
        let barMaxHeight = m.avatarSize * 1.9

        return Group {
            if games.isEmpty {
                Text("Speel een potje en zie de grafiek hier groeien!")
                    .font(AppTheme.rounded(m.captionSize + 2, .bold))
                    .foregroundStyle(AppTheme.cardSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(m.gutter)
                    .toyBlock(fill: AppTheme.card, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
            } else {
                HStack(alignment: .bottom, spacing: m.gutter * 0.45) {
                    ForEach(Array(games.enumerated()), id: \.offset) { index, game in
                        VStack(spacing: 4) {
                            if game.won {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: m.captionSize * 0.9, weight: .black))
                                    .foregroundStyle(AppTheme.amber)
                            }
                            Text("\(game.pairs)")
                                .font(AppTheme.rounded(m.captionSize * 0.82, .bold))
                                .foregroundStyle(AppTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            RoundedRectangle(cornerRadius: m.cellCorner * 0.7, style: .continuous)
                                .fill(game.won ? AppTheme.amber : AppTheme.sky)
                                .overlay {
                                    RoundedRectangle(cornerRadius: m.cellCorner * 0.7, style: .continuous)
                                        .strokeBorder(AppTheme.ink, lineWidth: m.thinBorder)
                                }
                                // Nooit helemaal plat: ook een mager potje
                                // verdient een zichtbaar blokje.
                                .frame(height: max(barMaxHeight * CGFloat(game.pairs) / CGFloat(top), 10))
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(
                            game.won
                                ? String(localized: "Potje \(index + 1): \(game.pairs) paren, gewonnen")
                                : String(localized: "Potje \(index + 1): \(game.pairs) paren")
                        )
                    }
                }
                .padding(m.gutter)
                .toyBlock(fill: AppTheme.card, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
            }
        }
    }

    // MARK: - Trofeeën

    private var badgeColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: m.gutter * 0.6), count: 3)
    }

    private func trophyCase(for profile: PlayerProfile) -> some View {
        let badges = ProfileBadge.collection(for: profile)
        let tints = [AppTheme.amber, AppTheme.mint, AppTheme.sky, AppTheme.coral]

        return LazyVGrid(columns: badgeColumns, spacing: m.gutter * 0.6) {
            ForEach(Array(badges.enumerated()), id: \.element.id) { index, badge in
                VStack(spacing: 6) {
                    Image(systemName: badge.isEarned ? badge.icon : "lock.fill")
                        .font(.system(size: m.bodySize + 4, weight: .black))
                        .foregroundStyle(badge.isEarned ? AppTheme.ink : AppTheme.offInk)
                        .frame(width: m.tapTarget * 0.82, height: m.tapTarget * 0.82)
                        .background(
                            Circle().fill(badge.isEarned ? tints[index % tints.count] : AppTheme.offFill)
                        )
                        .overlay {
                            Circle().strokeBorder(
                                badge.isEarned ? AppTheme.ink : AppTheme.offInk,
                                lineWidth: m.thinBorder + 0.5
                            )
                        }

                    Text(badge.title)
                        .font(AppTheme.rounded(m.captionSize * 0.88, .bold))
                        .foregroundStyle(badge.isEarned ? AppTheme.ink : AppTheme.cardDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    // Het doel blijft staan, ook na het behalen: zo kunnen
                    // kinderen elkaar uitleggen hoe je hem verdient.
                    Text(badge.goal)
                        .font(AppTheme.rounded(m.captionSize * 0.78, .bold))
                        .foregroundStyle(AppTheme.cardSoft)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, m.gutter * 0.6)
                .padding(.horizontal, 4)
                .toyBlock(
                    fill: AppTheme.card,
                    radius: m.cardCorner * 0.8,
                    depth: badge.isEarned ? 3 : 0,
                    border: m.thinBorder + 0.5
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    badge.isEarned
                        ? String(localized: "Trofee \(badge.title), behaald. \(badge.goal)")
                        : String(localized: "Trofee \(badge.title), nog te verdienen. \(badge.goal)")
                )
            }
        }
    }

    /// Het voorproefje zonder Gezinsversie: de kast staat er, de deurtjes
    /// zitten dicht.
    private var lockedTeaser: some View {
        VStack(spacing: m.gutter) {
            LazyVGrid(columns: badgeColumns, spacing: m.gutter * 0.6) {
                ForEach(0..<6, id: \.self) { _ in
                    Image(systemName: "lock.fill")
                        .font(.system(size: m.bodySize + 4, weight: .black))
                        .foregroundStyle(AppTheme.offInk)
                        .frame(width: m.tapTarget * 0.82, height: m.tapTarget * 0.82)
                        .background(Circle().fill(AppTheme.offFill))
                        .overlay { Circle().strokeBorder(AppTheme.offInk, lineWidth: m.thinBorder + 0.5) }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, m.gutter * 0.6)
                        .toyBlock(fill: AppTheme.card, radius: m.cardCorner * 0.8, depth: 0, border: m.thinBorder + 0.5)
                }
            }
            .accessibilityHidden(true)

            Text("Trofeeën, het grafiekje en de gezinsrecords horen bij de Gezinsversie.")
                .font(AppTheme.rounded(m.captionSize + 2, .bold))
                .foregroundStyle(AppTheme.soft)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button {
                showPaywall = true
            } label: {
                Text("Ontgrendel de Gezinsversie")
                    .font(AppTheme.rounded(m.buttonTextSize * 0.75))
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.buttonHeight * 0.8)
            }
            .buttonStyle(ToyButtonStyle(
                fill: AppTheme.mint,
                radius: m.cardCorner * 0.9,
                depth: m.depth,
                border: m.border
            ))
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

#Preview("Ontgrendeld") {
    let profiles = ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json"))
    let _ = profiles.addProfile(name: "Lene")

    NavigationStack {
        ProfileStatsView(profileID: profiles.humanProfiles[0].id)
    }
    .environment(profiles)
    .environment(EntitlementStore(previewUnlocked: true))
    .appMetrics()
}

#Preview("Gratis") {
    let profiles = ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json"))
    let _ = profiles.addProfile(name: "Ellis")

    NavigationStack {
        ProfileStatsView(profileID: profiles.humanProfiles[0].id)
    }
    .environment(profiles)
    .environment(EntitlementStore(previewUnlocked: false))
    .appMetrics()
}
