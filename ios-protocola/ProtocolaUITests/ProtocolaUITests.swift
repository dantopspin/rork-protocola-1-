import XCTest

final class ProtocolaUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }


    @MainActor
    func testOnboardingRequiresAcknowledgementBeforeProtocolSetup() throws {
        let app = freshApp()

        let getStarted =
            app.buttons["Get started"]

        XCTAssertTrue(
            getStarted.waitForExistence(
                timeout: 8
            )
        )

        getStarted.tap()

        XCTAssertTrue(
            app.staticTexts[
                "One record. Every change preserved."
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        let continueButton =
            app.buttons["Continue"]

        XCTAssertTrue(
            continueButton.waitForExistence(
                timeout: 2
            )
        )

        continueButton.tap()

        XCTAssertTrue(
            app.staticTexts[
                "Private by design."
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        let setupButton =
            app.buttons[
                "onboarding.setupProtocol"
            ]

        XCTAssertTrue(
            setupButton.waitForExistence(
                timeout: 2
            )
        )

        XCTAssertFalse(
            setupButton.isEnabled
        )

        let acknowledgement =
            app.buttons[
                "onboarding.acknowledgement"
            ]

        XCTAssertTrue(
            acknowledgement
                .waitForExistence(
                    timeout: 2
                )
        )

        acknowledgement.tap()

        XCTAssertTrue(
            setupButton.isEnabled
        )

        setupButton.tap()

        XCTAssertTrue(
            app.navigationBars[
                "Set up your protocol"
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        XCTAssertTrue(
            app.textFields[
                "protocolName"
            ]
            .exists
        )

        XCTAssertTrue(
            app.textFields[
                "compoundName"
            ]
            .exists
        )
    }


    @MainActor
    func testDemoPathEntersMainApp() throws {
        let app = freshApp()

        let demo =
            app.buttons[
                "Explore sample records"
            ]

        XCTAssertTrue(
            demo.waitForExistence(
                timeout: 8
            )
        )

        demo.tap()

        XCTAssertTrue(
            app.staticTexts["Today"]
                .waitForExistence(
                    timeout: 4
                )
        )

        XCTAssertTrue(
            app.buttons["Exit"]
                .waitForExistence(
                    timeout: 2
                )
        )
    }


    @MainActor
    func testDemoMainTabsRemainReachable() throws {
        let app = freshApp()

        let demo =
            app.buttons[
                "Explore sample records"
            ]

        XCTAssertTrue(
            demo.waitForExistence(
                timeout: 8
            )
        )

        demo.tap()

        let tabBar =
            app.tabBars.firstMatch

        XCTAssertTrue(
            tabBar.waitForExistence(
                timeout: 4
            )
        )

        for title in [
            "Protocols",
            "History",
            "Insights",
            "Today"
        ] {
            let tab =
                tabBar.buttons[title]

            XCTAssertTrue(
                tab.waitForExistence(
                    timeout: 2
                )
            )

            tab.tap()

            XCTAssertTrue(
                app.staticTexts[title]
                    .waitForExistence(
                        timeout: 3
                    )
            )
        }
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
