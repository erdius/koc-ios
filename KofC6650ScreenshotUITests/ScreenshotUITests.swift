import XCTest

final class ScreenshotUITests: XCTestCase {
    func testCaptureScreens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ScreenshotMode", "-kofc_appearance_mode", "Dark"]
        app.launch()

        let gotItButton = app.buttons["Got It"]
        if gotItButton.waitForExistence(timeout: 5) {
            gotItButton.tap()
        }

        let pinField = app.secureTextFields["Council PIN"]
        if pinField.waitForExistence(timeout: 5) {
            pinField.tap()
            pinField.typeText("1882")
        }

        _ = app.tabBars.firstMatch.waitForExistence(timeout: 15)
        sleep(3)
        app.buttons["Agenda"].firstMatch.tap()
        sleep(1)
        save(app.screenshot(), name: "01_signups")

        app.tabBars.buttons["Calendar"].tap()
        sleep(2)
        app.buttons["Month"].firstMatch.tap()
        sleep(2)
        save(app.screenshot(), name: "02_calendar_month")

        app.tabBars.buttons["Submit Photos"].tap()
        sleep(1)
        save(app.screenshot(), name: "03_submitphotos")

        app.tabBars.buttons["Recent Photos"].tap()
        sleep(2)
        save(app.screenshot(), name: "04_recentphotos")
    }

    private func save(_ screenshot: XCUIScreenshot, name: String) {
        let dir = "/private/tmp/claude-501/-Users-david/4c8d4f68-0fba-4ccf-8d98-48e69f7de333/scratchpad/screenshots"
        let path = dir + "/" + name + ".png"
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: path))
    }
}
