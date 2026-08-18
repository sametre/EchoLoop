import XCTest
@testable import EchoLoop

final class CloudMergeTests: XCTestCase {
    func testNewerDeviceWinsCurrencyAndSelections() {
        var local = PlayerProfile.SaveData()
        local.coins = 800
        local.selectedOrbID = "core"
        local.lastModified = 100
        local.syncRevision = 3

        var remote = PlayerProfile.SaveData()
        remote.coins = 240
        remote.selectedOrbID = "rose"
        remote.lastModified = 200
        remote.syncRevision = 4

        let merged = PlayerProfile.merged(local: local, remote: remote)
        XCTAssertEqual(merged.coins, 240)
        XCTAssertEqual(merged.selectedOrbID, "rose")
    }

    func testMergePreservesBestAndOwnedProgress() {
        var local = PlayerProfile.SaveData()
        local.bestTime = 90
        local.lifetimeShards = 50
        local.ownedOrbs.insert("rose")
        local.lastModified = 100

        var remote = PlayerProfile.SaveData()
        remote.bestTime = 60
        remote.lifetimeShards = 120
        remote.ownedOrbs.insert("violet")
        remote.lastModified = 200

        let merged = PlayerProfile.merged(local: local, remote: remote)
        XCTAssertEqual(merged.bestTime, 90)
        XCTAssertEqual(merged.lifetimeShards, 120)
        XCTAssertTrue(merged.ownedOrbs.contains("rose"))
        XCTAssertTrue(merged.ownedOrbs.contains("violet"))
    }

    func testSameDayChallengeProgressUsesMaximum() {
        var local = PlayerProfile.SaveData()
        local.challengeDayKey = "2026-08-18"
        local.challengeProgress = ["survive_45": 20]
        local.lastModified = 100

        var remote = PlayerProfile.SaveData()
        remote.challengeDayKey = "2026-08-18"
        remote.challengeProgress = ["survive_45": 40]
        remote.lastModified = 200

        let merged = PlayerProfile.merged(local: local, remote: remote)
        XCTAssertEqual(merged.challengeProgress["survive_45"], 40)
    }
    func testV6SeasonAndBossProgressMergeMonotonically() {
        var local = PlayerProfile.SaveData()
        local.seasonID = SeasonProgression.seasonID
        local.seasonXP = 1200
        local.claimedSeasonTiers = [1, 2]
        local.lifetimeBossEncounters = 2

        var remote = PlayerProfile.SaveData()
        remote.seasonID = SeasonProgression.seasonID
        remote.seasonXP = 1800
        remote.claimedSeasonTiers = [1, 3]
        remote.lifetimeBossEncounters = 5

        let merged = PlayerProfile.merged(local: local, remote: remote)
        XCTAssertEqual(merged.seasonXP, 1800)
        XCTAssertEqual(merged.claimedSeasonTiers, [1, 2, 3])
        XCTAssertEqual(merged.lifetimeBossEncounters, 5)
    }

}
