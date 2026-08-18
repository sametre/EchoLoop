import Combine
import StoreKit
import Foundation

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedIDs: Set<String> = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = observeTransactions()
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    deinit { updatesTask?.cancel() }

    var adsRemoved: Bool { purchasedIDs.contains(AppConfig.Store.removeAds) }
    var premiumUnlocked: Bool { purchasedIDs.contains(AppConfig.Store.premiumNeon) }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        lastError = nil
        defer { isLoadingProducts = false }

        do {
            let loaded = try await Product.products(for: AppConfig.Store.productIDs)
            products = loaded.sorted { $0.price < $1.price }
            if loaded.count != AppConfig.Store.productIDs.count {
                AppLogger.store.warning("Some configured StoreKit products were not returned by App Store Connect.")
            } else {
                AppLogger.store.debug("Loaded \(loaded.count, privacy: .public) StoreKit products.")
            }
        } catch {
            lastError = error.localizedDescription
            AppLogger.store.error("Product load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func purchase(_ product: Product) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        lastError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                Haptics.success()
                AudioManager.shared.play(.revive)
                AnalyticsManager.shared.track(.purchaseCompleted, properties: ["product_id": transaction.productID])
                AppLogger.store.notice("Purchase completed: \(transaction.productID, privacy: .public)")
            case .pending:
                AppLogger.store.notice("Purchase pending: \(product.id, privacy: .public)")
            case .userCancelled:
                AppLogger.store.debug("Purchase cancelled: \(product.id, privacy: .public)")
            @unknown default:
                AppLogger.store.warning("Unknown purchase result for \(product.id, privacy: .public)")
            }
        } catch {
            lastError = error.localizedDescription
            AppLogger.store.error("Purchase failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func restore() async {
        guard !isRestoring else { return }
        isRestoring = true
        lastError = nil
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            Haptics.success()
            AppLogger.store.notice("Purchases restored.")
        } catch {
            lastError = error.localizedDescription
            AppLogger.store.error("Restore failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func refreshEntitlements() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            guard AppConfig.Store.productIDs.contains(transaction.productID) else { continue }
            active.insert(transaction.productID)
        }
        purchasedIDs = active
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.refreshEntitlements()
                    AppLogger.store.notice("Transaction update processed: \(transaction.productID, privacy: .public)")
                } catch {
                    self.lastError = error.localizedDescription
                    AppLogger.store.error("Transaction update verification failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified: throw StoreError.failedVerification
        }
    }

    enum StoreError: LocalizedError {
        case failedVerification

        var errorDescription: String? {
            "The App Store transaction could not be verified."
        }
    }
}
