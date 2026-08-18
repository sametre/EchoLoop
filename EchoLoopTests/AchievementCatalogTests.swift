import XCTest
@testable import EchoLoop

final class AchievementCatalogTests: XCTestCase {
    func testProgressClampsAtOne() {
        let snapshot = AchievementSnapshot(
            bestTime: 500,
            highestStage: 99,
            lifetimeShards: 9999,
            lifetimeDashes: 9999,
            lifetimeSpecialEchoes: 9999,
            lifetimeArenaEvents: 9999,
            lifetimeBossEncounters: 9999
        )
        XCTAssertTrue(AchievementCatalog.all.allSatisfy { $0.progress(using: snapshot) == 1 })
    }

    func testZeroSnapshotHasNoCompletedAchievements() {
        let snapshot = AchievementSnapshot(
            bestTime: 0,
            highestStage: 1,
            lifetimeShards: 0,
            lifetimeDashes: 0,
            lifetimeSpecialEchoes: 0,
            lifetimeArenaEvents: 0,
            lifetimeBossEncounters: 0
        )
        XCTAssertFalse(AchievementCatalog.all.contains { $0.progress(using: snapshot) >= 1 })
    }
}
