import AVFoundation

/// Speelt de korte spelgeluiden af. De ambient-categorie houdt de
/// mute-schakelaar van het toestel de baas en laat muziek van een andere app
/// gewoon doorspelen — precies wat je wil bij een spelletje aan tafel.
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    enum Sound: String, CaseIterable {
        /// Een steen valt in het bord.
        case drop = "plop"
        /// Een zet teruggezet of iets bevestigd.
        case score = "ding"
        /// De beurt gaat naar de volgende speler.
        case turn = "wissel"
        /// Het potje is uit — de grote klapper.
        case fanfare = "fanfare"
    }

    /// Aan of uit, onthouden over sessies heen; instelbaar in het
    /// instellingenscherm.
    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Self.enabledKey) }
    }

    private static let enabledKey = "geluid-aan"
    private var players: [Sound: AVAudioPlayer] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
                continue
            }
            let player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            players[sound] = player
        }
    }

    func play(_ sound: Sound) {
        guard isEnabled, let player = players[sound] else { return }
        player.currentTime = 0
        player.play()
    }
}
