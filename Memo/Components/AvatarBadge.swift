import SwiftUI

struct AvatarBadge: View {
    let name: String
    var colorIndex: Int = 0
    /// SF Symbol op het bolletje; zonder symbool staan er initialen.
    var symbol: String?
    var size: CGFloat = 44

    /// Waar een kind uit kiest in de avatarkiezer.
    @MainActor static var palette: [Color] {
        [
            AppTheme.coral,
            AppTheme.sky,
            AppTheme.amber,
            AppTheme.mint,
            Color(red: 0.78, green: 0.47, blue: 0.90),
            Color(red: 0.98, green: 0.60, blue: 0.35)
        ]
    }

    init(name: String, colorIndex: Int, symbol: String? = nil, size: CGFloat = 44) {
        self.name = name
        self.colorIndex = colorIndex
        self.symbol = symbol
        self.size = size
    }

    init(profile: PlayerProfile, size: CGFloat = 44) {
        self.name = profile.name
        self.colorIndex = profile.avatarColorIndex
        self.symbol = profile.avatarSymbol
        self.size = size
    }

    init(player: GamePlayer, size: CGFloat = 44) {
        self.name = player.name
        self.colorIndex = player.avatarColorIndex
        self.symbol = player.avatarSymbol
        self.size = size
    }

    private var color: Color {
        Self.palette[colorIndex % Self.palette.count]
    }

    var body: some View {
        Group {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .black))
                    .foregroundStyle(.white)
            } else {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        // Rand en diepte meeschalen, anders oogt een grote avatar op een
        // iPad dunner omlijnd dan een kleine op een iPhone.
        .toyBlock(
            fill: color,
            radius: size / 2,
            depth: max(size * 0.07, 3),
            border: max(size * 0.057, 2.5)
        )
        .accessibilityHidden(true)
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

#Preview {
    HStack(spacing: 12) {
        AvatarBadge(name: "Lene Wauters", colorIndex: 0)
        AvatarBadge(name: "Ellis", colorIndex: 1)
        AvatarBadge(name: "Noah", colorIndex: 2, size: 64)
    }
    .padding()
    .background(AppTheme.cream)
}
