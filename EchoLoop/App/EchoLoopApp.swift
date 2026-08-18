import SwiftUI

@main
struct EchoLoopApp: App {
    init() {
        AppLaunchEnvironment.prepare()
        _ = PlayerProfile.shared
        _ = SettingsStore.shared
        AudioManager.shared.configure()
        if !AppConfig.Runtime.isUITesting {
            GameCenterManager.shared.authenticate()
            CloudSyncManager.shared.bootstrap()
        }
        AnalyticsManager.shared.track(.appLaunch)

        AppLogger.app.notice("ECHO LOOP \(AppConfig.marketingVersion, privacy: .public) build \(AppConfig.buildNumber, privacy: .public) launched.")
        for issue in ConfigurationValidator.issues {
            AppLogger.app.notice("Config \(issue.severity.rawValue, privacy: .public): \(issue.title, privacy: .public)")
        }

        if !AppConfig.Runtime.isUITesting {
            Task { await PrivacyConsentManager.shared.gatherConsentAndStartAds() }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
