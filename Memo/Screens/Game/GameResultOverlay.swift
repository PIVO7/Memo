import SwiftUI

/// De eindstand over het speelveld heen, met de winnaar in de verf.
struct GameResultOverlay: View {
    let players: [GamePlayer]
    let winnerProfileIDs: [UUID]
    let message: String
    /// Aantal gevonden paren per speler, in spelersvolgorde.
    let pairCounts: [Int]
    /// Meer paren dan ooit tevoren: extra feest.
    var isNewRecord = false
    let onRematch: () -> Void
    let onClose: () -> Void

    @Environment(\.metrics) private var m

    private var hasWinner: Bool { winnerProfileIDs.count == 1 }

    private var winner: GamePlayer? {
        guard hasWinner else { return nil }
        return players.first { winnerProfileIDs.contains($0.profileID) }
    }

    /// De grote kop noemt de winnaar bij naam; een kaal "Gewonnen!" leest
    /// alsof jíj won, ook wanneer de computer er met de paren vandoor ging.
    private var title: String {
        winner.map { String(localized: "\($0.name) wint!") } ?? String(localized: "Gelijkspel!")
    }

    /// Onder de kop: de vangst — of een hart onder de riem als de computer
    /// won.
    private var subtitle: String {
        guard let winner, let index = players.firstIndex(where: { $0.id == winner.id }) else {
            return message
        }
        if winner.isComputer {
            return String(localized: "Volgende keer win jij vast!")
        }
        let count = pairCounts.indices.contains(index) ? pairCounts[index] : 0
        return String(localized: "Gewonnen met \(count) paren!")
    }

    var body: some View {
        ZStack {
            AppTheme.ink.opacity(0.5).ignoresSafeArea()

            // Alleen feest wanneer een échte speler wint; confetti voor de
            // computer maakt het eindscherm juist verwarrender.
            if let winner, !winner.isComputer {
                ConfettiView(particleCount: isNewRecord ? 44 : 28)
                    .ignoresSafeArea()
            }

            VStack(spacing: m.gutter) {
                if let winner {
                    AvatarBadge(player: winner, size: m.avatarSize * 1.5)
                        .overlay(alignment: .top) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: m.avatarSize * 0.52, weight: .black))
                                .foregroundStyle(AppTheme.amber)
                                .rotationEffect(.degrees(14))
                                .offset(x: m.avatarSize * 0.52, y: -m.avatarSize * 0.4)
                        }
                        .padding(.top, m.gutter * 0.4)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(AppTheme.rounded(m.titleSize))
                    .foregroundStyle(AppTheme.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                if isNewRecord {
                    Label("Nieuw record!", systemImage: "sparkles")
                        .font(AppTheme.rounded(m.captionSize + 2))
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .toyBlock(fill: AppTheme.amber, radius: m.cellCorner + 2, depth: 3, border: m.thinBorder)
                }

                Text(subtitle)
                    .font(AppTheme.rounded(m.bodySize, .bold))
                    .foregroundStyle(AppTheme.soft)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        row(for: player, pairCount: pairCounts.indices.contains(index) ? pairCounts[index] : 0)
                    }
                }

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
                .padding(.top, 4)

                Button(action: onClose) {
                    Text("Terug naar menu")
                        .font(AppTheme.rounded(m.buttonTextSize * 0.85))
                        .foregroundStyle(AppTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: m.buttonHeight * 0.9)
                }
                .buttonStyle(ToyButtonStyle(
                    fill: .white,
                    radius: m.cardCorner * 0.8,
                    depth: m.depth,
                    border: m.border
                ))
            }
            .padding(m.gutter * 1.5)
            .toyBlock(fill: .white, radius: m.cardCorner + 4, depth: m.depth + 1, border: m.border)
            .frame(maxWidth: m.overlayMaxWidth)
            .padding(m.gutter * 2)
            // Modaal voor VoiceOver: het speelveld eronder is voorbij.
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity.combined(with: .scale))
    }

    private func row(for player: GamePlayer, pairCount: Int) -> some View {
        let isWinner = winnerProfileIDs.contains(player.profileID)
        return HStack {
            AvatarBadge(player: player, size: m.avatarSize * 0.72)
            Text(player.name)
                .font(AppTheme.rounded(m.bodySize, .bold))
            Spacer()
            Text("\(pairCount) paren")
                .font(AppTheme.rounded(m.captionSize + 1, .bold))
                .foregroundStyle(AppTheme.soft)
            if isWinner && hasWinner {
                Image(systemName: "star.fill")
                    .foregroundStyle(AppTheme.amber)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(AppTheme.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .toyBlock(
            fill: isWinner ? AppTheme.tintAmber : AppTheme.sunk,
            radius: m.cellCorner + 1,
            depth: isWinner ? 3 : 0,
            border: isWinner ? m.border : m.thinBorder
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isWinner && hasWinner
                ? String(localized: "\(player.name), \(pairCount) paren, winnaar")
                : String(localized: "\(player.name), \(pairCount) paren")
        )
    }
}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene", avatarColorIndex: 0))
    let ellis = GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1))

    GameResultOverlay(
        players: [lene, ellis],
        winnerProfileIDs: [lene.profileID],
        message: "Lene wint met 5 paren!",
        pairCounts: [5, 3],
        isNewRecord: true,
        onRematch: {},
        onClose: {}
    )
    .background(AppTheme.cream)
    .appMetrics()
}
