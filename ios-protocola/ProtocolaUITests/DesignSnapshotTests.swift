import XCTest

/// Captures the main screens with demo data as named attachments so design
/// changes can be reviewed visually. Navigation steps are best-effort: a
/// missing element skips that shot instead of failing the suite.
final class DesignSnapshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    func testCaptureDefaultTextSize() throws {
        capture(prefix: "default", extraArguments: [])
    }

    @MainActor
    func testCaptureAccessibilityTextSize() throws {
        capture(
            prefix: "ax-xl",
            extraArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXL"
            ],
            screens: ["Today", "Protocols"]
        )
    }

    // MARK: - Flow

    @MainActor
    private func capture(
        prefix: String,
        extraArguments: [String],
        screens: Set<String>? = nil
    ) {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset"] + extraArguments
        app.launch()

        let demo = app.buttons["Explore sample records"]
        guard demo.waitForExistence(timeout: 10) else {
            shot(app, "\(prefix)-00-onboarding")
            return
        }
        demo.tap()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 6) else { return }

        func wants(_ name: String) -> Bool {
            screens?.contains(name) ?? true
        }

        if wants("Today") {
            settle()
            shot(app, "\(prefix)-01-today")
            app.swipeUp()
            settle()
            shot(app, "\(prefix)-02-today-scrolled")
            app.swipeUp()
            settle()
            shot(app, "\(prefix)-03-today-bottom")

            if screens == nil {
                let inventory = app.buttons
                    .containing(NSPredicate(format: "label CONTAINS[c] 'inventory'"))
                    .firstMatch
                if inventory.waitForExistence(timeout: 2) {
                    inventory.tap()
                    settle()
                    shot(app, "\(prefix)-04-inventory")
                    app.navigationBars.buttons.firstMatch.tap()
                    settle()
                }

                app.swipeDown()
                app.swipeDown()
                let actions = app.buttons["Today actions"]
                if actions.waitForExistence(timeout: 2) {
                    actions.tap()
                    let settings = app.buttons["Settings"]
                    if settings.waitForExistence(timeout: 2) {
                        settings.tap()
                        settle()
                        shot(app, "\(prefix)-05-settings")
                        dismissSheets(app)
                    }
                }

                let log = app.buttons["Log"].firstMatch
                if log.waitForExistence(timeout: 2) {
                    log.tap()
                    settle()
                    shot(app, "\(prefix)-06-dose-editor")
                    dismissSheets(app)
                }
            }
        }

        if wants("Protocols"), openTab(app, "Protocols") {
            settle()
            shot(app, "\(prefix)-07-protocols")

            if screens == nil {
                let row = app.buttons
                    .matching(NSPredicate(format: "label CONTAINS 'Active'"))
                    .firstMatch
                if row.waitForExistence(timeout: 2) {
                    row.tap()
                    settle()
                    shot(app, "\(prefix)-08-protocol-detail")
                    app.swipeUp()
                    settle()
                    shot(app, "\(prefix)-09-protocol-detail-scrolled")
                    app.navigationBars.buttons.firstMatch.tap()
                    settle()
                }
            }
        }

        if wants("History"), openTab(app, "History") {
            settle()
            shot(app, "\(prefix)-10-history")
        }

        if wants("Insights"), openTab(app, "Insights") {
            settle()
            shot(app, "\(prefix)-11-insights")
            app.swipeUp()
            settle()
            shot(app, "\(prefix)-12-insights-scrolled")
            app.swipeUp()
            settle()
            shot(app, "\(prefix)-13-insights-bottom")
        }
    }

    // MARK: - Helpers

    /// Closes any open sheet so the tab bar is reachable again.
    @MainActor
    private func dismissSheets(_ app: XCUIApplication) {
        for _ in 0..<3 {
            if app.tabBars.firstMatch.isHittable { return }
            for title in ["Cancel", "Done", "Close"] {
                let button = app.navigationBars.buttons[title]
                if button.exists, button.isHittable {
                    button.tap()
                    settle()
                    break
                }
            }
            if app.tabBars.firstMatch.isHittable { return }
            app.swipeDown(velocity: .fast)
            settle()
        }
    }

    @MainActor
    private func openTab(_ app: XCUIApplication, _ title: String) -> Bool {
        dismissSheets(app)
        let tab = app.tabBars.firstMatch.buttons[title]
        guard tab.waitForExistence(timeout: 3), tab.isHittable else {
            shot(app, "zz-missing-tab-\(title)")
            return false
        }
        tab.tap()
        return true
    }

    private func settle() {
        Thread.sleep(forTimeInterval: 0.8)
    }

    @MainActor
    private func shot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
