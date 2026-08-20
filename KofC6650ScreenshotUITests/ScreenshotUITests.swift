import XCTest

final class ScreenshotUITests: XCTestCase {
    func testCaptureScreens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ScreenshotMode"]
        app.launch()

        let gotItButton = app.buttons["Got It"]
        if gotItButton.waitForExistence(timeout: 5) {
            gotItButton.tap()
        }

        let pinField = app.secureTextFields["Council PIN"]
        if pinField.waitForExistence(timeout: 5) {
            pinField.tap()
            pinField.typeText("1882")
            app.buttons["Unlock"].tap()
        }

        _ = app.tabBars.firstMatch.waitForExistence(timeout: 15)
        sleep(3)
        app.buttons["Agenda"].firstMatch.tap()
        sleep(1)
        save(app.screenshot(), name: "01_signups")

        app.buttons["Month"].firstMatch.tap()
        sleep(1)
        save(app.screenshot(), name: "01b_signups_month")

        app.swipeUp()
        app.swipeUp()
        app.swipeUp()
        sleep(1)
        save(app.screenshot(), name: "01c_signups_month_scrolled_to_bottom")

        app.tabBars.buttons["Calendar"].tap()
        sleep(2)
        save(app.screenshot(), name: "02_calendar")

        app.buttons["Month"].firstMatch.tap()
        sleep(1)
        save(app.screenshot(), name: "02b_calendar_month")

        app.tabBars.buttons["Submit Photos"].tap()
        sleep(1)
        save(app.screenshot(), name: "03_submitphotos")

        app.tabBars.buttons["Recent Photos"].tap()
        sleep(3)
        save(app.screenshot(), name: "04_recentphotos")
    }

    private func save(_ screenshot: XCUIScreenshot, name: String) {
        let dir = "/private/tmp/claude-501/-Users-david/4c8d4f68-0fba-4ccf-8d98-48e69f7de333/scratchpad/screenshots"
        let path = dir + "/" + name + ".png"
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: path))
    }
}
