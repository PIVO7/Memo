import SwiftUI

/// De eindstand als "podiumknal": het scherm klapt om naar amber, de winnaar
/// staat op het hoogste podiumblok onder een draaiende stralenkrans, en het
/// aantal paren telt op in flipcijfers. Choreografie: blokken springen
/// omhoog → avatars landen → banner klapt open → cijfers tellen → kroon valt.
struct GameResultOverlay: View {
    let players: [GamePlayer]
    let winnerProfileIDs: [UUID]
    let message: String
    /// Aantal gevonden paren per speler, in spelersvolgorde.
    let pairCounts: [Int]
    /// Meer paren dan ooit tevoren: extra feest.
    var isNewRecord = false
    /// Uit voor stille renders (rooktest, previews zonder klok): het scherm
    /// staat er dan meteen compleet, zonder choreografie.
    var animatesIn = true
    let onRematch: () -> Void
    let onClose: () -> Void

    @Environment(\.metrics) private var m
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var blocksRose = false
    @State private var avatarsLanded = false
    @State private var bannerOpened = false
    @State private var crownFell = false
    @State private var countedValue = 0

    private var blocksUp: Bool { blocksRose || !animatesIn }
    private var avatarsDown: Bool { avatarsLanded || !animatesIn }
    private var bannerIn: Bool { bannerOpened || !animatesIn }
    private var crownOn: Bool { crownFell || !animatesIn }
    private var shownCount: Int { animatesIn ? countedValue : winnerPairs }

    private var hasWinner: Bool { winnerProfileIDs.count == 1 }

    private var winner: GamePlayer? {
        guard hasWinner else { return nil }
        return players.first { winnerProfileIDs.contains($0.profileID) }
    }

    private var winnerPairs: Int {
        guard let winner, let index = players.firstIndex(where: { $0.id == winner.id }),
              pairCounts.indices.contains(index) else { return 0 }
        return pairCounts[index]
    }

    /// De banner noemt de winnaar bij naam; een kaal "Gewonnen!" leest
    /// alsof jíj won, ook wanneer de computer er met de paren vandoor ging.
    private var bannerTitle: String {
        let title = winner.map { String(localized: "\($0.name) wint!") } ?? String(localized: "Gelijkspel!")
        return title.uppercased()
    }

    /// Spelers op podiumvolgorde: winnaar in het midden, de rest op paren.
    /// Indeling links → rechts: [2e, 1e], zoals op een echt podium.
    private var podium: [(player: GamePlayer, rank: Int, pairs: Int)] {
        let ranked = players.enumerated().sorted { a, b in
            let aWins = winnerProfileIDs.contains(a.element.profileID)
            let bWins = winnerProfileIDs.contains(b.element.profileID)
            if aWins != bWins { return aWins }
            return (pairCounts[safe: a.offset] ?? 0) > (pairCounts[safe: b.offset] ?? 0)
        }
        let entries = ranked.enumerated().map { rank, item in
            (player: item.element, rank: rank, pairs: pairCounts[safe: item.offset] ?? 0)
        }
        var arranged = entries
        if entries.count >= 2 {
            arranged[0] = entries[1]
            arranged[1] = entries[0]
        }
        return arranged
    }

