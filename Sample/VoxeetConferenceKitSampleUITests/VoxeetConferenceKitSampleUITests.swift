//
//  VoxeetConferenceKitSampleUITests.swift
//  VoxeetConferenceKitSampleUITests
//
//  Created by Coco on 16/05/2017.
//  Copyright © 2017 Corentin Larroque. All rights reserved.
//

import XCTest

class VoxeetConferenceKitSampleUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testConferenceFlow() {
        let app = XCUIApplication()
        
        // Create and join the conference.
        let conferenceNameTextField = app.textFields["Conference name"]
        conferenceNameTextField.tap()
        conferenceNameTextField.typeText("_\(Int(arc4random_uniform(1000)))")
        app.buttons["Join conference"].tap()
        
        // Stay around x seconds in the conference.
        sleep(5)
        
        // Hang up.
        app.buttons["Hangup"].tap()
        
        // The conference needs to hang up properly before killing the application.
        sleep(1)
    }
}
