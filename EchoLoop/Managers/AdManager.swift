import Combine
import Foundation
import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

#if canImport(GoogleMobileAds)
@MainActor
final class AdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = AdManager()

    @Published private(set) var rewardedReady = false
    @Published private(set) var interstitialReady = false
    @Published private(set) var isStarted = false
    @Published private(set) var fullScreenAdVisible = false

    private var interstitial: InterstitialAd?
    private var rewarded: RewardedAd?
    private var completedRunCounter = 0
    private var started = false
    private var loadingInterstitial = false
    private var loadingRewarded = false
    private var pendingRewardCompletion: ((Bool) -> Void)?

    func start() {
        guard !started else { return }
        guard PrivacyConsentManager.shared.canRequestAds else {
            AppLogger.ads.notice("Ad SDK start deferred because consent is not ready.")
            return
        }
        guard ConfigurationValidator.adsMayStart else {
            AppLogger.ads.error("Ad SDK blocked: release build is still configured with Google test IDs.")
            return
        }

        started = true
        isStarted = true
        MobileAds.shared.start()
        AppLogger.ads.notice("Google Mobile Ads SDK started.")
        Task {
            await loadInterstitial()
            await loadRewarded()
        }
    }

    func loadInterstitial() async {
        guard isStarted, !loadingInterstitial else { return }
        guard !StoreManager.shared.adsRemoved, PrivacyConsentManager.shared.canRequestAds else { return }
        guard ConfigurationValidator.adsMayStart else { return }

        loadingInterstitial = true
        defer { loadingInterstitial = false }

        do {
            let loaded = try await InterstitialAd.load(with: AppConfig.AdMob.interstitial, request: Request())
            loaded.fullScreenContentDelegate = self
            interstitial = loaded
            interstitialReady = true
            AppLogger.ads.debug("Interstitial ready.")
        } catch {
            interstitial = nil
            interstitialReady = false
            AppLogger.ads.error("Interstitial load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func loadRewarded() async {
        guard isStarted, !loadingRewarded else { return }
        guard PrivacyConsentManager.shared.canRequestAds else { return }
        guard ConfigurationValidator.adsMayStart else { return }

        loadingRewarded = true
        defer { loadingRewarded = false }

        do {
            let loaded = try await RewardedAd.load(with: AppConfig.AdMob.rewarded, request: Request())
            loaded.fullScreenContentDelegate = self
            rewarded = loaded
            rewardedReady = true
            AppLogger.ads.debug("Rewarded ad ready.")
        } catch {
            rewarded = nil
            rewardedReady = false
            AppLogger.ads.error("Rewarded load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func registerCompletedRun() {
        completedRunCounter += 1
        guard !StoreManager.shared.adsRemoved, PrivacyConsentManager.shared.canRequestAds else { return }
        guard ConfigurationValidator.adsMayStart else { return }
        guard completedRunCounter % 3 == 0 else { return }

        guard let interstitial else {
            Task { await loadInterstitial() }
            return
        }

        interstitialReady = false
        fullScreenAdVisible = true
        interstitial.present(from: nil)
        self.interstitial = nil
    }

    func showRewardedRevive(completion: @escaping (Bool) -> Void) {
        if StoreManager.shared.adsRemoved {
            completion(true)
            return
        }

        guard pendingRewardCompletion == nil else {
            completion(false)
            return
        }
        guard PrivacyConsentManager.shared.canRequestAds, ConfigurationValidator.adsMayStart else {
            completion(false)
            return
        }
        guard let rewarded else {
            completion(false)
            Task { await loadRewarded() }
            return
        }

        pendingRewardCompletion = completion
        rewardedReady = false
        fullScreenAdVisible = true
        rewarded.present(from: nil) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.pendingRewardCompletion?(true)
                self.pendingRewardCompletion = nil
            }
        }
        self.rewarded = nil
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        fullScreenAdVisible = true
        AudioManager.shared.duckMusic(true)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        fullScreenAdVisible = false
        AudioManager.shared.duckMusic(false)
        if let pendingRewardCompletion {
            pendingRewardCompletion(false)
            self.pendingRewardCompletion = nil
        }
        Task {
            await loadInterstitial()
            await loadRewarded()
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        fullScreenAdVisible = false
        AudioManager.shared.duckMusic(false)
        pendingRewardCompletion?(false)
        pendingRewardCompletion = nil
        AppLogger.ads.error("Full-screen ad presentation failed: \(error.localizedDescription, privacy: .public)")
        Task {
            await loadInterstitial()
            await loadRewarded()
        }
    }
}

struct AdaptiveBannerView: UIViewRepresentable {
    let width: CGFloat

    func makeUIView(context: Context) -> BannerView {
        let size = largeAnchoredAdaptiveBanner(width: max(1, width))
        let banner = BannerView(adSize: size)
        banner.adUnitID = AppConfig.AdMob.banner
        banner.rootViewController = UIApplication.shared.echoTopViewController
        if PrivacyConsentManager.shared.canRequestAds,
           AdManager.shared.isStarted,
           ConfigurationValidator.adsMayStart {
            banner.load(Request())
        }
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.rootViewController = UIApplication.shared.echoTopViewController
    }
}

extension UIApplication {
    var echoTopViewController: UIViewController? {
        let scene = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let root = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        return root?.echoTopMost
    }
}

private extension UIViewController {
    var echoTopMost: UIViewController {
        if let presented = presentedViewController { return presented.echoTopMost }
        if let nav = self as? UINavigationController { return nav.visibleViewController?.echoTopMost ?? nav }
        if let tab = self as? UITabBarController { return tab.selectedViewController?.echoTopMost ?? tab }
        return self
    }
}
#else
@MainActor
final class AdManager: ObservableObject {
    static let shared = AdManager()

    @Published private(set) var rewardedReady = false
    @Published private(set) var interstitialReady = false
    @Published private(set) var isStarted = false
    @Published private(set) var fullScreenAdVisible = false

    private init() {}

    func start() {
        AppLogger.ads.notice("Google Mobile Ads SDK is unavailable; ads remain disabled.")
    }

    func loadInterstitial() async {}

    func loadRewarded() async {}

    func registerCompletedRun() {}

    func showRewardedRevive(completion: @escaping (Bool) -> Void) {
        completion(StoreManager.shared.adsRemoved)
    }
}

struct AdaptiveBannerView: UIViewRepresentable {
    let width: CGFloat

    func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero)
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension UIApplication {
    var echoTopViewController: UIViewController? {
        let scene = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let root = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        return root?.echoTopMost
    }
}

private extension UIViewController {
    var echoTopMost: UIViewController {
        if let presented = presentedViewController { return presented.echoTopMost }
        if let nav = self as? UINavigationController { return nav.visibleViewController?.echoTopMost ?? nav }
        if let tab = self as? UITabBarController { return tab.selectedViewController?.echoTopMost ?? tab }
        return self
    }
}
#endif
