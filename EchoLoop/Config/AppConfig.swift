import Foundation
import CoreGraphics

enum AppConfig {
    static let appName = "ECHO LOOP"
    static let bundleIdentifier = "com.sameter.echoloop"
    static let marketingVersion = "1.0.0"
    static let buildNumber = 10

    enum Runtime {
        static let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        #if DEBUG
        static let diagnosticsEnabled = true
        #else
        static let diagnosticsEnabled = false
        #endif
    }

    enum Game {
        static let baseEchoInterval: TimeInterval = 5.0
        static let minimumEchoInterval: TimeInterval = 3.5
        static let playerSpeed: CGFloat = 405
        static let collisionDistance: CGFloat = 23
        static let closeCallDistance: CGFloat = 58
        static let shardSpawnInterval: TimeInterval = 5.5
        static let maximumShardsOnScreen = 3
        static let stageLength: TimeInterval = 20
        static let dashDistance: CGFloat = 118
        static let dashCooldown: TimeInterval = 4.5
        static let dashInvulnerability: TimeInterval = 0.24
        static let maximumCombo = 8
        static let comboLifetime: TimeInterval = 4.0
        static let arenaEventStartStage = 4
        static let overdriveSpeedMultiplier: CGFloat = 1.28
        static let phaseCollisionDelay: TimeInterval = 0.75
        static let bossEncounterStartStage = 7
        static let tutorialCompletionSeconds: TimeInterval = 24

        static let hazardStartStage = 3
        static let hazardBaseInterval: TimeInterval = 7.0
        static let hazardMinimumInterval: TimeInterval = 4.2
        static let hazardWarningDuration: TimeInterval = 1.25
        static let hazardActiveDuration: TimeInterval = 1.0
        static let hazardRadius: CGFloat = 46

        static let leaderboardID = "CHANGE_ME_ECHO_LONGEST_RUN"

        enum Achievements {
            static let survive60 = "CHANGE_ME_SURVIVE_60"
            static let survive120 = "CHANGE_ME_SURVIVE_120"
            static let echoes10 = "CHANGE_ME_ECHOES_10"
            static let closeCalls15 = "CHANGE_ME_CLOSE_CALLS_15"
            static let stage6 = "CHANGE_ME_STAGE_6"
            static let shards100 = "CHANGE_ME_SHARDS_100"
            static let dashes100 = "CHANGE_ME_DASHES_100"
            static let specialEchoes50 = "CHANGE_ME_SPECIAL_ECHOES_50"
            static let arenaEvents25 = "CHANGE_ME_ARENA_EVENTS_25"
            static let bossEncounters10 = "CHANGE_ME_BOSS_ENCOUNTERS_10"
        }
    }

    enum Cloud {
        // CloudKit code is compiled and ready, but remains off until the iCloud capability
        // and a production container are configured in the Apple Developer portal.
        static let enabled = false
        static let containerIdentifier = "CHANGE_ME_iCloud.com.sameter.echoloop"
        static let profileRecordName = "player-profile-v10"

        static var isConfigured: Bool {
            enabled && !containerIdentifier.contains("CHANGE_ME")
        }
    }

    enum AdMob {
        static let appID = "ca-app-pub-3321006469806168~5262008450"
        static let banner = "ca-app-pub-3321006469806168/8310843623"

        static var isConfigured: Bool {
            appID.range(of: #"^ca-app-pub-\d{16}~\d{10}$"#, options: .regularExpression) != nil &&
            banner.range(of: #"^ca-app-pub-\d{16}/\d{10}$"#, options: .regularExpression) != nil
        }
    }
}
