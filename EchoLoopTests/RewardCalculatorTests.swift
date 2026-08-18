import XCTest
@testable import EchoLoop

final class RewardCalculatorTests: XCTestCase {
    func testMinimumReward() {
        let reward = RewardCalculator.reward(elapsed: 0, closeCalls: 0, shards: 0, score: 0)
        XCTAssertEqual(reward, RunReward(coins: 5, xp: 12))
    }

    func testRewardGrowsWithPerformance() {
        let low = RewardCalculator.reward(elapsed: 10, closeCalls: 0, shards: 0, score: 500)
        let high = RewardCalculator.reward(elapsed: 90, closeCalls: 8, shards: 12, score: 20_000)
        XCTAssertGreaterThan(high.coins, low.coins)
        XCTAssertGreaterThan(high.xp, low.xp)
    }

    func testNegativeInputsAreSanitized() {
        let negative = RewardCalculator.reward(elapsed: -500, closeCalls: -5, shards: -8, score: -1000)
        XCTAssertEqual(negative, RunReward(coins: 5, xp: 12))
    }
}
