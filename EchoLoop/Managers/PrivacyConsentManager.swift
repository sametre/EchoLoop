import Combine
import Foundation

#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

@MainActor
final class PrivacyConsentManager: ObservableObject {
    static let shared = PrivacyConsentManager()

    @Published private(set) var canRequestAds = false
    @Published private(set) var privacyOptionsRequired = false
    @Published private(set) var isReady = false
    @Published private(set) var lastError: String?

    private var didStartAds = false

    private init() {}

    func gatherConsentAndStartAds() async {
        #if canImport(UserMessagingPlatform)
        let parameters = RequestParameters()
        lastError = nil

        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
                Task { @MainActor in
                    if let error {
                        self?.lastError = error.localizedDescription
                        AppLogger.privacy.error("Consent info update failed: \(error.localizedDescription, privacy: .public)")
                    }
                    self?.refreshState()
                    continuation.resume()
                }
            }
        }

        do {
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            lastError = error.localizedDescription
            AppLogger.privacy.error("Consent form failed: \(error.localizedDescription, privacy: .public)")
        }

        refreshState()
        isReady = true
        startAdsIfPossible()
        #else
        canRequestAds = false
        privacyOptionsRequired = false
        isReady = true
        lastError = nil
        AppLogger.privacy.notice("User Messaging Platform SDK is unavailable; consent flow skipped.")
        #endif
    }

    func presentPrivacyOptions() async {
        #if canImport(UserMessagingPlatform)
        lastError = nil
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            AnalyticsManager.shared.track(.privacyOptionsOpened)
            refreshState()
            startAdsIfPossible()
        } catch {
            lastError = error.localizedDescription
            AppLogger.privacy.error("Privacy options failed: \(error.localizedDescription, privacy: .public)")
        }
        #else
        lastError = nil
        AppLogger.privacy.notice("User Messaging Platform SDK is unavailable; privacy options skipped.")
        #endif
    }

    private func refreshState() {
        #if canImport(UserMessagingPlatform)
        canRequestAds = ConsentInformation.shared.canRequestAds
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        AppLogger.privacy.debug("Consent state refreshed. canRequestAds=\(self.canRequestAds, privacy: .public)")
        #endif
    }

    private func startAdsIfPossible() {
        guard canRequestAds, !didStartAds else { return }
        AdManager.shared.start()
        didStartAds = AdManager.shared.isStarted
    }

    #if DEBUG
    func resetConsentForDevelopment() {
        #if canImport(UserMessagingPlatform)
        ConsentInformation.shared.reset()
        #endif
        canRequestAds = false
        privacyOptionsRequired = false
        isReady = false
        didStartAds = false
        lastError = nil
        AppLogger.privacy.notice("Consent state reset for development.")
    }
    #endif
}
