import Combine
import Foundation
import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

#if canImport(GoogleMobileAds)
@MainActor
final class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    @Published private(set) var isStarted = false
    private var started = false

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
        AppLogger.ads.notice("Google Mobile Ads SDK started for banner ads.")
    }

    func registerCompletedRun() {}

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

    @Published private(set) var isStarted = false

    private init() {}

    func start() {
        AppLogger.ads.notice("Google Mobile Ads SDK is unavailable; ads remain disabled.")
    }

    func registerCompletedRun() {}

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
