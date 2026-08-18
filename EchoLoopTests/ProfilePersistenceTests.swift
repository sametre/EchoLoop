import XCTest
@testable import EchoLoop

final class ProfilePersistenceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "EchoLoopTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testFirstSaveSeedsRecoveryBackup() throws {
        let persistence = ProfilePersistence(defaults: defaults)
        var save = PlayerProfile.SaveData()
        save.coins = 777

        XCTAssertTrue(persistence.save(save, primaryKey: "primary", backupKey: "backup"))
        XCTAssertNotNil(defaults.data(forKey: "primary"))
        XCTAssertNotNil(defaults.data(forKey: "backup"))
    }

    func testCorruptedPrimaryRecoversFromBackup() throws {
        let persistence = ProfilePersistence(defaults: defaults)
        var first = PlayerProfile.SaveData()
        first.coins = 100
        var second = first
        second.coins = 200

        XCTAssertTrue(persistence.save(first, primaryKey: "primary", backupKey: "backup"))
        XCTAssertTrue(persistence.save(second, primaryKey: "primary", backupKey: "backup"))
        defaults.set(Data("not-json".utf8), forKey: "primary")

        let result: PersistenceLoadResult<PlayerProfile.SaveData> = persistence.load(
            PlayerProfile.SaveData.self,
            primaryKey: "primary",
            backupKey: "backup",
            legacyKeys: []
        )

        XCTAssertTrue(result.recoveredFromBackup)
        XCTAssertEqual(result.source, "backup")
        XCTAssertEqual(result.value?.coins, 100)
    }

    func testLegacySaveLoadsWhenPrimaryAndBackupAreMissing() throws {
        let persistence = ProfilePersistence(defaults: defaults)
        var legacy = PlayerProfile.SaveData()
        legacy.schemaVersion = 3
        legacy.coins = 321
        defaults.set(try JSONEncoder().encode(legacy), forKey: "legacy")

        let result: PersistenceLoadResult<PlayerProfile.SaveData> = persistence.load(
            PlayerProfile.SaveData.self,
            primaryKey: "primary",
            backupKey: "backup",
            legacyKeys: ["legacy"]
        )

        XCTAssertFalse(result.recoveredFromBackup)
        XCTAssertEqual(result.source, "legacy")
        XCTAssertEqual(result.value?.coins, 321)
    }
}
