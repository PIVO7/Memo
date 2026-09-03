import SwiftUI

/// Het grote woord bij het moment waar het spel om draait: er ligt een paar.
/// De statuschip vertelt wie er nog een keer mag; dit is de knal erbij, vlak
/// bij de kaartjes waar het gebeurde — zoals de worp in woorden bij de
/// stenen van Dobbel staat.
///
/// Puur decor: VoiceOver krijgt de melding al als aankondiging bij de beurt.
struct MatchCalloutView: View {
    @Environment(\.metrics) private var m
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("Paar!")
            .textCase(.uppercase)
            .font(AppTheme.rounded(m.displaySize))
            .kerning(1.5)
            .foregroundStyle(AppTheme.card)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, m.gutter * 1.6)
            .padding(.vertical, m.gutter * 0.7)
            .toyBlock(fill: AppTheme.coral, radius: m.cellCorner, depth: m.heroDepth, border: m.border)
            .scaleEffect(reduceMotion ? 1 : 1.04)
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.86)))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    MatchCalloutView()
        .padding()
        .background(AppTheme.cream)
        .appMetrics()
}
