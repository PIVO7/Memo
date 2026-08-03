import XCTest
@testable import Memo

final class ParentalGateTests: XCTestCase {
    /// De poortvraag moet het juiste antwoord tussen de opties hebben, en
    /// geen dubbele of onmogelijke opties.
    func testQuestionIsSolvableAndFair() {
        var rng = SplitMix64(seed: 42)
        for _ in 0..<50 {
            let question = ParentalGateQuestion.make(using: &rng)
            XCTAssertEqual(question.options.count, 3)
            XCTAssertEqual(Set(question.options).count, 3)
            XCTAssertTrue(question.options.contains(question.answer))
            XCTAssertTrue(question.options.allSatisfy { $0 > 0 })
            XCTAssertTrue(question.answer >= 16 && question.answer <= 81)
        }
    }
}
