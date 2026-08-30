import SwiftUI

/// De kaartjesrand van het startscherm: een rij afgeronde tanden, als de
/// ruggen van omgekeerde memokaartjes die boven de tafelrand uitsteken. De
/// rij centreert zichzelf, zodat links en rechts evenveel tafel overblijft.
struct CardTeethLine: Shape {
    /// Met `hanging` hangen de tanden omlaag vanaf de bovenrand van het
    /// frame in plaats van omhoog vanaf de onderrand.
    var hanging = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseY = hanging ? rect.minY : rect.maxY
        path.move(to: CGPoint(x: rect.minX, y: baseY))
        Self.addTeeth(to: &path, across: rect, baseY: baseY, height: rect.height, hanging: hanging)
        return path
    }

    /// Tekent de tanden verder vanaf het huidige punt; met `reversed` van
    /// rechts naar links, voor de onderrand van een gesloten vlak. Tand- en
    /// tussenmaat volgen uit de hoogte, zodat de rand op elke breedte
    /// dezelfde kaartjes-verhouding houdt.
    static func addTeeth(to path: inout Path, across rect: CGRect, baseY: CGFloat, height: CGFloat, hanging: Bool = false, reversed: Bool = false) {
        let tooth = height * 3
        let gap = height * 1.35
        let count = max(Int((rect.width - gap) / (tooth + gap)), 3)
        let lead = (rect.width - CGFloat(count) * tooth - CGFloat(count - 1) * gap) / 2
        let dir: CGFloat = reversed ? -1 : 1
        let out: CGFloat = hanging ? 1 : -1
        let corner = height * 0.5
        var x = (reversed ? rect.maxX : rect.minX) + lead * dir

        path.addLine(to: CGPoint(x: x, y: baseY))
        for tand in 0..<count {
            path.addLine(to: CGPoint(x: x, y: baseY + out * (height - corner)))
            path.addQuadCurve(
                to: CGPoint(x: x + dir * corner, y: baseY + out * height),
                control: CGPoint(x: x, y: baseY + out * height)
            )
            path.addLine(to: CGPoint(x: x + dir * (tooth - corner), y: baseY + out * height))
            path.addQuadCurve(
                to: CGPoint(x: x + dir * tooth, y: baseY + out * (height - corner)),
                control: CGPoint(x: x + dir * tooth, y: baseY + out * height)
            )
            path.addLine(to: CGPoint(x: x + dir * tooth, y: baseY))
            x += dir * (tooth + gap)
            if tand < count - 1 {
                path.addLine(to: CGPoint(x: x, y: baseY))
            }
        }
        path.addLine(to: CGPoint(x: reversed ? rect.minX : rect.maxX, y: baseY))
    }
}

/// Een gevuld vlak met kaartjes-tanden boven en (optioneel) onder. De
/// inktlijn komt er als overlay bovenop, want een vlak en zijn rand vullen
/// anders elkaars halve lijndikte weg.
struct CardTeethBandShape: Shape {
    var height: CGFloat
    var toothedBottom = true

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + height))
        CardTeethLine.addTeeth(to: &path, across: rect, baseY: rect.minY + height, height: height)
        if toothedBottom {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - height))
            CardTeethLine.addTeeth(to: &path, across: rect, baseY: rect.maxY - height, height: height, hanging: true, reversed: true)
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

/// De koraalroze band waarin de titel ligt: kaartjes-tanden boven en onder,
/// met een inktlijn op beide randen.
struct CardBandView<Content: View>: View {
    var height: CGFloat = 10
    var lineWidth: CGFloat = 3
    @ViewBuilder var content: () -> Content

    var body: some View {
        // Vulling en inktlijn komen uit exact dezelfde shape in dezelfde
        // rect: zo kunnen tandtelling en fase nooit uit elkaar lopen. De
        // negatieve horizontale marge duwt de zijranden van de omtreklijn
        // net buiten beeld.
        let shape = CardTeethBandShape(height: height)
        content()
            .frame(maxWidth: .infinity)
            .padding(.vertical, height * 2 + 12)
            .background {
                ZStack {
                    shape.fill(AppTheme.tintCoral)
                    shape.stroke(AppTheme.ink, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                }
                .padding(.horizontal, -lineWidth)
            }
    }
}

/// De tafelrand onder aan het scherm, met een rij omgekeerde kaartjes die
/// erboven uitsteken — en één kaartje al omgedraaid: een gevonden vormpje.
/// Puur decor — ligt achter de inhoud en vangt geen aanrakingen.
struct CardTableView: View {
    var lineWidth: CGFloat = 3
    var height: CGFloat = 84

    var body: some View {
        Rectangle()
            .fill(AppTheme.tintCoral)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppTheme.ink)
                    .frame(height: lineWidth)
            }
            // De kaartjes staan achter de tafelrand: hun voet verdwijnt
            // achter het vlak, alleen de koppen kijken eroverheen.
            .background(alignment: .top) {
                HStack(spacing: height * 0.16) {
                    peekingCard(tilt: -4)
                    peekingCard(tilt: 3)
                    foundCard(tilt: -2)
                    peekingCard(tilt: 4)
                    peekingCard(tilt: -3)
                }
                .offset(y: -height * 0.34)
            }
            .frame(height: height)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    private func peekingCard(tilt: Double) -> some View {
        MemoryCardView(card: MemoryCard(face: CardFace.catalog[0]), size: height * 0.56)
            .rotationEffect(.degrees(tilt))
    }

    private func foundCard(tilt: Double) -> some View {
        var card = MemoryCard(face: CardFace.catalog[8])
        card.isFaceUp = true
        return MemoryCardView(card: card, size: height * 0.56)
            .rotationEffect(.degrees(tilt))
    }
}

#Preview {
    VStack(spacing: 40) {
        CardBandView {
            Text(verbatim: "Memo!")
                .font(AppTheme.rounded(42))
                .foregroundStyle(AppTheme.ink)
        }
        Spacer()
        CardTableView()
    }
    .background(AppTheme.cream)
    .ignoresSafeArea(edges: .bottom)
    .appMetrics()
}
