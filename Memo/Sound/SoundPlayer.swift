import AVFoundation

/// Speelt de korte spelgeluiden af. De ambient-categorie houdt de
/// mute-schakelaar van het toestel de baas en laat muziek van een andere app
/// gewoon doorspelen — precies wat je wil bij een spelletje aan tafel.
///
/// Al het audiowerk loopt op een eigen achtergrondwachtrij: de audiosessie
/// instellen en activeren kan even blokkeren, en op de main thread zou dat
/// de interface kunnen laten haperen.
final class SoundPlayer: @unchecked Sendable {
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
    private let queue = DispatchQueue(label: "com.pivo7.memo.sound", qos: .userInitiated)
    /// Alleen aanraken vanop `queue`.
    private var players: [Sound: AVAudioPlayer] = [:]

    private init() {
        queue.async { self.setUp() }
    }

    func play(_ sound: Sound) {
        guard isEnabled else { return }
        queue.async {
            guard let player = self.players[sound] else { return }
            player.currentTime = 0
            player.play()
        }
    }

    private func setUp() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient)
        // Zelf activeren, zodat de eerste play() dat niet impliciet hoeft te doen.
        try? session.setActive(true)
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
                continue
            }
            let player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            players[sound] = player
        }
    }
}