    var body: some View {
        ZStack {
            AppTheme.amber.ignoresSafeArea()

            // Alleen feest wanneer een échte speler wint; confetti voor de
            // computer maakt het eindscherm juist verwarrender.
            if let winner, !winner.isComputer {
                ConfettiView(particleCount: isNewRecord ? 44 : 28)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                header
                Spacer(minLength: m.gutter)
                podiumRow
                buttons
            }
            .padding(.horizontal, m.gutter * 1.5)
            .padding(.top, m.gutter)
            .padding(.bottom, m.gutter * 1.5)
            .frame(maxWidth: m.overlayMaxWidth + 120)
            // Modaal voor VoiceOver: het speelveld eronder is voorbij.
            .accessibilityAddTraits(.isModal)
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale))
        .task { await runChoreography() }
    }

    // MARK: - Kop: kroon, banner, telcijfers, recordpil

    private var header: some View {
        VStack(spacing: m.gutter * 0.85) {
            Image(systemName: "crown.fill")
                .font(.system(size: m.titleSize * 0.9, weight: .black))
                .foregroundStyle(AppTheme.card)
                .shadow(color: AppTheme.ink, radius: 0, y: 2)
                .opacity(crownOn ? 1 : 0)
                .offset(y: crownOn ? 0 : -m.gutter * 3)
                .accessibilityHidden(true)

            ResultBanner(title: bannerTitle)
                .scaleEffect(bannerIn ? 1 : 0.4)
                .opacity(bannerIn ? 1 : 0)

            if let winner {
                if winner.isComputer {
                    Text("Volgende keer win jij vast!")
                        .font(AppTheme.rounded(m.bodySize + 2, .bold))
                        .foregroundStyle(AppTheme.ink)
                        .opacity(bannerIn ? 1 : 0)
                } else {
                    TallyTiles(value: shownCount, label: String(localized: "paren"))
                        .opacity(bannerIn ? 1 : 0)
                        .accessibilityLabel(String(localized: "gewonnen met \(winnerPairs) paren"))
                }
            } else {
                Text(message)
                    .font(AppTheme.rounded(m.bodySize + 2, .bold))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)
                    .opacity(bannerIn ? 1 : 0)
            }

            if isNewRecord {
                Label("Nieuw record!", systemImage: "sparkles")
                    .font(AppTheme.rounded(m.captionSize + 2))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .toyBlock(fill: AppTheme.card, radius: m.cellCorner + 2, depth: 3, border: m.thinBorder)
                    .opacity(bannerIn ? 1 : 0)
            }
        }
        .padding(.top, m.gutter)
    }

    // MARK: - Podium

    private var podiumRow: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(podium, id: \.player.id) { entry in
                podiumColumn(entry)
            }
        }
    }

    private func podiumColumn(_ entry: (player: GamePlayer, rank: Int, pairs: Int)) -> some View {
        let isFirst = entry.rank == 0 && hasWinner
        let blockHeights: [CGFloat] = [3.4, 2.3, 1.75, 1.3]
        let blockColors: [Color] = [AppTheme.card, AppTheme.sky, AppTheme.coral, AppTheme.mint]
        let height = m.avatarSize * blockHeights[min(entry.rank, 3)]
        let avatarSize = isFirst ? m.avatarSize * 2.1 : m.avatarSize * 1.6

        return VStack(spacing: m.gutter * 0.6) {
            AvatarBadge(player: entry.player, size: avatarSize)
                .background {
                    // De stralenkrans draait achter de winnaar, tot ver
                    // buiten het podium.
                    if isFirst {
                        SunburstView()
                            .frame(width: avatarSize * 7, height: avatarSize * 7)
                    }
                }
                .overlay(alignment: .top) {
                    if isFirst {
                        Image(systemName: "crown.fill")
                            .font(.system(size: avatarSize * 0.4, weight: .black))
                            // Crème in plaats van amber: op de amberkleurige
                            // achtergrond viel de kroon anders weg.
                            .foregroundStyle(AppTheme.card)
                            .shadow(color: AppTheme.ink, radius: 0, y: 1.5)
                            .rotationEffect(.degrees(14))
                            .offset(x: avatarSize * 0.4, y: -avatarSize * 0.3)
                            .opacity(crownOn ? 1 : 0)
                            .accessibilityHidden(true)
                    }
                }
                .opacity(avatarsDown ? 1 : 0)
                .offset(y: avatarsDown ? 0 : -m.gutter * 2.5)

            Text(entry.player.name)
                .font(AppTheme.rounded(isFirst ? m.bodySize + 5 : m.bodySize + 1))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .opacity(avatarsDown ? 1 : 0)

            PodiumBlock(
                rank: entry.rank,
                fill: blockColors[min(entry.rank, 3)],
                height: height,
                statText: String(localized: "\(entry.pairs) paren")
            )
            .scaleEffect(y: blocksUp ? 1 : 0.01, anchor: .bottom)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isFirst
                ? String(localized: "\(entry.player.name), \(entry.pairs) paren, winnaar")
                : String(localized: "\(entry.player.name), \(entry.pairs) paren")
        )
    }

    // MARK: - Knoppen

    private var buttons: some View {
        VStack(spacing: 10) {
            // De meest gemiste knop: meteen nog een potje met dezelfde
            // spelers; wie tweede was mag nu beginnen.
            Button(action: onRematch) {
                Text("Nog een keer!")
                    .font(AppTheme.rounded(m.buttonTextSize * 0.85))
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.buttonHeight * 0.9)
            }
            .buttonStyle(ToyButtonStyle(
                fill: AppTheme.mint,
                radius: m.cardCorner * 0.8,
                depth: m.depth,
                border: m.border
            ))

            Button(action: onClose) {
                Text("Terug naar menu")
                    .font(AppTheme.rounded(m.buttonTextSize * 0.85))
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.buttonHeight * 0.9)
            }
            .buttonStyle(ToyButtonStyle(
                fill: AppTheme.card,
                radius: m.cardCorner * 0.8,
                depth: m.depth,
                border: m.border
            ))
        }
        .padding(.top, m.gutter)
    }

    // MARK: - Choreografie

    /// Alles binnen ~2,2 s; de knoppen doen het vanaf de eerste tel. Bij
    /// Verminder beweging staat het scherm er meteen compleet.
    private func runChoreography() async {
        guard animatesIn else { return }
        guard !reduceMotion else {
            blocksRose = true
            avatarsLanded = true
            bannerOpened = true
            crownFell = true
            countedValue = winnerPairs
            return
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.62).delay(0.1)) {
            blocksRose = true
        }
        try? await Task.sleep(for: .milliseconds(350))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
            avatarsLanded = true
        }
        try? await Task.sleep(for: .milliseconds(250))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            bannerOpened = true
        }

        // Flipcijfers: in een vaste tijd naar het eindgetal, wat het ook is.
        let target = winnerPairs
        if target > 0 {
            try? await Task.sleep(for: .milliseconds(250))
            let steps = min(target, 16)
            for step in 1 ... steps {
                countedValue = target * step / steps
                try? await Task.sleep(for: .milliseconds(600 / UInt64(steps)))
            }
        }
        countedValue = target

        try? await Task.sleep(for: .milliseconds(200))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            crownFell = true
        }
    }
}

