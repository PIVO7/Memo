import SwiftUI

/// Korte melding bij een beurtwissel, zodat aan één toestel duidelijk is wie
/// er nu mag. Hij komt bovenaan en dimt niets; de avatar staat erbij omdat
/// een kind die sneller herkent dan zijn naam.
struct TurnBannerView: View {
    let player: GamePlayer
    /// De tekst staat los van de speler: solo zegt de banner "Jij bent aan de
    /// beurt" in plaats van je eigen naam.
    var title: String?

    @Environment(\.metrics) private var m

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: m.gutter * 0.6) {
                AvatarBadge(player: player, size: m.avatarSize * 0.62)

                Text(title ?? String(localized: "\(player.name) is aan de beurt"))
                    .font(AppTheme.rounded(m.bodySize))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.leading, m.gutter * 0.6)
            .padding(.trailing, m.gutter * 1.1)
            .padding(.vertical, m.gutter * 0.6)
            .toyBlock(
                fill: AppTheme.coral,
                radius: m.cardCorner * 0.8,
                depth: m.depth,
                border: m.border
            )
            // Net onder de kop, waar geen knoppen zitten.
            .padding(.top, m.tapTarget + m.gutter)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}

#Preview {
    TurnBannerView(player: GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1)))
        .background(AppTheme.cream)
        .appMetrics()
}
