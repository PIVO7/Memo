import SwiftUI

/// Het aankoopscherm van de Gezinsversie: wat je krijgt, één prijs — en de
/// ouder-poort vóór het hele scherm, niet alleen vóór de kassa.
struct PaywallView: View {
    let entitlements: EntitlementStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m
    /// Optioneel: het scherm hangt ook in previews en rendertests, waar geen
    /// profielen bestaan.
    @Environment(ProfileStore.self) private var profileStore: ProfileStore?

    @State private var gateQuestion: ParentalGateQuestion?
    /// De poort staat vóór het hele scherm: ook de prijzen en de koopknoppen
    /// zijn oudergebied (kindercategorie).
    @State private var gatePassed = false
    @State private var gateEntry = ""
    @FocusState private var gateFieldFocused: Bool
    @State private var isBusy = false
    /// Uitleg wanneer kopen of terugzetten niet doorging; annuleren blijft
    /// stil. Wachten op een ouder en "niets gevonden" krijgen hun eigen kop —
    /// dat zijn geen mislukkingen.
    @State private var purchaseNotice: PurchaseNotice?

    private struct PurchaseNotice {
        let title: String
        let message: String
    }

    private var priceText: String {
        entitlements.familyProduct?.displayPrice ?? "…"
    }

    /// De namen die al in de app staan: het scherm gaat over dít gezin, niet
    /// over "gebruikers". Geen profielen? Dan blijft de regel weg.
    private var familyLine: String? {
        let names = (profileStore?.humanProfiles ?? []).map(\.name)
        switch names.count {
        case 0: return nil
        case 1: return String(localized: "Voor \(names[0])")
        default: return String(localized: "Voor \(names.dropLast().joined(separator: ", ")) en \(names[names.count - 1])")
        }
    }

