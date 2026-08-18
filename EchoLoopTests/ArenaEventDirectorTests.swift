import XCTest
@testable import EchoLoop

final class ArenaEventDirectorTests: XCTestCase {
    func testEventIntervalTightensButHasFloor() {
        XCTAssertGreaterThan(ArenaEventDirector.interval(stage: 4), ArenaEventDirector.interval(stage: 12))
        XCTAssertGreaterThanOrEqual(ArenaEventDirector.interval(stage: 100), 15)
    }

    func testEarlyRotationExcludesOverdrive() {
        let events = (0..<8).map { ArenaEventDirector.event(forIndex: $0, stage: 4) }
        XCTAssertFalse(events.contains(.overdrive))
        XCTAssertTrue(events.contains(.signalBlackout))
        XCTAssertTrue(events.contains(.shardStorm))
    }

    func testLateRotationIncludesEveryEvent() {
        let events = Set((0..<9).map { ArenaEventDirector.event(forIndex: $0, stage: 7) })
        XCTAssertEqual(events, Set(ArenaEventKind.allCases))
    }
}
