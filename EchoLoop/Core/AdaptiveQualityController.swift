import Foundation

enum RenderingQuality: Int, CaseIterable, Equatable {
    case low = 0
    case balanced = 1
    case high = 2

    var particleMultiplier: Double {
        switch self {
        case .low: return 0.42
        case .balanced: return 0.72
        case .high: return 1.0
        }
    }
}

struct AdaptiveQualityController {
    private(set) var quality: RenderingQuality = .high
    private(set) var smoothedFrameDelta: TimeInterval = 1.0 / 60.0
    private var slowSamples = 0
    private var fastSamples = 0

    mutating func reset() {
        quality = .high
        smoothedFrameDelta = 1.0 / 60.0
        slowSamples = 0
        fastSamples = 0
    }

    @discardableResult
    mutating func observe(frameDelta: TimeInterval, enabled: Bool) -> RenderingQuality {
        guard enabled else {
            quality = .high
            slowSamples = 0
            fastSamples = 0
            return quality
        }
        guard frameDelta > 0, frameDelta < 0.25 else { return quality }

        let alpha = 0.08
        smoothedFrameDelta = (smoothedFrameDelta * (1 - alpha)) + (frameDelta * alpha)

        if smoothedFrameDelta > 1.0 / 48.0 {
            slowSamples += 1
            fastSamples = 0
        } else if smoothedFrameDelta < 1.0 / 57.0 {
            fastSamples += 1
            slowSamples = max(0, slowSamples - 1)
        } else {
            slowSamples = max(0, slowSamples - 1)
            fastSamples = max(0, fastSamples - 1)
        }

        if slowSamples >= 45, quality != .low {
            quality = RenderingQuality(rawValue: quality.rawValue - 1) ?? .low
            slowSamples = 0
            fastSamples = 0
        } else if fastSamples >= 180, quality != .high {
            quality = RenderingQuality(rawValue: quality.rawValue + 1) ?? .high
            slowSamples = 0
            fastSamples = 0
        }

        return quality
    }
}
