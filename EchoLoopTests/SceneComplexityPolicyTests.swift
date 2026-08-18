import XCTest
@testable import EchoLoop

final class SceneComplexityPolicyTests: XCTestCase {
    func testEchoBudgetIsBounded() {
        XCTAssertLessThanOrEqual(SceneComplexityPolicy.maximumActiveEchoes(stage: 100, quality: .high), 22)
        XCTAssertLessThan(SceneComplexityPolicy.maximumActiveEchoes(stage: 1, quality: .low), SceneComplexityPolicy.maximumActiveEchoes(stage: 1, quality: .high))
    }

    func testReducedMotionReducesParticles() {
        let normal = SceneComplexityPolicy.particleCount(requested: 40, quality: .high, reducedMotion: false)
        let reduced = SceneComplexityPolicy.particleCount(requested: 40, quality: .high, reducedMotion: true)
        XCTAssertLessThan(reduced, normal)
    }
}
