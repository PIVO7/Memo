import SwiftUI

/// Houdt het spel bij elkaar: bewaart de voortgang en vertaalt zetten naar
/// trillingen, banners en vieringen. Het tekenwerk zit in de losse views.
struct GameView: View {
    let engine: GameEngine
    /// Vervangt het spel door een vers potje met dezelfde deelnemers; de
    /// eigenaar van de cover wisselt de engine.
    let onRematch: () -> Void
    let onClose: () -> Void

    @Environment(ProfileStore.self) private var profileStore
    @Environment(GameStore.self) private var gameStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.metrics) private var m

    @State private var didRecordResult = false
    @State private var isNewRecord = false
    @State private var showResult = false
    @State private var showExitConfirm = false
    @State private var resultReveal: Task<Void, Never>?
    /// Legt na een misser de kaarten weer dicht zodra het kind even heeft
    /// kunnen kijken; de computerlus regelt zijn eigen missers.
    @State private var resolveDelay: Task<Void, Never>?
    @State private var flipPulse = 0
    @State private var turnPulse = 0
    @State private var winPulse = 0
    /// De laatste uitkomst kleurt de statuschip: amber bij een paar, sky bij
    /// geen paar, coral bij het feest op het einde. Neutraal zodra de beurt
    /// wisselt.
    @State private var lastOutcome: FlipOutcome?

    private enum FlipOutcome { case match, mismatch, finished }

    /// De korte knal bij een gevonden paar; verdwijnt vanzelf weer.
    @State private var showMatchCallout = false
    @State private var matchCallout: Task<Void, Never>?

    var body: some View {
        ZStack {
            ThemedBackground()

            VStack(spacing: m.gutter) {
                topBar

                // De tussenstand vlak boven het speelveld dat hij samenvat.
                GameHeaderView(
                    players: engine.players,
                    currentPlayerID: engine.currentPlayer.id,
                    pairCount: engine.pairCount(of:)
                )

                statusLine

                CardGridView(
                    cards: engine.cards,
                    columns: engine.boardSize.columns,
                    playerName: { engine.players[$0].name },
                    isEnabled: engine.canFlip,
                    onFlip: flip
                )
            }
            .padding(.horizontal, m.gutter)
            .padding(.vertical, m.gutter * 0.5)
            // De hele kolom op één maximumbreedte, anders rekt de kop op een
            // iPad uit over het volle scherm.
            .frame(maxWidth: m.contentMaxWidth)
            .frame(maxWidth: .infinity)

            if showMatchCallout {
                MatchCalloutView()
                    .zIndex(2)
            }

            if showResult {
                GameResultOverlay(
                    players: engine.players,
                    winnerProfileIDs: engine.winnerProfileIDs,
                    message: engine.turnMessage,
                    pairCounts: engine.players.indices.map(engine.pairCount(of:)),
                    isNewRecord: isNewRecord,
                    onRematch: onRematch,
                    onClose: onClose
                )
                .zIndex(4)
            }

            if showExitConfirm {
                ToyDialog(
                    title: String(localized: "Spel verlaten?"),
                    message: String(localized: "Je voortgang wordt bewaard."),
                    confirmTitle: String(localized: "Verlaten"),
                    cancelTitle: String(localized: "Doorspelen"),
                    onConfirm: leave,
                    onCancel: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            showExitConfirm = false
                        }
                    }
                )
                .zIndex(5)
            }
        }
        .task(id: engine.currentPlayerIndex) {
            await engine.playComputerTurnIfNeeded()
        }
        .onAppear {
            // Een hervat spel dat toch al uit bleek: meteen de eindstand.
            if engine.isFinished {
                showResult = true
            }
        }
        .onChange(of: engine.saveVersion) { _, _ in
            persistProgress()
        }
        .onChange(of: engine.faceUpIndices) { old, new in
            // Hier en niet op de knop: zo plopt het ook als de computer een
            // kaart omdraait.
            guard new.count > old.count else { return }
            flipPulse += 1
            SoundPlayer.shared.play(.drop)
        }
        .onChange(of: engine.matchPulse) { _, _ in
            lastOutcome = .match
            presentMatchCallout()
            winPulse += 1
            SoundPlayer.shared.play(.score)
            if let pair = engine.lastMatchIndices.first.map({ engine.cards[$0] }) {
                AccessibilityNotification.Announcement(
                    String(localized: "Paar gevonden: \(pair.face.label)!")
                ).post()
            }
        }
        .onChange(of: engine.mismatchPulse) { _, _ in
            lastOutcome = .mismatch
        }
        .onChange(of: engine.isResolving) { _, resolving in
            resolveDelay?.cancel()
            guard resolving, !engine.currentPlayer.isComputer else { return }
            resolveDelay = Task {
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 1000 : 1300))
                guard !Task.isCancelled else { return }
                engine.finishMismatch()
            }
        }
        .onChange(of: engine.isFinished) { _, finished in
            guard finished else { return }
            lastOutcome = .finished
            gameDidFinish()
        }
        .onChange(of: engine.turnJustChanged) { _, changed in
            guard changed else { return }
            lastOutcome = nil
            announceTurnChange()
            engine.acknowledgeTurnChange()
        }
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.7), trigger: flipPulse)
        .sensoryFeedback(.selection, trigger: turnPulse)
        .sensoryFeedback(.success, trigger: winPulse)
    }

    // MARK: - Deelviews

    /// De spelstand als toy-chip onder de kop: wie er mag, paar of geen
    /// paar. Het kleuraccent volgt de uitkomst, zodat een kind één duidelijk
    /// "ding" heeft om naar te kijken. Tijdens het eindscherm wijkt hij.
    private var statusLine: some View {
        Text(engine.turnMessage)
            .font(AppTheme.rounded(m.bodySize, .bold))
            .foregroundStyle(AppTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, m.gutter)
            .padding(.vertical, m.gutter * 0.45)
            .frame(maxWidth: .infinity)
            .toyBlock(fill: statusFill, radius: m.cellCorner, depth: m.shallowDepth, border: m.thinBorder + 0.5)
            .animation(.easeOut(duration: 0.15), value: engine.turnMessage)
            .opacity(showResult ? 0 : 1)
    }

    private var statusFill: Color {
        switch lastOutcome {
        case .match: AppTheme.tintAmber
        case .mismatch: AppTheme.tintSky
        case .finished: AppTheme.tintCoral
        case nil: AppTheme.card
        }
    }

    /// De dunne bovenrand: beurt- en parenteller (passieve meta-info) met
    /// de sluitknop ernaast. De tussenstand staat niet meer hier maar vlak
    /// boven het speelveld.
    private var topBar: some View {
        HStack(spacing: 8) {
            let turn = Text("Beurt \(engine.attempts + (engine.isFinished ? 0 : 1))")
            let pairs = Text("Nog \(engine.pairsRemaining) paren")
            Text("\(turn) · \(pairs)")
                .textCase(.uppercase)
                .font(AppTheme.rounded(m.captionSize * 0.92))
                .kerning(1.6)
                .foregroundStyle(AppTheme.faint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)

            Button(action: requestLeave) {
                Label("Spel verlaten", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.system(size: m.captionSize + 2, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: m.tapTarget, height: m.tapTarget)
            }
            .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cellCorner, depth: m.shallowDepth, border: m.thinBorder))
        }
    }

    // MARK: - Zetten

    private func flip(at index: Int) {
        engine.flip(at: index)
    }

    /// Een afgelopen spel valt niets meer te bewaren, dus dan slaan we de
    /// bevestiging over.
    private func requestLeave() {
        if engine.isFinished {
            leave()
        } else {
            withAnimation(.easeOut(duration: 0.15)) {
                showExitConfirm = true
            }
        }
    }

    private func leave() {
        persistProgress()
        onClose()
    }

    // MARK: - Reacties op het spel

    /// Solo spreekt de aankondiging je aan; met z'n tweeën aan één toestel
    /// noemt ze de naam.
    private var turnAnnouncement: String {
        if engine.mode == .versusComputer, !engine.currentPlayer.isComputer {
            return String(localized: "Jij bent aan de beurt")
        }
        return String(localized: "\(engine.currentPlayer.name) is aan de beurt")
    }

    /// De knal even laten staan en dan vanzelf laten gaan. Een volgend
    /// paar onderbreekt de vorige, zodat er nooit twee overlappen.
    private func presentMatchCallout() {
        matchCallout?.cancel()
        matchCallout = Task {
            withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.6)) {
                showMatchCallout = true
            }
            try? await Task.sleep(for: .milliseconds(1100))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                showMatchCallout = false
            }
        }
    }

    private func gameDidFinish() {
        winPulse += 1
        SoundPlayer.shared.play(.fanfare)
        recordResult()
        AccessibilityNotification.Announcement(engine.turnMessage).post()
        // Het laatste paar eerst even laten zien; daarna pas de eindstand
        // eroverheen.
        resultReveal?.cancel()
        resultReveal = Task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 400 : 1200))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.8)) {
                showResult = true
            }
        }
    }

    private func recordResult() {
        guard !didRecordResult else { return }
        didRecordResult = true
        let pairCounts = engine.players.indices.map(engine.pairCount(of:))
        // Record checken vóór de statistieken worden bijgewerkt; het eerste
        // potje ooit telt niet als record.
        if engine.winnerProfileIDs.count == 1,
           let winnerIndex = engine.players.indices.first(where: { engine.winnerProfileIDs.contains(engine.players[$0].profileID) }),
           let profile = profileStore.humanProfiles.first(where: { $0.id == engine.players[winnerIndex].profileID }),
           profile.gamesPlayed > 0,
           pairCounts[winnerIndex] > profile.mostPairs {
            isNewRecord = true
        }
        gameStore.clear()
        profileStore.recordGameResult(
            players: engine.players,
            winnerProfileIDs: engine.winnerProfileIDs,
            pairCounts: pairCounts
        )
    }

    /// Geen rood vlak meer bij een beurtwissel: de kop en de statusregel
    /// zeggen al wie er mag. De tik, het geluid en de VoiceOver-aankondiging
    /// markeren het moment.
    private func announceTurnChange() {
        guard !engine.isFinished else { return }
        turnPulse += 1
        SoundPlayer.shared.play(.turn)
        AccessibilityNotification.Announcement(turnAnnouncement).post()
    }

    private func persistProgress() {
        if engine.isFinished {
            gameStore.clear()
        } else {
            gameStore.save(engine.snapshot)
        }
    }
}

#Preview {
    let profiles = [
        PlayerProfile(name: "Lene", avatarColorIndex: 0),
        PlayerProfile(name: "Ellis", avatarColorIndex: 1)
    ]
    GameView(
        engine: GameEngine(mode: .versusFriends, profiles: profiles),
        onRematch: {},
        onClose: {}
    )
    .environment(ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json")))
    .environment(GameStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json")))
    .appMetrics()
}
