import XCTest
@testable import EchoLoop

final class BossEncounterDirectorTests: XCTestCase {
    func testBossStagesRepeatEveryThreeStages() {
        XCTAssertTrue(BossEncounterDirector.shouldStart(stage: 7, lastStartedStage: 0))
        XCTAssertTrue(BossEncounterDirector.shouldStart(stage: 10, lastStartedStage: 7))
        XCTAssertFalse(BossEncounterDirector.shouldStart(stage: 8, lastStartedStage: 7))
        XCTAssertFalse(BossEncounterDirector.shouldStart(stage: 7, lastStartedStage: 7))
    }

    func testBossRotationIsDeterministic() {
        XCTAssertEqual(BossEncounterDirector.boss(for: 7), .chronoWarden)
        XCTAssertEqual(BossEncounterDirector.boss(for: 10), .prismRegent)
        XCTAssertEqual(BossEncounterDirector.boss(for: 13), .voidSentinel)
        XCTAssertEqual(BossEncounterDirector.boss(for: 16), .chronoWarden)
    }
}
