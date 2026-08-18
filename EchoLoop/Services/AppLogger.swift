import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? AppConfig.bundleIdentifier

    static let app = Logger(subsystem: subsystem, category: "App")
    static let gameplay = Logger(subsystem: subsystem, category: "Gameplay")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let ads = Logger(subsystem: subsystem, category: "Ads")
    static let gameCenter = Logger(subsystem: subsystem, category: "GameCenter")
    static let audio = Logger(subsystem: subsystem, category: "Audio")
    static let privacy = Logger(subsystem: subsystem, category: "Privacy")
    static let analytics = Logger(subsystem: subsystem, category: "Analytics")
    static let cloud = Logger(subsystem: subsystem, category: "CloudSync")
}