// MARK: - Onderdelen

/// Coral banier met omgeslagen linten, zoals op een kermiskraam.
private struct ResultBanner: View {
    let title: String

    @Environment(\.metrics) private var m

    var body: some View {
        Text(title)
            .font(AppTheme.rounded(m.displaySize))
            .kerning(1.5)
            .foregroundStyle(AppTheme.card)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, m.gutter * 1.6)
            .padding(.vertical, m.gutter * 0.55)
            .toyBlock(fill: AppTheme.coral, radius: m.cellCorner, depth: m.depth, border: m.border)
            .background(alignment: .leading) {
                RibbonTail(pointsLeading: true)
                    .fill(AppTheme.coral)
                    .overlay(RibbonTail(pointsLeading: true).fill(AppTheme.ink.opacity(0.3)))
                    .frame(width: m.gutter * 1.5, height: m.gutter * 2.2)
                    .offset(x: -m.gutter, y: m.gutter * 0.6)
            }
            .background(alignment: .trailing) {
                RibbonTail(pointsLeading: false)
                    .fill(AppTheme.coral)
                    .overlay(RibbonTail(pointsLeading: false).fill(AppTheme.ink.opacity(0.3)))
                    .frame(width: m.gutter * 1.5, height: m.gutter * 2.2)
                    .offset(x: m.gutter, y: m.gutter * 0.6)
            }
    }
}

