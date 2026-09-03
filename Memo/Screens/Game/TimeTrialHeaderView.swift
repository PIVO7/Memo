import SwiftUI

/// De kop van een potje tegen de klok: de speler met zijn parenteller links,
/// de stopwatch rechts. Dezelfde chip-taal als de tweespelerkop, maar de
/// tweede plek is voor de klok — dát is hier de tegenstander.
struct TimeTrialHeaderView: View {
    let player: GamePlayer
    let pairs: Int
    let totalPairs: Int
    let isRunning: Bool
    /// Elke seconde opnieuw gevraagd zolang de klok loopt; daarna één keer.
    let elapsedSeconds: () -> Int

    @Environment(\.metrics) private var m

    var body: some View {
        HStack(spacing: m.gutter * 0.6) {
            HStack(spacing: 5) {
                AvatarBadge(player: player, size: m.captionSize * 1.8)
                Text(player.name)
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text("\(pairs)/\(totalPairs)")
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.ink)
                    .monospacedDigit()
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(AppTheme.tintAmber))
                    .overlay(Capsule().strokeBorder(AppTheme.ink, lineWidth: 1.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // TimelineView alleen zolang de klok loopt: een stilstaande klok
            // hoeft niet elke seconde opnieuw te tekenen.
            if isRunning {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    clock(seconds: elapsedSeconds())
                }
            } else {
                clock(seconds: elapsedSeconds())
            }
        }
        .padding(.horizontal, m.gutter * 0.5 + m.border)
        .padding(.vertical, m.gutter * 0.45)
        .frame(maxWidth: .infinity)
        .toyBlock(fill: AppTheme.card, radius: m.buttonCorner, depth: m.shallowDepth, border: m.thinBorder + 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(localized: "\(player.name), \(pairs) van \(totalPairs) paren, \(ClockText.spoken(seconds: elapsedSeconds()))")
        )
    }

    private func clock(seconds: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: m.captionSize, weight: .black))
                .foregroundStyle(AppTheme.coral)
            Text(ClockText.string(seconds: seconds))
                .font(AppTheme.rounded(m.bodySize))
                .foregroundStyle(AppTheme.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, m.gutter * 0.5 + m.border)
        .padding(.vertical, m.gutter * 0.25 + m.border)
        .background(
            RoundedRectangle(cornerRadius: m.cellCorner, style: .continuous)
                .fill(AppTheme.tintCoral)
        )
        .overlay {
            RoundedRectangle(cornerRadius: m.cellCorner, style: .continuous)
                .strokeBorder(AppTheme.coral, lineWidth: m.border)
        }
    }
}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene", avatarColorIndex: 0))

    TimeTrialHeaderView(player: lene, pairs: 3, totalPairs: 8, isRunning: false, elapsedSeconds: { 83 })
        .padding()
        .background(AppTheme.cream)
        .appMetrics()
}
