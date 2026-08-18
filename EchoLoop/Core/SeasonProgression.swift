import Foundation

struct SeasonTier: Identifiable, Hashable {
    let id: Int
    let requiredXP: Int
    let coinReward: Int
    let title: String
}

enum SeasonProgression {
    static let seasonID = "signal-zero"
    static let title = "SIGNAL ZERO"

    static let tiers: [SeasonTier] = [
        .init(id: 1, requiredXP: 0, coinReward: 75, title: "BOOT SEQUENCE"),
        .init(id: 2, requiredXP: 250, coinReward: 100, title: "FIRST TRACE"),
        .init(id: 3, requiredXP: 600, coinReward: 125, title: "AFTERIMAGE"),
        .init(id: 4, requiredXP: 1_050, coinReward: 150, title: "SIGNAL LOCK"),
        .init(id: 5, requiredXP: 1_600, coinReward: 200, title: "DEEP LOOP"),
        .init(id: 6, requiredXP: 2_250, coinReward: 225, title: "CHRONO TRACE"),
        .init(id: 7, requiredXP: 3_000, coinReward: 250, title: "PRISM BREAK"),
        .init(id: 8, requiredXP: 3_850, coinReward: 300, title: "VOID SIGNAL"),
        .init(id: 9, requiredXP: 4_800, coinReward: 350, title: "OVERDRIVE"),
        .init(id: 10, requiredXP: 5_850, coinReward: 400, title: "ECHO MASTER"),
        .init(id: 11, requiredXP: 7_000, coinReward: 500, title: "PAST BREAKER"),
        .init(id: 12, requiredXP: 8_250, coinReward: 650, title: "SIGNAL COMPLETE")
    ]

    static func xpForRun(elapsed: TimeInterval, stage: Int, score: Int, bossEncounters: Int) -> Int {
        let survival = Int(max(0, elapsed) * 1.25)
        let stageBonus = max(0, stage - 1) * 18
        let scoreBonus = max(0, score) / 450
        let bossBonus = max(0, bossEncounters) * 120
        return max(20, survival + stageBonus + scoreBonus + bossBonus)
    }

    static func currentTier(for xp: Int) -> Int {
        tiers.last(where: { xp >= $0.requiredXP })?.id ?? 1
    }

    static func progressToNextTier(for xp: Int) -> Double {
        let current = currentTier(for: xp)
        guard let currentTier = tiers.first(where: { $0.id == current }),
              let nextTier = tiers.first(where: { $0.id == current + 1 }) else { return 1 }
        let width = max(1, nextTier.requiredXP - currentTier.requiredXP)
        return min(1, max(0, Double(xp - currentTier.requiredXP) / Double(width)))
    }

    static func unlockedUnclaimedTiers(xp: Int, claimed: Set<Int>) -> [SeasonTier] {
        tiers.filter { xp >= $0.requiredXP && !claimed.contains($0.id) }
    }
}