/// Lintuiteinde met een driehoekige inkeping.
private struct RibbonTail: Shape {
    var pointsLeading: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsLeading {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.45, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

/// De winnende score als flipcijfers: één witte tegel per cijfer.
private struct TallyTiles: View {
    let value: Int
    let label: String

    @Environment(\.metrics) private var m

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 7) {
            HStack(spacing: 7) {
                ForEach(Array(String(value).enumerated()), id: \.offset) { _, digit in
                    Text(String(digit))
                        .font(AppTheme.rounded(m.titleSize * 0.9))
                        .foregroundStyle(AppTheme.ink)
                        .monospacedDigit()
                        .frame(width: m.avatarSize * 1.1, height: m.avatarSize * 1.45)
                        .toyBlock(fill: AppTheme.card, radius: m.cellCorner, depth: 4, border: m.border)
                        .contentTransition(.numericText(value: Double(value)))
                }
            }
            Text(label)
                .font(AppTheme.rounded(m.bodySize + 4))
                .foregroundStyle(AppTheme.ink)
        }
        .animation(.snappy(duration: 0.15), value: value)
        .accessibilityElement(children: .ignore)
    }
}

/// Podiumblok: bovenaan afgerond, met ranggetal en een statbordje.
private struct PodiumBlock: View {
    let rank: Int
    let fill: Color
    let height: CGFloat
    let statText: String

    @Environment(\.metrics) private var m

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: m.cellCorner + 6,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: m.cellCorner + 6,
            style: .continuous
        )
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("\(rank + 1)")
                .font(AppTheme.rounded(rank == 0 ? m.brandSize * 0.9 : m.titleSize * 0.8))
                .foregroundStyle(rank == 0 ? AppTheme.ink : AppTheme.card)
            Text(statText)
                .font(AppTheme.rounded(m.captionSize, .bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: m.cellCorner * 0.7, style: .continuous)
                        .fill(rank == 0 ? AppTheme.sunk : AppTheme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: m.cellCorner * 0.7, style: .continuous)
                        .strokeBorder(AppTheme.ink, lineWidth: m.thinBorder)
                )
                .padding(.horizontal, 4)
        }
        .padding(.top, m.gutter * 0.8)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .background(shape.fill(fill))
        .overlay(alignment: .bottom) {
            // Binnenrand onderaan: het blok lijkt in de vloer te staan.
            Rectangle()
                .fill(AppTheme.ink.opacity(0.16))
                .frame(height: m.depth)
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(AppTheme.ink, lineWidth: m.border))
        .padding(.horizontal, m.gutter * 0.35)
    }
}

/// Draaiende stralenkrans achter de winnaar. Puur decor: geen hit-testing,
/// en bij Verminder beweging staat hij stil.
private struct SunburstView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin = false

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = max(size.width, size.height)
            for wedge in 0 ..< 12 {
                let start = Angle.degrees(Double(wedge) * 30)
                let end = Angle.degrees(Double(wedge) * 30 + 15)
                var path = Path()
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
                path.closeSubpath()
                context.fill(path, with: .color(.white.opacity(0.22)))
            }
        }
        .rotationEffect(.degrees(spin ? 360 : 0))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 36).repeatForever(autoreverses: false)) {
                spin = true
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene", avatarColorIndex: 1))
    let ellis = GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 0))

    GameResultOverlay(
        players: [lene, ellis],
        winnerProfileIDs: [lene.profileID],
        message: "Lene wint met 8 paren!",
        pairCounts: [8, 5],
        isNewRecord: true,
        onRematch: {},
        onClose: {}
    )
    .appMetrics()
}
