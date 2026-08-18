import Foundation

@main
struct LinuxCoreSmokeMain {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fputs("[FAIL] \(message)\n", stderr)
            exit(2)
        }
        print("[PASS] \(message)")
    }

    static func main() {
        expect(SeasonProgression.currentTier(for: 0) == 1, "season starts at tier 1")
        expect(SeasonProgression.currentTier(for: 8_250) == 12, "season reaches tier 12")
        expect(ArenaEventDirector.event(forIndex: 0, stage: 4) == .shardStorm, "stage 4 event rotation is stable")
        expect(TutorialRunCoordinator.step(elapsed: 1, dashes: 0, shards: 0, echoes: 0) == .move, "tutorial starts with movement")
        expect(TutorialRunCoordinator.step(elapsed: 25, dashes: 1, shards: 1, echoes: 1) == .complete, "tutorial completes after required actions")

        var controller = AdaptiveQualityController()
        for _ in 0..<120 { _ = controller.observe(frameDelta: 1.0 / 30.0, enabled: true) }
        expect(controller.quality != .high, "adaptive quality reacts to sustained slow frames")
        expect(SceneComplexityPolicy.maximumActiveEchoes(stage: 100, quality: .high) <= 22, "echo budget remains bounded")
        expect(SceneComplexityPolicy.particleCount(requested: 40, quality: .high, reducedMotion: true) < 40, "reduced motion lowers particles")

        print("ECHO LOOP Linux core smoke tests passed.")
    }
}
