import XCTest
@testable import EchoLoop

final class SeasonProgressionTests: XCTestCase {
    func testTierProgressionUsesThresholds() {
        XCTAssertEqual(SeasonProgression.currentTier(for: 0), 1)
        XCTAssertEqual(SeasonProgression.currentTier(for: 600), 3)
        XCTAssertEqual(SeasonProgression.currentTier(for: 100_000), 12)
    }

    func testUnlockedUnclaimedTiersExcludesClaimed() {
        let unlocked = SeasonProgression.unlockedUnclaimedTiers(xp: 1_050, claimed: [1, 2])
        XCTAssertEqual(unlocked.map(\.id), [3, 4])
    }

    func testSeasonXPRewardsBossSurvival() {
        let base = SeasonProgression.xpForRun(elapsed: 60, stage: 4, score: 3000, bossEncounters: 0)
        let boss = SeasonProgression.xpForRun(elapsed: 60, stage: 4, score: 3000, bossEncounters: 1)
        XCTAssertGreaterThan(boss, base)
    }
}
