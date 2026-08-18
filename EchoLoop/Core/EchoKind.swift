import Foundation
import UIKit

enum EchoKind: String, Codable, CaseIterable, Identifiable {
    case classic
    case hunter
    case mirror
    case phase

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: return "CLASSIC"
        case .hunter: return "HUNTER"
        case .mirror: return "MIRROR"
        case .phase: return "PHASE"
        }
    }

    var isSpecial: Bool { self != .classic }

    var color: UIColor {
        switch self {
        case .classic: return UIColor(hex: "4CCBFF")
        case .hunter: return UIColor(hex: "FF5DAE")
        case .mirror: return UIColor(hex: "A86BFF")
        case .phase: return UIColor(hex: "6BFF9A")
        }
    }

    var speedMultiplier: Double {
        switch self {
        case .classic: return 1.0
        case .hunter: return 0.82
        case .mirror: return 0.94
        case .phase: return 0.88
        }
    }

    var collisionRadiusMultiplier: CGFloat {
        switch self {
        case .classic: return 1.0
        case .hunter: return 1.08
        case .mirror: return 0.96
        case .phase: return 0.88
        }
    }

    var spawnScoreBonus: Int {
        switch self {
        case .classic: return 0
        case .hunter: return 45
        case .mirror: return 55
        case .phase: return 65
        }
    }

    static func kind(forSpawnIndex index: Int, stage: Int) -> EchoKind {
        guard stage >= 3 else { return .classic }
        let safeIndex = max(1, index)

        if stage >= 6, safeIndex % 7 == 0 { return .phase }
        if stage >= 5, safeIndex % 5 == 0 { return .mirror }
        if safeIndex % 4 == 0 { return .hunter }
        return .classic
    }
}
