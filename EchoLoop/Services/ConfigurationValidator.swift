import Foundation

struct ConfigurationIssue: Identifiable, Hashable {
    enum Severity: String {
        case info = "INFO"
        case warning = "WARNING"
        case blocking = "BLOCKING"
    }

    let id: String
    let severity: Severity
    let title: String
    let detail: String
}

enum ConfigurationValidator {
    static var issues: [ConfigurationIssue] {
        var result: [ConfigurationIssue] = []

        if AppConfig.Game.leaderboardID.contains("CHANGE_ME") {
            result.append(.init(
                id: "leaderboard-placeholder",
                severity: .warning,
                title: "Game Center leaderboard not configured",
                detail: "Replace the leaderboard placeholder in AppConfig.swift before App Store release."
            ))
        }

        let placeholderAchievements = [
            AppConfig.Game.Achievements.survive60,
            AppConfig.Game.Achievements.survive120,
            AppConfig.Game.Achievements.echoes10,
            AppConfig.Game.Achievements.closeCalls15,
            AppConfig.Game.Achievements.stage6,
            AppConfig.Game.Achievements.shards100,
            AppConfig.Game.Achievements.dashes100,
            AppConfig.Game.Achievements.specialEchoes50,
            AppConfig.Game.Achievements.arenaEvents25,
            AppConfig.Game.Achievements.bossEncounters10
        ].contains(where: { $0.contains("CHANGE_ME") })

        if placeholderAchievements {
            result.append(.init(
                id: "achievement-placeholder",
                severity: .warning,
                title: "Game Center achievements not configured",
                detail: "Achievement identifiers are still placeholders. Gameplay remains functional, but achievements will not submit."
            ))
        }


        if AppConfig.Cloud.enabled && !AppConfig.Cloud.isConfigured {
            result.append(.init(
                id: "cloud-placeholder",
                severity: .blocking,
                title: "CloudKit container not configured",
                detail: "Disable Cloud sync or replace the CloudKit container placeholder before release."
            ))
        } else if !AppConfig.Cloud.enabled {
            result.append(.init(
                id: "cloud-disabled",
                severity: .info,
                title: "Cloud sync staged",
                detail: "CloudKit support is compiled but disabled until an iCloud container is configured."
            ))
        }

        return result
    }

    static var hasBlockingIssue: Bool {
        issues.contains(where: { $0.severity == .blocking })
    }

    static var adsMayStart: Bool {
        true
    }
}
