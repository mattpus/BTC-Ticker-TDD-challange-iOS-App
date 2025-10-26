//
//  TickerFlowUITests.swift
//  BTCTickerIOSAppUITests
//
//  Created by Matt on 26/10/2025.
//

import XCTest

final class TickerFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testInitialStateDisplaysStoppedStatusAndButtonStates() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertEqual(app.staticTexts["titleLabel"].label, "Bitcoin Ticker")
        XCTAssertEqual(app.staticTexts["priceLabel"].label, "--")
        XCTAssertEqual(app.staticTexts["statusLabel"].label, "Service stopped")
        XCTAssertTrue(app.buttons["startButton"].isEnabled)
        XCTAssertFalse(app.buttons["stopButton"].isEnabled)
    }

    func testStartAndStopButtonsToggleStatesThroughFlow() {
        let app = XCUIApplication()
        app.launch()

        let startButton = app.buttons["startButton"]
        let stopButton = app.buttons["stopButton"]
        let statusLabel = app.staticTexts["statusLabel"]

        startButton.tap()

        XCTAssertFalse(startButton.isEnabled)
        XCTAssertTrue(stopButton.isEnabled)

        stopButton.tap()

        XCTAssertTrue(startButton.isEnabled)
        XCTAssertFalse(stopButton.isEnabled)
    }
}
