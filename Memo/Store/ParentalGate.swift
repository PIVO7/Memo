import Foundation

/// Een rekenvraag die een kleuter niet zomaar oplost: de kindercategorie van
/// de App Store eist een ouder-poort vóór elke aankoop.
struct ParentalGateQuestion: Equatable {
    let text: String
    let answer: Int
    let options: [Int]

    static func make(using generator: inout some RandomNumberGenerator) -> ParentalGateQuestion {
        let a = Int.random(in: 4...9, using: &generator)
        let b = Int.random(in: 4...9, using: &generator)
        let answer = a * b

        var wrong: Set<Int> = []
        while wrong.count < 2 {
            let offset = Int.random(in: -9 ... 9, using: &generator)
            let candidate = answer + offset
            if candidate != answer, candidate > 0 {
                wrong.insert(candidate)
            }
        }
        let options = ([answer] + wrong).shuffled(using: &generator)
        return ParentalGateQuestion(text: String(localized: "Hoeveel is \(a) × \(b)?"), answer: answer, options: options)
    }

    static func make() -> ParentalGateQuestion {
        var generator = SystemRandomNumberGenerator()
        return make(using: &generator)
    }
}
