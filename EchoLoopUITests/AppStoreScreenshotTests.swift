import XCTest
import Foundation

final class AppStoreScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-reset", "--appstore-screenshots"]
        app.launch()
        XCTAssertTrue(app.buttons["menu.play"].waitForExistence(timeout: 6))
    }

    func testCaptureAppStoreScreens() {
        capture("01-main-menu")

        app.buttons["menu.achievements"].tap()
        XCTAssertTrue(app.buttons["achievements.close"].waitForExistence(timeout: 4))
        capture("05-achievements")
        app.buttons["achievements.close"].tap()

        XCTAssertTrue(app.buttons["menu.season"].waitForExistence(timeout: 4))
        app.buttons["menu.season"].tap()
        XCTAssertTrue(app.buttons["season.close"].waitForExistence(timeout: 4))
        capture("04-season")
        app.buttons["season.close"].tap()

        XCTAssertTrue(app.buttons["menu.play"].waitForExistence(timeout: 4))
        app.buttons["menu.play"].tap()
        XCTAssertTrue(app.buttons["game.pause"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 2)
        capture("02-gameplay")

        let dash = app.buttons["game.dash"]
        if dash.exists { dash.tap() }
        Thread.sleep(forTimeInterval: 1)
        capture("03-dash-gameplay")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
