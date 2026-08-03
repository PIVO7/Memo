import SwiftUI

/// Het kenmerk van deze stijl: een gevuld blok met een inktrand, en daarachter
/// hetzelfde blok een paar punten lager. Geen vervaging — dat leest als dikte
/// in plaats van als schaduw.
// MainActor omdat de standaardwaarden uit het (MainActor-)thema komen.
@MainActor
struct ToyBlock: ViewModifier {
    var fill: Color
    var radius: CGFloat = 16
    var depth: CGFloat = 5
    var border: CGFloat = 3
    var borderColor: Color = AppTheme.ink
    var shadowColor: Color = AppTheme.ink

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: border)
            }
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(shadowColor)
                    .offset(y: depth)
            )
    }
}

extension View {
    @MainActor
    func toyBlock(
        fill: Color,
        radius: CGFloat = 16,
        depth: CGFloat = 5,
        border: CGFloat = 3,
        borderColor: Color = AppTheme.ink,
        shadowColor: Color = AppTheme.ink
    ) -> some View {
        modifier(ToyBlock(
            fill: fill,
            radius: radius,
            depth: depth,
            border: border,
            borderColor: borderColor,
            shadowColor: shadowColor
        ))
    }
}

