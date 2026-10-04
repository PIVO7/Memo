import XCTest
@testable import Memo

final class ParentalGateTests: XCTestCase {
    /// De poortvraag moet een echte tafelsom zijn met een antwoord dat een
    /// ouder uit het hoofd kent.
    func testQuestionIsSolvable() {
        var rng = SplitMix64(seed: 42)
        for _ in 0..<50 {
            let question = ParentalGateQuestion.make(using: &rng)
            XCTAssertTrue(question.answer >= 16 && question.answer <= 81)
            XCTAssertFalse(question.text.isEmpty)
        }
    }
}
