import Combine
import GameKit
import UIKit

@MainActor
final class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()

    @Published private(set) var isAuthenticated = false
    @Published private(set) var lastError: String?

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let viewController {
                    UIApplication.shared.echoTopViewController?.present(viewController, animated: true)
                    return
                }

                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self?.lastError = error?.localizedDescription
                GKAccessPoint.shared.isActive = GKLocalPlayer.local.isAuthenticated

                if let error {
                    AppLogger.gameCenter.error("Authentication failed: \(error.localizedDescription, privacy: .public)")
                } else if GKLocalPlayer.local.isAuthenticated {
                    AppLogger.gameCenter.notice("Game Center authenticated.")
                }
            }
        }
    }

    func submitRun(seconds: TimeInterval, echoes: Int, closeCalls: Int) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        submitScore(seconds: seconds)
        reportAchievement(id: AppConfig.Game.Achievements.survive60, percent: min(100, seconds / 60 * 100))
        reportAchievement(id: AppConfig.Game.Achievements.survive120, percent: min(100, seconds / 120 * 100))
        reportAchievement(id: AppConfig.Game.Achievements.echoes10, percent: min(100, Double(echoes) / 10 * 100))
        reportAchievement(id: AppConfig.Game.Achievements.closeCalls15, percent: min(100, Double(closeCalls) / 15 * 100))
    }


    func syncProfileAchievements(_ profile: PlayerProfile) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let snapshot = profile.achievementSnapshot
        let mappings: [(String, AchievementDefinition)] = [
            (AppConfig.Game.Achievements.survive60, AchievementCatalog.all[0]),
            (AppConfig.Game.Achievements.survive120, AchievementCatalog.all[1]),
            (AppConfig.Game.Achievements.stage6, AchievementCatalog.all[2]),
            (AppConfig.Game.Achievements.shards100, AchievementCatalog.all[3]),
            (AppConfig.Game.Achievements.dashes100, AchievementCatalog.all[4]),
            (AppConfig.Game.Achievements.specialEchoes50, AchievementCatalog.all[5]),
            (AppConfig.Game.Achievements.arenaEvents25, AchievementCatalog.all[6]),
            (AppConfig.Game.Achievements.bossEncounters10, AchievementCatalog.all[7])
        ]

        for (gameCenterID, definition) in mappings {
            reportAchievement(id: gameCenterID, percent: definition.progress(using: snapshot) * 100)
        }
    }

    func showDashboard() {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate()
            return
        }
        let controller = GKGameCenterViewController(state: .leaderboards)
        controller.gameCenterDelegate = GameCenterDismissDelegate.shared
        UIApplication.shared.echoTopViewController?.present(controller, animated: true)
    }

    private func submitScore(seconds: TimeInterval) {
        guard !AppConfig.Game.leaderboardID.contains("CHANGE_ME") else { return }
        let milliseconds = max(0, Int(seconds * 1000))
        GKLeaderboard.submitScore(
            milliseconds,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [AppConfig.Game.leaderboardID]
        ) { error in
            if let error {
                AppLogger.gameCenter.error("Leaderboard submit failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func reportAchievement(id: String, percent: Double) {
        guard !id.contains("CHANGE_ME") else { return }
        let achievement = GKAchievement(identifier: id)
        achievement.percentComplete = min(100, max(0, percent))
        achievement.showsCompletionBanner = true
        GKAchievement.report([achievement]) { error in
            if let error {
                AppLogger.gameCenter.error("Achievement submit failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

private final class GameCenterDismissDelegate: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismissDelegate()

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
