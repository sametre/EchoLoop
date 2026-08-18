import CloudKit
import Combine
import Foundation

@MainActor
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    enum State: String {
        case disabled
        case checkingAccount
        case ready
        case syncing
        case unavailable
        case failed
    }

    @Published private(set) var state: State = AppConfig.Cloud.isConfigured ? .checkingAccount : .disabled
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var lastError: String?

    private var scheduledPush: Task<Void, Never>?
    private var isSyncing = false

    private init() {}

    var isConfigured: Bool { AppConfig.Cloud.isConfigured }

    func bootstrap() {
        guard isConfigured else {
            state = .disabled
            return
        }
        checkAccountAndSync()
    }

    func schedulePush(reason: String) {
        guard isConfigured else { return }
        scheduledPush?.cancel()
        scheduledPush = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            await self?.push(reason: reason)
        }
    }

    func syncNow() {
        guard isConfigured, !isSyncing else { return }
        checkAccountAndSync()
    }

    private func container() -> CKContainer {
        CKContainer(identifier: AppConfig.Cloud.containerIdentifier)
    }

    private func checkAccountAndSync() {
        state = .checkingAccount
        container().accountStatus { [weak self] status, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.fail(error)
                    return
                }
                guard status == .available else {
                    self.state = .unavailable
                    self.lastError = "iCloud account unavailable"
                    return
                }
                self.state = .ready
                await self.pullThenPush()
            }
        }
    }

    private func pullThenPush() async {
        guard !isSyncing else { return }
        isSyncing = true
        state = .syncing
        defer { isSyncing = false }

        let recordID = CKRecord.ID(recordName: AppConfig.Cloud.profileRecordName)
        let database = container().privateCloudDatabase

        do {
            let remote = try await fetchRecord(id: recordID, database: database)
            if let data = remote?["payload"] as? Data,
               let remoteSave = try? JSONDecoder().decode(PlayerProfile.SaveData.self, from: data) {
                _ = PlayerProfile.shared.mergeCloudSave(remoteSave)
            }
            try await saveCurrentProfile(recordID: recordID, database: database, existing: remote)
            completeSync()
        } catch let error as CKError where error.code == .unknownItem {
            do {
                try await saveCurrentProfile(recordID: recordID, database: database, existing: nil)
                completeSync()
            } catch {
                fail(error)
            }
        } catch {
            fail(error)
        }
    }

    private func push(reason: String) async {
        guard !isSyncing else { return }
        isSyncing = true
        state = .syncing
        let recordID = CKRecord.ID(recordName: AppConfig.Cloud.profileRecordName)
        let database = container().privateCloudDatabase

        do {
            let existing = try? await fetchRecord(id: recordID, database: database)
            try await saveCurrentProfile(recordID: recordID, database: database, existing: existing ?? nil)
            AppLogger.cloud.debug("Cloud push completed: \(reason, privacy: .public)")
            completeSync()
        } catch {
            fail(error)
        }
        isSyncing = false
    }

    private func fetchRecord(id: CKRecord.ID, database: CKDatabase) async throws -> CKRecord? {
        try await withCheckedThrowingContinuation { continuation in
            database.fetch(withRecordID: id) { record, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: record) }
            }
        }
    }

    private func saveCurrentProfile(recordID: CKRecord.ID, database: CKDatabase, existing: CKRecord?) async throws {
        let record = existing ?? CKRecord(recordType: "EchoPlayerProfile", recordID: recordID)
        let data = try JSONEncoder().encode(PlayerProfile.shared.exportSaveData())
        record["payload"] = data as CKRecordValue
        record["revision"] = NSNumber(value: PlayerProfile.shared.syncRevision)
        record["updatedAt"] = Date() as CKRecordValue

        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord, Error>) in
            database.save(record) { saved, error in
                if let error { continuation.resume(throwing: error) }
                else if let saved { continuation.resume(returning: saved) }
                else { continuation.resume(throwing: CloudSyncError.missingRecord) }
            }
        }
    }

    private func completeSync() {
        state = .ready
        lastError = nil
        lastSyncDate = Date()
        AnalyticsManager.shared.track(.cloudSyncCompleted)
    }

    private func fail(_ error: Error) {
        state = .failed
        lastError = error.localizedDescription
        AppLogger.cloud.error("Cloud sync failed: \(error.localizedDescription, privacy: .public)")
    }
}

private enum CloudSyncError: Error {
    case missingRecord
}
