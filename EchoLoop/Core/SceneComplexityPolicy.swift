import Foundation

enum SceneComplexityPolicy {
    static func maximumActiveEchoes(stage: Int, quality: RenderingQuality) -> Int {
        let base: Int
        switch quality {
        case .low: base = 10
        case .balanced: base = 14
        case .high: base = 18
        }
        return min(22, base + max(0, stage - 8) / 4)
    }

    static func starCount(quality: RenderingQuality, reducedMotion: Bool) -> Int {
        if reducedMotion { return 36 }
        switch quality {
        case .low: return 48
        case .balanced: return 72
        case .high: return 95
        }
    }

    static func particleCount(requested: Int, quality: RenderingQuality, reducedMotion: Bool) -> Int {
        guard requested > 0 else { return 0 }
        let motionMultiplier = reducedMotion ? 0.48 : 1.0
        let scaled = Double(requested) * quality.particleMultiplier * motionMultiplier
        return max(1, Int(scaled.rounded()))
    }

    static func trailBirthRate(base: CGFloat, quality: RenderingQuality, reducedMotion: Bool) -> CGFloat {
        let motionMultiplier = reducedMotion ? 0.42 : 1.0
        return max(8, base * CGFloat(quality.particleMultiplier * motionMultiplier))
    }
}