    var body: some View {
        ZStack {
            ThemedBackground()

            if gatePassed || entitlements.isFamilyUnlocked {
                paywallContent
            }

            // De sluitknop hoort in de hoek van het vénster, niet in de hoek
            // van de smallere tekstkolom — en blijft ook mét dichte poort
            // bereikbaar, zodat een kind gewoon weg kan.
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Label("Sluiten", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                            .font(.system(size: m.captionSize + 2, weight: .black))
                            .foregroundStyle(AppTheme.ink)
                            .frame(width: m.tapTarget, height: m.tapTarget)
                    }
                    .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cellCorner, depth: m.shallowDepth, border: m.thinBorder))
                }
                Spacer()
            }
            // Ruimer dan de standaardmarge: de ronde hoek van het sheet
            // liep anders dwars achter de knop door en knipte zijn schaduw.
            .padding(m.gutter * 1.4)

            // De ouder-poort: verplicht voor de kindercategorie, en eerlijk
            // gezegd gewoon verstandig.
            if let question = gateQuestion {
                gateOverlay(question)
            }

            if let purchaseNotice {
                ToyDialog(
                    title: purchaseNotice.title,
                    message: purchaseNotice.message,
                    confirmTitle: String(localized: "Oké"),
                    onConfirm: dismissNotice,
                    onCancel: dismissNotice
                )
            }
        }
        .interactiveDismissDisabled(isBusy)
        .onAppear {
            // De vraag komt meteen bij het openen; wie de winkel al heeft,
            // hoeft niets meer te rekenen.
            if !entitlements.isFamilyUnlocked && !gatePassed {
                gateQuestion = .make()
            }
        }
        // De prijs kan bij het openen nog ontbreken (geen netwerk bij de
        // start); hier krijgt hij een tweede kans.
        .task {
            if entitlements.familyProduct == nil {
                await entitlements.load()
            }
        }
    }

    private var paywallContent: some View {
        // Past alles op het scherm (iPad, grote iPhone), dan hoort het in het
        // midden; anders scrollt het, met de kassa vast onderaan. ViewThatFits
        // meet dat zelf — een GeometryReader in een sheet rekende zich rijk en
        // liet op de iPad een halve lege pagina onder de tekst.
        ViewThatFits(in: .vertical) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                paywallBody
                Spacer(minLength: 0)
            }
            ScrollView {
                paywallBody
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Ontgrendeld is er geen kassa meer; het bordje staat dan gewoon
            // onder de tekst in plaats van te zweven in een lege balk.
            if !entitlements.isFamilyUnlocked {
                purchaseBar
            }
        }
    }

    private var paywallBody: some View {
        VStack(spacing: m.gutter) {
            Image(systemName: "figure.2.and.child.holdinghands")
                .font(.system(size: m.titleSize, weight: .black))
                .foregroundStyle(AppTheme.coral)

            if let familyLine {
                Text(familyLine)
                    .font(AppTheme.rounded(m.captionSize + 2, .bold))
                    .foregroundStyle(AppTheme.soft)
                    .multilineTextAlignment(.center)
            }

            Text("Gezinsversie")
                .font(AppTheme.rounded(m.titleSize * 0.7))
                .foregroundStyle(AppTheme.headline)

            Text("Eén keer kopen, voor het hele gezin — ook via Delen met gezin.")
                .font(AppTheme.rounded(m.captionSize + 2, .bold))
                .foregroundStyle(AppTheme.soft)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: m.gutter * 0.7) {
                feature("stopwatch.fill", "Tegen de klok", "Solo: alle paren zo snel mogelijk")
                feature("graduationcap.fill", "Drie tegenstanders", "Dommel, Robbie en Professor Punt")
                feature("paintpalette.fill", "Alle kleurenthema's", "Snoep, Oceaan en Nacht")
                feature("chart.bar.fill", "Statistieken en trofeeën", "Per speler, met winreeks en beste vangst")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(m.gutter)
            .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)

            reassurance

            if entitlements.isFamilyUnlocked {
                Label("Ontgrendeld — veel plezier!", systemImage: "checkmark.seal.fill")
                    .font(AppTheme.rounded(m.bodySize))
                    .foregroundStyle(AppTheme.mint)
                    .padding(.top, m.gutter * 0.5)
            }
        }
        .padding(.horizontal, m.gutter * 1.4)
        .padding(.top, m.gutter)
        .padding(.bottom, m.gutter)
        .frame(maxWidth: m.overlayMaxWidth)
        .frame(maxWidth: .infinity)
    }

    /// Wat een ouder op dit moment wil weten: wat het niet is. Geen abonnement,
    /// geen advertenties, en gratis blijft gewoon spelen.
    private var reassurance: some View {
        VStack(spacing: m.gutter * 0.3) {
            Text("Zonder Gezinsversie blijven jullie gewoon samen spelen, met z'n tweeën.")
            Text("Gemaakt voor gezinnen, niet voor advertenties: niets dat meekijkt en geen abonnement.")
        }
        .font(AppTheme.rounded(m.captionSize, .bold))
        .foregroundStyle(AppTheme.soft)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    /// De kassa staat vast onderaan: met grote letters schoof de knop anders
    /// onder de vouw en leek het scherm een folder zonder kassa.
    private var purchaseBar: some View {
        VStack(spacing: m.gutter * 0.4) {
            Text("Eenmalig · geen abonnement")
                .font(AppTheme.rounded(m.captionSize, .bold))
                .foregroundStyle(AppTheme.cardSoft)
                .multilineTextAlignment(.center)

            Button(action: startPurchase) {
                // Bezig? Dan draait er zichtbaar iets. Prijs nog onderweg?
                // Dan geen "Ontgrendel voor …" met een gat erin.
                Group {
                    if isBusy {
                        ProgressView()
                            .tint(AppTheme.ink)
                    } else if entitlements.familyProduct == nil {
                        Text("Ontgrendelen")
                    } else {
                        Text("Ontgrendel voor \(priceText)")
                    }
                }
                .font(AppTheme.rounded(m.defaultButton.textSize))
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: m.defaultButton.height)
            }
            .buttonStyle(ToyButtonStyle(
                fill: AppTheme.mint,
                radius: m.buttonCorner,
                depth: m.defaultButton.depth,
                border: m.border
            ))
            .disabled(isBusy)

            Button(action: startRestore) {
                Text("Eerder gekocht? Zet terug")
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.cardSoft)
                    .frame(minHeight: m.tapTarget)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(isBusy)
        }
        .padding(.horizontal, m.gutter)
        .padding(.vertical, m.gutter * 0.7)
        .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
        .frame(maxWidth: m.overlayMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, m.gutter * 1.4)
        .padding(.bottom, m.gutter * 0.6)
    }

    /// Kop plus uitleg in plaats van één lange zin: zo scan je de lijst in
    /// twee seconden en lees je alleen door wat je aanspreekt.
    private func feature(_ icon: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: m.gutter * 0.6) {
            Image(systemName: icon)
                .font(.system(size: m.bodySize, weight: .black))
                .foregroundStyle(AppTheme.coral)
                .frame(width: m.bodySize * 1.6)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.rounded(m.captionSize + 2))
                    .foregroundStyle(AppTheme.ink)
                Text(detail)
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.cardSoft)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func gateOverlay(_ question: ParentalGateQuestion) -> some View {
        ZStack {
            // Tikken naast de kaart sluit het hele scherm; VoiceOver krijgt
            // de opties op de kaart, niet dit vlak.
            AppTheme.ink.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
                .accessibilityHidden(true)

            VStack(spacing: m.gutter * 0.8) {
                Text("Vraag even aan papa of mama")
                    .font(AppTheme.rounded(m.bodySize + 2))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)

                Text(question.text)
                    .font(AppTheme.rounded(m.titleSize * 0.6))
                    .foregroundStyle(AppTheme.coral)

                // Het antwoord wordt ingetypt: uit drie knoppen valt te
                // gokken, een leeg veld niet.
                TextField(
                    "",
                    text: $gateEntry,
                    prompt: Text(verbatim: "?").foregroundStyle(AppTheme.cardDim)
                )
                .keyboardType(.numberPad)
                .focused($gateFieldFocused)
                .font(AppTheme.rounded(m.bodySize + 4))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: m.tapTarget * 2.2)
                .frame(height: m.tapTarget)
                .toyBlock(fill: AppTheme.sunk, radius: m.cellCorner, depth: 0, border: m.thinBorder)
                .accessibilityLabel(String(localized: "Antwoord"))
                .onAppear { gateFieldFocused = true }

                Button {
                    answerGate(question: question)
                } label: {
                    Text("Controleer")
                        .font(AppTheme.rounded(m.bodySize + 2))
                        .foregroundStyle(AppTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: m.tapTarget)
                }
                .buttonStyle(ToyButtonStyle(fill: AppTheme.mint, radius: m.cellCorner, depth: m.shallowDepth, border: m.thinBorder))
                .disabled(Int(gateEntry) == nil)
            }
            .padding(m.gutter * 1.4)
            // Kaartwit en niet cream: in het nachtthema is cream donker en
            // zou de donkere inkt onleesbaar worden.
            .toyBlock(fill: AppTheme.card, radius: m.dialogCorner, depth: m.heroDepth, border: m.border)
            .frame(maxWidth: m.overlayMaxWidth * 0.82)
            .padding(m.gutter * 2)
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity)
    }

    private func answerGate(question: ParentalGateQuestion) {
        guard Int(gateEntry) == question.answer else {
            // Fout: nieuwe som en een leeg veld, zodat gokken niet loont.
            gateEntry = ""
            gateQuestion = .make()
            return
        }
        gateEntry = ""
        withAnimation(.easeOut(duration: 0.15)) {
            gateQuestion = nil
            gatePassed = true
        }
    }

    // MARK: - Kassa

    private func startPurchase() {
        isBusy = true
        Task {
            await purchase()
            isBusy = false
        }
    }

    private func startRestore() {
        isBusy = true
        Task {
            await restore()
            isBusy = false
        }
    }

    /// Annuleren is een keuze en blijft stil; mislukken en wachten-op-ouder
    /// verdienen uitleg — anders lijkt de knop gewoon kapot.
    private func purchase() async {
        switch await entitlements.purchaseFamily() {
        case .success, .cancelled:
            break
        case .pending:
            showNotice(
                title: String(localized: "Vraag onderweg"),
                message: String(localized: "De aankoop wacht op goedkeuring van een ouder. Zodra die er is, wordt alles vanzelf ontgrendeld.")
            )
        case .failed:
            showNotice(
                title: String(localized: "Dat lukte niet"),
                message: String(localized: "Kopen is niet gelukt. Controleer de internetverbinding en probeer het straks nog eens.")
            )
        }
    }

    /// Terugzetten dat stilletjes niets doet lijkt kapot; hier hoort een
    /// antwoord bij, ook als dat "niets gevonden" is.
    private func restore() async {
        let synced = await entitlements.restorePurchases()
        if !synced {
            showNotice(
                title: String(localized: "Dat lukte niet"),
                message: String(localized: "Terugzetten is niet gelukt. Controleer de internetverbinding en probeer het straks nog eens.")
            )
        } else if !entitlements.isFamilyUnlocked {
            showNotice(
                title: String(localized: "Niets gevonden"),
                message: String(localized: "Er is geen eerdere aankoop gevonden voor dit Apple-account.")
            )
        }
    }

    private func showNotice(title: String, message: String) {
        withAnimation(.easeOut(duration: 0.15)) {
            purchaseNotice = PurchaseNotice(title: title, message: message)
        }
    }

    private func dismissNotice() {
        withAnimation(.easeOut(duration: 0.15)) {
            purchaseNotice = nil
        }
    }
}

#Preview {
    PaywallView(entitlements: EntitlementStore(previewUnlocked: false))
        .appMetrics()
}
