import XCTest
@testable import EchoLoop

final class GameRulesTests: XCTestCase {
    func testStageBoundaries() {
        XCTAssertEqual(GameRules.stage(for: 0), 1)
        XCTAssertEqual(GameRules.stage(for: 19.99), 1)
        XCTAssertEqual(GameRules.stage(for: 20), 2)
        XCTAssertEqual(GameRules.stage(for: 60), 4)
    }

    func testEchoIntervalNeverDropsBelowMinimum() {
        XCTAssertEqual(GameRules.echoInterval(stage: 1), AppConfig.Game.baseEchoInterval, accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(GameRules.echoInterval(stage: 100), AppConfig.Game.minimumEchoInterval)
    }

    func testFrameDeltaIsClamped() {
        XCTAssertEqual(GameRules.clampedFrameDelta(-1), 0, accuracy: 0.0001)
        XCTAssertEqual(GameRules.clampedFrameDelta(1), 1.0 / 20.0, accuracy: 0.0001)
        XCTAssertEqual(GameRules.clampedFrameDelta(0.01), 0.01, accuracy: 0.0001)
    }

    func testDifficultyTightensArenaAndHazards() {
        XCTAssertGreaterThan(GameRules.gameplayMargin(stage: 10), GameRules.gameplayMargin(stage: 1))
        XCTAssertLessThanOrEqual(GameRules.hazardInterval(stage: 10), GameRules.hazardInterval(stage: 3))
        XCTAssertLessThanOrEqual(GameRules.echoSpeedFactor(stage: 10), GameRules.echoSpeedFactor(stage: 1))
    }
}
