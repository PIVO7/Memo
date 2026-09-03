import SwiftUI

struct GameSetupView: View {
    let mode: GameMode
    @Environment(ProfileStore.self) private var profileStore
    @Environment(GameStore.self) private var gameStore
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.metrics) private var m
    /// Een lijst en geen verzameling: wie eerst aantikt, mag beginnen.
    @State private var selectedIDs: [UUID] = []
    @State private var opponentLevel: ComputerLevel = .medium
    @State private var boardSize: BoardSize = .medium
    @State private var activeGame: ActiveGame?
    @State private var showRules = false
    @State private var showPaywall = false
    /// De start die nog op bevestiging wacht omdat er een bewaard spel is.
    @State private var pendingStart: (() -> Void)?

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: m.gutter), count: count)
    }

    var body: some View {
        ZStack {
            ThemedBackground()

            VStack(alignment: .leading, spacing: m.gutter) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.title)
                            .font(AppTheme.rounded(m.titleSize))
                            .foregroundStyle(AppTheme.headline)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        Text(mode.subtitle)
                            .font(AppTheme.rounded(m.bodySize, .bold))
                            .foregroundStyle(AppTheme.soft)
                    }

                    Spacer()

                    Button {
                        showRules = true
                    } label: {
                        Label("Hoe werkt Memo?", systemImage: "book.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: m.captionSize + 2, weight: .black))
                            .foregroundStyle(AppTheme.ink)
                            .frame(width: m.tapTarget, height: m.tapTarget)
                    }
                    .buttonStyle(ToyButtonStyle(fill: AppTheme.tintSky, radius: m.cellCorner, depth: m.shallowDepth, border: m.thinBorder))
                    .sheet(isPresented: $showRules) {
                        RulesView()
                            .appMetrics()
                    }
                    .sheet(isPresented: $showPaywall) {
                        PaywallView(entitlements: entitlements)
                            .appMetrics()
                    }
                }

                if profileStore.humanProfiles.isEmpty {
                    VStack(spacing: m.gutter) {
                        // Eigen kaartje in de speelgoedstijl in plaats van
                        // ContentUnavailableView met systeemtypografie.
                        VStack(spacing: m.gutter * 0.6) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: m.avatarSize * 0.6, weight: .black))
                                .foregroundStyle(AvatarBadge.palette[4])
                                .frame(width: m.avatarSize * 1.3, height: m.avatarSize * 1.3)
                                .toyBlock(fill: AppTheme.card, radius: m.cellCorner, depth: 0, border: m.thinBorder + 0.5)
                                .accessibilityHidden(true)
                            Text("Geen profielen")
                                .font(AppTheme.rounded(m.bodySize + 4))
                                .foregroundStyle(AppTheme.ink)
                            Text("Maak eerst een profiel aan om te spelen.")
                                .font(AppTheme.rounded(m.captionSize + 1, .bold))
                                .foregroundStyle(AppTheme.cardSoft)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(m.gutter * 1.4)
                        .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)

                        NavigationLink(value: Destination.profiles) {
                            Text("Naar profielen")
                                .font(AppTheme.rounded(m.defaultButton.textSize))
                                .foregroundStyle(AppTheme.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: m.defaultButton.height)
                        }
                        .buttonStyle(ToyButtonStyle(
                            fill: AppTheme.mint,
                            radius: m.buttonCorner,
                            depth: m.defaultButton.depth,
                            border: m.border
                        ))
                    }

                    // Ook zonder profiel hoort de tegenstanderkeuze in beeld:
                    // een gast speelde anders altijd tegen Robbie zonder dat
                    // ergens te zien was.
                    if mode == .versusComputer {
                        Text("KIES JE TEGENSTANDER")
                            .font(AppTheme.rounded(m.captionSize * 0.9))
                            .kerning(1.4)
                            .foregroundStyle(AppTheme.faint)

                        HStack(spacing: m.gutter * 0.75) {
                            ForEach(ComputerLevel.allCases) { level in
                                opponentButton(level)
                            }
                        }
                    }

                    boardSection

                    // Meteen kunnen spelen zonder eerst een profiel aan
                    // te maken; gasten worden niet bewaard.
                    Button(action: requestGuestStart) {
                        // Expliciet LocalizedStringKey: een ternary van twee
                        // letterlijke strings wordt anders een gewone String
                        // en die vertaalt Text niet.
                        Text(mode == .versusComputer
                             ? LocalizedStringKey("Of speel als gast")
                             : LocalizedStringKey("Of speel met twee gasten"))
                            .font(AppTheme.rounded(m.compactButton.textSize))
                            .foregroundStyle(AppTheme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: m.compactButton.height)
                    }
                    .buttonStyle(ToyButtonStyle(
                        fill: AppTheme.card,
                        radius: m.buttonCorner,
                        depth: m.compactButton.depth,
                        border: m.border
                    ))
                    .padding(.bottom, 6)
                } else {
                    Text(mode == .versusComputer
                         ? LocalizedStringKey("KIES JOUW PROFIEL")
                         : LocalizedStringKey("KIES 2 SPELERS"))
                        .font(AppTheme.rounded(m.captionSize * 0.9))
                        .kerning(1.4)
                        .foregroundStyle(AppTheme.faint)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: m.gutter) {
                            ForEach(profileStore.humanProfiles) { profile in
                                profileButton(profile)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    if mode == .versusComputer {
                        Text("KIES JE TEGENSTANDER")
                            .font(AppTheme.rounded(m.captionSize * 0.9))
                            .kerning(1.4)
                            .foregroundStyle(AppTheme.faint)

                        HStack(spacing: m.gutter * 0.75) {
                            ForEach(ComputerLevel.allCases) { level in
                                opponentButton(level)
                            }
                        }
                    }

                    boardSection

                    Button(action: requestStart) {
                        Text("Start spel")
                            .font(AppTheme.rounded(m.heroButton.textSize))
                            .foregroundStyle(canStart ? AppTheme.ink : AppTheme.offInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: m.heroButton.height)
                    }
                    .buttonStyle(ToyButtonStyle(
                        fill: canStart ? AppTheme.mint : AppTheme.offFill,
                        radius: m.buttonCorner,
                        depth: m.heroButton.depth,
                        border: m.border
                    ))
                    .disabled(!canStart)
                    .padding(.bottom, 6)
                }
            }
            .padding(.horizontal, m.gutter * 1.5)
            .padding(.top, 6)
            .padding(.bottom, m.gutter)
            .frame(maxWidth: m.contentMaxWidth)
            .frame(maxWidth: .infinity)

            // Eigen dialoog in de speelgoedstijl in plaats van het grijze
            // systeempaneel.
            if pendingStart != nil {
                ToyDialog(
                    title: String(localized: "Lopend spel vervangen?"),
                    message: String(localized: "Er staat nog een spel klaar om verder te spelen."),
                    confirmTitle: String(localized: "Nieuw spel starten"),
                    cancelTitle: String(localized: "Annuleer"),
                    onConfirm: {
                        let start = pendingStart
                        pendingStart = nil
                        start?()
                    },
                    onCancel: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            pendingStart = nil
                        }
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeGame) { game in
            GameCoverView(
                game: game,
                profileStore: profileStore,
                gameStore: gameStore,
                activeGame: $activeGame
            )
        }
    }

    /// De bordkeuze: klein voor de jongsten, groot voor de geheugentijgers.
    @ViewBuilder
    private var boardSection: some View {
        Text("KIES HET BORD")
            .font(AppTheme.rounded(m.captionSize * 0.9))
            .kerning(1.4)
            .foregroundStyle(AppTheme.faint)

        HStack(spacing: m.gutter * 0.75) {
            ForEach(BoardSize.allCases) { size in
                boardButton(size)
            }
        }
    }

    private func boardButton(_ size: BoardSize) -> some View {
        let picked = boardSize == size
        return Button {
            boardSize = size
        } label: {
            VStack(spacing: 3) {
                Text(size.title)
                    .font(AppTheme.rounded(m.captionSize + 2))
                    .foregroundStyle(AppTheme.ink)
                Text(size.subtitle)
                    .font(AppTheme.rounded(m.captionSize * 0.82, .bold))
                    .foregroundStyle(AppTheme.cardSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, m.gutter * 0.55)
        }
        .buttonStyle(ToyButtonStyle(
            fill: picked ? AppTheme.tintCoral : AppTheme.card,
            radius: m.cardCorner,
            depth: picked ? m.depth : m.shallowDepth,
            border: m.border,
            borderColor: picked ? AppTheme.coral : AppTheme.ink
        ))
        .accessibilityLabel("\(size.title), \(size.subtitle)")
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    private func profileButton(_ profile: PlayerProfile) -> some View {
        let picked = selectedIDs.contains(profile.id)
        return Button {
            toggle(profile.id)
        } label: {
            HStack(spacing: m.gutter * 0.9) {
                AvatarBadge(profile: profile, size: m.avatarSize)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(AppTheme.rounded(m.bodySize + 2))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Text("\(profile.wins) overwinningen")
                        .font(AppTheme.rounded(m.captionSize, .bold))
                        .foregroundStyle(AppTheme.cardSoft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: m.bodySize * 1.4, weight: .black))
                    .foregroundStyle(picked ? AppTheme.coral : AppTheme.cardDim)
            }
            .padding(m.gutter * 0.9)
        }
        .buttonStyle(ToyButtonStyle(
            fill: picked ? AppTheme.tintCoral : AppTheme.card,
            radius: m.cardCorner,
            depth: m.depth,
            border: m.border,
            borderColor: picked ? AppTheme.coral : AppTheme.ink
        ))
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    /// De drie computertegenstanders naast elkaar; wie gekozen is, kleurt.
    /// Dommel en de professor horen bij de Gezinsversie.
    private func opponentButton(_ level: ComputerLevel) -> some View {
        let picked = opponentLevel == level
        let locked = level != .medium && !entitlements.isFamilyUnlocked
        return Button {
            if locked {
                showPaywall = true
            } else {
                opponentLevel = level
            }
        } label: {
            VStack(spacing: 6) {
                // Zelfde vinkje als bij de spelerkeuze, zodat de gekozen
                // tegenstander net zo duidelijk is als de gekozen speler.
                Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: m.bodySize * 1.1, weight: .black))
                    .foregroundStyle(picked ? AppTheme.coral : AppTheme.cardDim)
                AvatarBadge(name: level.personaName, colorIndex: level.avatarColorIndex, symbol: level.avatarSymbol, size: m.avatarSize * 0.9)
                    .overlay(alignment: .bottomTrailing) {
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: m.captionSize, weight: .black))
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(Circle().fill(AppTheme.ink))
                                .offset(x: 5, y: 5)
                        }
                    }
                Text(level.personaName)
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(level.subtitle)
                    .font(AppTheme.rounded(m.captionSize * 0.82, .bold))
                    .foregroundStyle(AppTheme.cardSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, m.gutter * 0.7)
            .padding(.horizontal, 4)
        }
        .buttonStyle(ToyButtonStyle(
            fill: picked ? AppTheme.tintCoral : AppTheme.card,
            radius: m.cardCorner,
            depth: picked ? m.depth : m.shallowDepth,
            border: m.border,
            borderColor: picked ? AppTheme.coral : AppTheme.ink
        ))
        .accessibilityLabel(
            locked
                ? String(localized: "\(level.personaName), \(level.subtitle), Gezinsversie nodig")
                : "\(level.personaName), \(level.subtitle)"
        )
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    private var canStart: Bool {
        switch mode {
        case .versusComputer:
            return selectedIDs.count == 1
        case .versusFriends:
            return selectedIDs.count == 2
        }
    }

    private func toggle(_ id: UUID) {
        if mode == .versusComputer {
            selectedIDs = [id]
            return
        }
        if let index = selectedIDs.firstIndex(of: id) {
            selectedIDs.remove(at: index)
        } else if selectedIDs.count < 2 {
            selectedIDs.append(id)
        }
    }

    /// Een nieuw spel gooit een bewaard spel weg, dus dat vragen we eerst.
    private func requestStart() {
        guard canStart else { return }
        request(beginNewGame)
    }

    private func requestGuestStart() {
        request(beginGuestGame)
    }

    private func request(_ start: @escaping () -> Void) {
        if gameStore.hasSavedGame {
            withAnimation(.easeOut(duration: 0.15)) {
                pendingStart = start
            }
        } else {
            start()
        }
    }

    /// Spelen zonder profiel: gasten doen gewoon mee maar worden nergens
    /// bewaard en tellen niet mee in de statistieken.
    private func beginGuestGame() {
        var profiles = mode == .versusFriends
            ? [
                PlayerProfile(name: String(localized: "Gast 1")),
                PlayerProfile(name: String(localized: "Gast 2"), avatarColorIndex: 1)
            ]
            : [PlayerProfile(name: String(localized: "Gast"))]
        if mode == .versusComputer {
            profiles.append(.computer(level: opponentLevel))
        }
        begin(with: profiles)
    }

    private func beginNewGame() {
        let humans = selectedIDs.compactMap { id in
            profileStore.humanProfiles.first { $0.id == id }
        }
        var profiles = humans
        if mode == .versusComputer {
            profiles.append(.computer(level: opponentLevel))
        }
        begin(with: profiles)
    }

    private func begin(with profiles: [PlayerProfile]) {
        gameStore.clear()
        let engine = GameEngine(mode: mode, profiles: profiles, boardSize: boardSize)
        // Meteen de verse stand wegschrijven: sluit je de app direct af,
        // dan komt anders het oude bewaarde spel weer boven.
        gameStore.save(engine.snapshot)
        activeGame = ActiveGame(engine: engine)
    }
}

#Preview {
    // Tijdelijke bestanden, zodat de preview nooit aan echte spelersdata komt.
    let profiles = ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json"))
    let _ = profiles.addProfile(name: "Lene")
    let _ = profiles.addProfile(name: "Ellis")
    let _ = profiles.addProfile(name: "Noah")

    NavigationStack {
        GameSetupView(mode: .versusFriends)
    }
    .environment(profiles)
    .environment(GameStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json")))
    .environment(EntitlementStore(previewUnlocked: false))
    .appMetrics()
}
