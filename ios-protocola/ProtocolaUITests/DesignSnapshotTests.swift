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
    func testCaptureDarkMode() throws {
        capture(
            prefix: "dark",
            extraArguments: ["-ui-dark"]
        )
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

    /// Opens only the paywall, so it can be captured on several screen sizes.
    @MainActor
    func testCapturePaywallOnly() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset"]
        app.launch()

        let demo = app.buttons["Explore sample records"]
        guard demo.waitForExistence(timeout: 10) else { return }
        demo.tap()
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 6)
        settle()

        let settings = app.navigationBars.buttons["Settings"].firstMatch
        guard settings.waitForExistence(timeout: 3) else { return }
        settings.tap()
        settle()

        if tapIfPresent(app.buttons["Upgrade"]) {
            settle()
            shot(app, "pw-paywall")
        }
    }

    /// Walks the real first run from a fresh install: onboarding, setup,
    /// the reminder explanation, and the first Today.
    @MainActor
    func testCaptureFirstRun() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset"]
        app.launch()

        let start = app.buttons["Get started"]
        guard start.waitForExistence(timeout: 10) else {
            shot(app, "fr-00-missing-start")
            return
        }
        settle()
        shot(app, "fr-01-welcome")
        start.tap()
        // Wait for the page transition to finish, not a fixed delay.
        _ = app.buttons["Continue"].waitForExistence(timeout: 5)
        settle()
        settle()
        shot(app, "fr-02-step2")

        guard tapIfPresent(app.buttons["Continue"]) else { return }
        shot(app, "fr-03-step3")

        guard tapIfPresent(app.buttons["onboarding.acknowledgement"]) else { return }
        shot(app, "fr-03b-step3-accepted")

        guard tapIfPresent(app.buttons["onboarding.setupProtocol"]) else { return }
        settle()
        shot(app, "fr-04-setup")

        let name = app.textFields["protocolName"]
        if name.waitForExistence(timeout: 3) {
            name.tap()
            name.typeText("Morning protocol")
        }
        let compound = app.textFields["compoundName"]
        if compound.exists {
            compound.tap()
            compound.typeText("Sample compound")
        }
        let amount = app.textFields["Amount"]
        if amount.exists {
            amount.tap()
            amount.typeText("0.25")
        }
        shot(app, "fr-05-setup-filled")
        app.swipeUp()
        settle()
        shot(app, "fr-06-setup-schedule")

        let save = app.navigationBars.buttons["Save"]
        guard save.waitForExistence(timeout: 2) else { return }
        save.tap()
        settle()
        shot(app, "fr-07-reminders")

        _ = tapIfPresent(app.buttons["Not now"])
        // Saving closes the setup sheet; wait for the tab bar before Today.
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 8)
        settle()
        settle()
        shot(app, "fr-08-today")
        app.swipeUp()
        settle()
        shot(app, "fr-09-today-scrolled")
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
        if screens == nil {
            shot(app, "\(prefix)-00-onboarding")
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
                    if tapIfPresent(app.buttons["Add vial"]) {
                        shot(app, "\(prefix)-04b-vial-editor")
                        dismissSheets(app)
                    }
                    app.navigationBars.buttons.firstMatch.tap()
                    settle()
                }

                app.swipeDown()
                app.swipeDown()
                let actions = app.navigationBars.buttons["Settings"].firstMatch
                if actions.waitForExistence(timeout: 2) {
                    actions.tap()
                    let settings = app.navigationBars["Settings"].firstMatch
                    if settings.waitForExistence(timeout: 2) {
                        _ = settings
                        settle()
                        shot(app, "\(prefix)-05-settings")
                        let alerts = app.switches
                            .matching(NSPredicate(format: "label CONTAINS[c] 'Inventory alerts'"))
                            .firstMatch
                        if alerts.waitForExistence(timeout: 2) {
                            // Tap the control itself, not the row label.
                            alerts
                                .coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
                                .tap()
                            settle()
                            shot(app, "\(prefix)-05b-permission-sheet")
                            tapIfPresent(app.buttons["Not now"])
                        }
                        if tapIfPresent(app.buttons["Upgrade"]) {
                            shot(app, "\(prefix)-05c-paywall")
                            app.swipeDown(velocity: .fast)
                            settle()
                        }
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
                if tapIfPresent(app.buttons["Add protocol"]) {
                    shot(app, "\(prefix)-07b-protocol-editor")
                    dismissSheets(app)
                }
            }

            if screens == nil {
                let row = app.buttons
                    .matching(NSPredicate(format: "label CONTAINS 'Sample protocol'"))
                    .firstMatch
                if row.waitForExistence(timeout: 2) {
                    row.tap()
                    settle()
                    shot(app, "\(prefix)-08-protocol-detail")
                    app.swipeUp()
                    settle()
                    shot(app, "\(prefix)-09-protocol-detail-scrolled")
                    if tapIfPresent(
                        app.buttons
                            .matching(NSPredicate(format: "label BEGINSWITH 'Labs'"))
                            .firstMatch
                    ) {
                        shot(app, "\(prefix)-09b-labs")
                        app.navigationBars.buttons.firstMatch.tap()
                        settle()
                    }
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

    @MainActor
    @discardableResult
    private func tapIfPresent(_ element: XCUIElement) -> Bool {
        guard element.waitForExistence(timeout: 2), element.isHittable else {
            return false
        }
        element.tap()
        settle()
        return true
    }

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
