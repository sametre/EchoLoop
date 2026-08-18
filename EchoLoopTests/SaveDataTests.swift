import XCTest
@testable import EchoLoop

final class SaveDataTests: XCTestCase {
    func testLegacyPayloadDecodesWithDefaults() throws {
        let json = #"{"schemaVersion":3,"coins":450,"bestTime":42.5,"ownedOrbs":["core"]}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PlayerProfile.SaveData.self, from: json)

        XCTAssertEqual(decoded.schemaVersion, 3)
        XCTAssertEqual(decoded.coins, 450)
        XCTAssertEqual(decoded.bestTime, 42.5, accuracy: 0.0001)
        XCTAssertEqual(decoded.bestScore, 0)
        XCTAssertTrue(decoded.ownedTrails.contains("ice"))
        XCTAssertTrue(decoded.ownedArenas.contains("deep_space"))
    }

    func testSaveRoundTrip() throws {
        var value = PlayerProfile.SaveData()
        value.coins = 1234
        value.xp = 987
        value.bestScore = 44_000
        value.ownedOrbs.insert("rose")

        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(PlayerProfile.SaveData.self, from: data)
        XCTAssertEqual(decoded, value)
    }
}
