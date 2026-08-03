import SwiftUI

/// De twee spelers op één regel, elk met hun parenteller, en de sluitknop
/// ernaast. Wie aan de beurt is krijgt een gekleurde chip met zijn bolletje.
struct GameHeaderView: View {
    let players: [GamePlayer]
    let currentPlayerID: UUID
    /// Spelerindex → aantal gevonden paren.
    let pairCount: (Int) -> Int
    let onLeave: () -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    chip(for: player, index: index)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, m.gutter * 0.45)
            .frame(maxWidth: .infinity)
            .toyBlock(fill: .white, radius: m.cellCorner + 3, depth: 3, border: m.thinBorder + 0.5)

            Button(action: onLeave) {
                Label("Spel verlaten", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.system(size: m.captionSize + 2, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: m.tapTarget, height: m.tapTarget)
            }
            .buttonStyle(ToyButtonStyle(fill: .white, radius: m.cellCorner, depth: 3, border: m.thinBorder))
        }
    }

    private func chip(for player: GamePlayer, index: Int) -> some View {
        let isMine = player.id == currentPlayerID
        let pairs = pairCount(index)
        return HStack(spacing: 5) {
            AvatarBadge(player: player, size: m.captionSize * 1.8)
            Text(player.name)
                .font(AppTheme.rounded(m.captionSize, .bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            // De stand in één oogopslag: hoeveel paren heeft iedereen al?
            Text("\(pairs)")
                .font(AppTheme.rounded(m.captionSize, .bold))
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(AppTheme.tintAmber))
                .overlay(Capsule().strokeBorder(AppTheme.ink.opacity(0.35), lineWidth: 1))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: m.cellCorner, style: .continuous)
                .fill(isMine ? AppTheme.tintCoral : .clear)
        )
        .overlay {
            RoundedRectangle(cornerRadius: m.cellCorner, style: .continuous)
                .strokeBorder(isMine ? AppTheme.coral : .clear, lineWidth: m.thinBorder)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(localized: "\(player.name), \(pairs) paren")
                + (isMine ? String(localized: ", aan de beurt") : "")
        )
    }
}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene", avatarColorIndex: 0))
    let ellis = GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1))

    GameHeaderView(players: [lene, ellis], currentPlayerID: lene.id, pairCount: { $0 + 2 }, onLeave: {})
        .padding()
        .background(AppTheme.cream)
        .appMetrics()
}
