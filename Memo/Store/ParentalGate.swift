import Foundation

/// Een rekenvraag die een kleuter niet zomaar oplost: de kindercategorie van
/// de App Store eist een ouder-poort vóór elke aankoop. Het antwoord wordt
/// ingetypt, niet aangetikt — met drie knoppen loont blijven gokken vroeg
/// of laat.
struct ParentalGateQuestion: Equatable {
    let text: String
    let answer: Int

    static func make(using generator: inout some RandomNumberGenerator) -> ParentalGateQuestion {
        let a = Int.random(in: 4...9, using: &generator)
        let b = Int.random(in: 4...9, using: &generator)
        return ParentalGateQuestion(text: String(localized: "Hoeveel is \(a) × \(b)?"), answer: a * b)
    }

    static func make() -> ParentalGateQuestion {
        var generator = SystemRandomNumberGenerator()
        return make(using: &generator)
    }
}
