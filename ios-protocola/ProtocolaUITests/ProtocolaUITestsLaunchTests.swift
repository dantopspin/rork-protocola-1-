//
//  ProtocolaUITestsLaunchTests.swift
//  ProtocolaUITests
//
//  Created by Rork on October 3, 2026.
//

import XCTest

final class ProtocolaUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        // One deterministic launch is enough for CI. Running the generated
        // launch test once per UI configuration caused simulator termination
        // races between configurations without adding product coverage.
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset"
        ]
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
