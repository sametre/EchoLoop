import XCTest
@testable import EchoLoop

final class EchoKindTests: XCTestCase {
    func testSpecialEchoesUnlockByStage() {
        XCTAssertEqual(EchoKind.kind(forSpawnIndex: 4, stage: 2), .classic)
        XCTAssertEqual(EchoKind.kind(forSpawnIndex: 4, stage: 3), .hunter)
        XCTAssertEqual(EchoKind.kind(forSpawnIndex: 5, stage: 5), .mirror)
        XCTAssertEqual(EchoKind.kind(forSpawnIndex: 7, stage: 6), .phase)
    }

    func testClassicFallbackIsDeterministic() {
        XCTAssertEqual(EchoKind.kind(forSpawnIndex: 3, stage: 8), .classic)
        XCTAssertEqual(EchoKind.kind(forSpawnIndex: 8, stage: 8), .hunter)
    }
}
