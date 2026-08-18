import XCTest

final class EchoLoopLaunchTests: XCTestCase {
    func testLaunchShowsMainMenu() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-reset"]
        app.launch()
        XCTAssertTrue(app.buttons["menu.play"].waitForExistence(timeout: 5))
    }
}
