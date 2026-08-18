import Foundation
import UIKit

enum BossEchoKind: String, Codable, CaseIterable, Identifiable {
    case chronoWarden
    case prismRegent
    case voidSentinel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chronoWarden: return "CHRONO WARDEN"
        case .prismRegent: return "PRISM REGENT"
        case .voidSentinel: return "VOID SENTINEL"
        }
    }

    var symbol: String {
        switch self {
        case .chronoWarden: return "clock.arrow.2.circlepath"
        case .prismRegent: return "triangle.fill"
        case .voidSentinel: return "circle.hexagongrid.fill"
        }
    }

    var echoKind: EchoKind {
        switch self {
        case .chronoWarden: return .hunter
        case .prismRegent: return .mirror
        case .voidSentinel: return .phase
        }
    }

    var tint: UIColor {
        switch self {
        case .chronoWarden: return UIColor(hex: "FF3D81")
        case .prismRegent: return UIColor(hex: "A86BFF")
        case .voidSentinel: return UIColor(hex: "42F5C8")
        }
    }

    var duration: TimeInterval {
        switch self {
        case .chronoWarden: return 11.0
        case .prismRegent: return 12.0
        case .voidSentinel: return 13.0
        }
    }

    var speedMultiplier: Double {
        switch self {
        case .chronoWarden: return 0.78
        case .prismRegent: return 0.86
        case .voidSentinel: return 0.82
        }
    }

    var collisionMultiplier: CGFloat {
        switch self {
        case .chronoWarden: return 1.18
        case .prismRegent: return 1.12
        case .voidSentinel: return 1.02
        }
    }

    var scaleMultiplier: CGFloat {
        switch self {
        case .chronoWarden: return 1.34
        case .prismRegent: return 1.42
        case .voidSentinel: return 1.28
        }
    }

    var survivalScoreReward: Int {
        switch self {
        case .chronoWarden: return 900
        case .prismRegent: return 1100
        case .voidSentinel: return 1350
        }
    }
}

enum BossEncounterDirector {
    static let firstStage = 7
    static let stageStride = 3

    static func shouldStart(stage: Int, lastStartedStage: Int) -> Bool {
        guard stage >= firstStage, stage != lastStartedStage else { return false }
        return (stage - firstStage) % stageStride == 0
    }

    static func boss(for stage: Int) -> BossEchoKind {
        let index = max(0, (stage - firstStage) / stageStride)
        let bosses = BossEchoKind.allCases
        return bosses[index % bosses.count]
    }
}
