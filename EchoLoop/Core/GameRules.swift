import CoreGraphics
import Foundation

enum GameRules {
    static func stage(for elapsed: TimeInterval) -> Int {
        max(1, Int(max(0, elapsed) / AppConfig.Game.stageLength) + 1)
    }

    static func echoInterval(stage: Int) -> TimeInterval {
        max(
            AppConfig.Game.minimumEchoInterval,
            AppConfig.Game.baseEchoInterval - Double(max(0, stage - 1)) * 0.25
        )
    }

    static func hazardInterval(stage: Int) -> TimeInterval {
        max(
            AppConfig.Game.hazardMinimumInterval,
            AppConfig.Game.hazardBaseInterval - Double(max(0, stage - AppConfig.Game.hazardStartStage)) * 0.45
        )
    }

    static func gameplayMargin(stage: Int) -> CGFloat {
        min(66, 28 + CGFloat(max(0, stage - 3)) * 5)
    }

    static func echoSpeedFactor(stage: Int) -> Double {
        max(0.68, 1.0 - Double(max(0, stage - 1)) * 0.035)
    }

    static func scorePointsPerSecond(stage: Int) -> Double {
        Double(8 + max(1, stage) * 2)
    }

    static func clampedFrameDelta(_ value: TimeInterval) -> TimeInterval {
        min(max(0, value), 1.0 / 20.0)
    }
}
