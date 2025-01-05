//
//  InspectARUITests.swift
//  InspectARUITests
//
//  Created by hybrayhem.
//

import XCTest

final class InspectARUITests: XCTestCase {

    func testNavigateToARScreen() {
        let app = XCUIApplication()
        app.launchArguments += [
            "--ui-testing",
            "animations", "0",
            "slowAnimations", "0",
            "TestIdentifier=InspectARUITest"
        ]
        app.launch()
        
        let cell = app.staticTexts["chassis.step"]
        XCTAssertTrue(cell.exists)
        cell.tap()
        
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.exists)
        nextButton.tap()
        
        app.tap()
        
        XCTContext.runActivity(named: "Keep open") { _ in
            while true {
                RunLoop.current.run(mode: .default, before: .distantFuture)
            }
        }
    }
    
}
