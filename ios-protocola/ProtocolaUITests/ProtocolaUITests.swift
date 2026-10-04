import XCTest

final class ProtocolaUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }


    @MainActor
    func testOnboardingRequiresIntentAndAcknowledgement() throws {
        let app = freshApp()

        let getStarted = app.buttons["Get started"]
        XCTAssertTrue(
            getStarted.waitForExistence(timeout: 8)
        )
        getStarted.tap()

        XCTAssertTrue(
            app.staticTexts["Make it yours."]
                .waitForExistence(timeout: 3)
        )

        let continueButton =
            app.buttons["Continue"]

        XCTAssertFalse(continueButton.isEnabled)

        // Required steps cannot be bypassed by horizontal paging.
        app.swipeLeft()

        XCTAssertTrue(
            app.staticTexts["Make it yours."].exists
        )
        XCTAssertFalse(continueButton.isEnabled)

        let scheduleChoice =
            app.buttons["onboarding.intent.schedule"]

        XCTAssertTrue(
            scheduleChoice.waitForExistence(timeout: 2)
        )
        scheduleChoice.tap()

        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        XCTAssertTrue(
            app.staticTexts[
                "Never wonder what's next."
            ]
            .waitForExistence(timeout: 3)
        )

        app.buttons["Continue"].tap()

        XCTAssertTrue(
            app.staticTexts["Private by design."]
                .waitForExistence(timeout: 3)
        )

        let setupButton =
            app.buttons["Set up my protocol"]

        XCTAssertFalse(setupButton.isEnabled)

        let acknowledgement =
            app.buttons["onboarding.acknowledgement"]

        XCTAssertTrue(
            acknowledgement.waitForExistence(
                timeout: 2
            )
        )

        acknowledgement.tap()

        XCTAssertTrue(setupButton.isEnabled)
        setupButton.tap()

        XCTAssertTrue(
            app.navigationBars["Set up your protocol"]
                .waitForExistence(timeout: 3)
        )

        XCTAssertTrue(
            app.textFields["protocolName"]
                .exists
        )

        XCTAssertTrue(
            app.textFields["compoundName"]
                .exists
        )
    }


    @MainActor
    func testDemoPathEntersMainApp() throws {
        let app = freshApp()

        let demo =
            app.buttons["Explore sample records"]

        XCTAssertTrue(
            demo.waitForExistence(timeout: 8)
        )

        demo.tap()

        XCTAssertTrue(
            app.navigationBars["Today"]
                .waitForExistence(timeout: 4)
        )

        XCTAssertTrue(
            app.buttons["Exit"]
                .waitForExistence(timeout: 2)
        )
    }


    @MainActor
    private func freshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset"
        ]
        app.launch()
        return app
    }
}
