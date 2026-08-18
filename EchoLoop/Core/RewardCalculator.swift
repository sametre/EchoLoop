import Foundation

enum RewardCalculator {
    static func reward(elapsed: TimeInterval, closeCalls: Int, shards: Int, score: Int) -> RunReward {
        let safeElapsed = max(0, elapsed)
        let safeCloseCalls = max(0, closeCalls)
        let safeShards = max(0, shards)
        let safeScore = max(0, score)
        let scoreBonus = min(60, safeScore / 2500)
        let coins = 5 + Int(safeElapsed / 10) * 3 + safeShards * 4 + min(safeCloseCalls, 15) + scoreBonus
        let xp = 12 + Int(safeElapsed * 1.25) + safeShards * 4 + safeCloseCalls * 2 + min(100, safeScore / 1000)
        return RunReward(coins: max(5, coins), xp: max(12, xp))
    }
}
