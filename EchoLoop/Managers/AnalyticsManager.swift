import Foundation

@MainActor
final class AnalyticsManager {
    static let shared = AnalyticsManager()

    enum Event: String {
        case appLaunch = "app_launch"
        case onboardingCompleted = "onboarding_completed"
        case runStarted = "run_started"
        case runCompleted = "run_completed"
        case reviveUsed = "revive_used"
        case shopOpened = "shop_opened"
        case purchaseCompleted = "purchase_completed"
        case dailyRewardClaimed = "daily_reward_claimed"
        case missionClaimed = "mission_claimed"
        case arenaEventStarted = "arena_event_started"
        case cloudSyncCompleted = "cloud_sync_completed"
        case privacyOptionsOpened = "privacy_options_opened"
    }

    private init() {}

    func track(_ event: Event, properties: [String: CustomStringConvertible] = [:]) {
        #if DEBUG
        let payload = properties
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: ", ")
        AppLogger.analytics.debug("\(event.rawValue, privacy: .public) \(payload, privacy: .public)")
        #endif
        // Production hook: connect a privacy-reviewed analytics provider here.
        // Gameplay and persistence remain provider-agnostic.
    }
}
