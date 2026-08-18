import XCTest
@testable import EchoLoop

final class AdaptiveQualityControllerTests: XCTestCase {
    func testSlowFramesReduceQuality() {
        var controller = AdaptiveQualityController()
        for _ in 0..<120 { _ = controller.observe(frameDelta: 1.0 / 30.0, enabled: true) }
        XCTAssertLessThan(controller.quality.rawValue, RenderingQuality.high.rawValue)
    }

    func testDisabledAdaptiveQualityStaysHigh() {
        var controller = AdaptiveQualityController()
        for _ in 0..<120 { _ = controller.observe(frameDelta: 1.0 / 30.0, enabled: false) }
        XCTAssertEqual(controller.quality, .high)
    }

    func testInvalidLargeDeltaDoesNotDropQuality() {
        var controller = AdaptiveQualityController()
        for _ in 0..<100 { _ = controller.observe(frameDelta: 1.0, enabled: true) }
        XCTAssertEqual(controller.quality, .high)
    }
}
