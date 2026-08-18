import XCTest
@testable import EchoLoop

final class TutorialRunCoordinatorTests: XCTestCase {
    func testTutorialProgressesInOrder() {
        XCTAssertEqual(TutorialRunCoordinator.step(elapsed: 1, dashes: 0, shards: 0, echoes: 0), .move)
        XCTAssertEqual(TutorialRunCoordinator.step(elapsed: 3, dashes: 0, shards: 0, echoes: 0), .dash)
        XCTAssertEqual(TutorialRunCoordinator.step(elapsed: 5, dashes: 1, shards: 0, echoes: 0), .collectShard)
        XCTAssertEqual(TutorialRunCoordinator.step(elapsed: 8, dashes: 1, shards: 1, echoes: 0), .meetEcho)
        XCTAssertEqual(TutorialRunCoordinator.step(elapsed: 12, dashes: 1, shards: 1, echoes: 1), .survive)
        XCTAssertEqual(TutorialRunCoordinator.step(elapsed: 24, dashes: 1, shards: 1, echoes: 1), .complete)
    }
}
