import SwiftUI

/// Een speelgoedtegeltje met een symbool: wit kaartje, dikke inktrand en
/// een kleur uit het avatarpalet. Overgenomen uit Raak; hier staat hij als
/// blikvanger bovenaan de winkel en naast elk voordeel.
struct TileBadge: View {
    var symbol: String
    /// Index in `AvatarBadge.palette`.
    var colorIndex: Int = 0
    var size: CGFloat = 44
    /// Losstaande tegels (de hero) krijgen dikte; tegels óp een gekleurd
    /// blok blijven plat.
    var depth: CGFloat = 0

    private var corner: CGFloat { size * 0.18 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(AppTheme.card)
            Image(systemName: symbol)
                .font(.system(size: size * 0.44, weight: .black))
                .foregroundStyle(AvatarBadge.palette[colorIndex % AvatarBadge.palette.count])
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(AppTheme.ink, lineWidth: max(size * 0.045, 1.5))
        }
        .frame(width: size, height: size)
        .background {
            if depth > 0 {
                RoundedRectangle(cornerRadius: corner)
                    .fill(AppTheme.ink)
                    .offset(y: depth)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 16) {
        TileBadge(symbol: "star.fill", colorIndex: 1, size: 80)
        TileBadge(symbol: "figure.2.and.child.holdinghands", colorIndex: 0, size: 80)
        TileBadge(symbol: "square.on.square", colorIndex: 2, size: 80)
    }
    .padding()
    .background(AppTheme.cream)
}
