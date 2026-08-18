import Foundation

struct PersistenceLoadResult<Value> {
    let value: Value?
    let source: String
    let recoveredFromBackup: Bool
}

final class ProfilePersistence {
    static let shared = ProfilePersistence()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load<T: Decodable>(_ type: T.Type, primaryKey: String, backupKey: String, legacyKeys: [String]) -> PersistenceLoadResult<T> {
        if let value = decode(type, data: defaults.data(forKey: primaryKey)) {
            return .init(value: value, source: primaryKey, recoveredFromBackup: false)
        }

        if let value = decode(type, data: defaults.data(forKey: backupKey)) {
            AppLogger.persistence.warning("Primary save could not be decoded; recovered from backup.")
            return .init(value: value, source: backupKey, recoveredFromBackup: true)
        }

        for key in legacyKeys {
            if let value = decode(type, data: defaults.data(forKey: key)) {
                AppLogger.persistence.notice("Migrating legacy save key: \(key, privacy: .public)")
                return .init(value: value, source: key, recoveredFromBackup: false)
            }
        }

        return .init(value: nil, source: "new", recoveredFromBackup: false)
    }

    @discardableResult
    func save<T: Codable>(_ value: T, primaryKey: String, backupKey: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(value)
            if let current = defaults.data(forKey: primaryKey),
               (try? JSONDecoder().decode(T.self, from: current)) != nil {
                // Keep the last known-good primary as the rollback copy.
                defaults.set(current, forKey: backupKey)
            } else if defaults.data(forKey: backupKey) == nil {
                // Seed a recovery copy on the very first successful save.
                defaults.set(data, forKey: backupKey)
            }
            defaults.set(data, forKey: primaryKey)
            return true
        } catch {
            AppLogger.persistence.error("Save encode failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
