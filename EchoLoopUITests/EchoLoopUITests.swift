import XCTest

final class EchoLoopUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-reset"]
        app.launch()
    }

    func testMainMenuCanOpenAchievementsAndReturn() {
        let achievements = app.buttons["menu.achievements"]
        XCTAssertTrue(achievements.waitForExistence(timeout: 5))
        achievements.tap()
        let close = app.buttons["achievements.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        close.tap()
        XCTAssertTrue(app.buttons["menu.play"].waitForExistence(timeout: 3))
    }

    func testSeasonScreenOpensAndReturnsToMenu() {
        let season = app.buttons["menu.season"]
        XCTAssertTrue(season.waitForExistence(timeout: 5))
        season.tap()
        let close = app.buttons["season.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        close.tap()
        XCTAssertTrue(app.buttons["menu.play"].waitForExistence(timeout: 3))
    }

    func testPlayStartsGameAndPauseControlExists() {
        let play = app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        play.tap()
        XCTAssertTrue(app.buttons["game.pause"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["game.dash"].exists)
    }
}
