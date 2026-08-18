import StoreKit
import UIKit

@MainActor
final class ReviewManager {
    static let shared = ReviewManager()

    private let defaults = UserDefaults.standard
    private let lastPromptRunsKey = "echo.review.lastPromptRuns"

    private init() {}

    func considerPrompt(totalRuns: Int, bestTime: TimeInterval) {
        guard totalRuns >= 8, bestTime >= 45 else { return }
        let lastPromptRuns = defaults.integer(forKey: lastPromptRunsKey)
        guard totalRuns - lastPromptRuns >= 12 || lastPromptRuns == 0 else { return }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }

        defaults.set(totalRuns, forKey: lastPromptRunsKey)
        AppStore.requestReview(in: scene)
        AppLogger.app.notice("App Store review prompt requested.")
    }
}
