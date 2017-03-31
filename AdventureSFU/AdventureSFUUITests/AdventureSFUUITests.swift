//
//  AdventureSFUTests.swift
//  AdventureSFUTests
//
//	Created for SFU CMPT 276, Instructor Herbert H. Tsang, P.Eng., Ph.D.
//	AdventureSFU was a project created by Group 12 of CMPT 276
//
//  AdventureSFUTests.swift - contains the unit test for the application
//  Programmers: Karan Aujla, Carlos Abaffy, Eleanor Lewis, Chris Norris-Jones
//
//  Created by Group12 on 3/19/17.
//  Copyright © 2017. All rights reserved.
//Test Case Note:	Currently our test cases, as provided in the Revised Quality Assurance Document, were not performed via XCode's UI Test Software tools, but rather via running through
//					unit tests created specifically by the programmer at the time of development. The use of XCode's testing software is something our team is in the process of
//					learning, but we were not yet at a stage with the tools to satisfactorily provide full test code coverage in a way that running through our own UI tests
//					individually could not better handle. We look into having simplified UI test cases available via XCode's testing tools for the final version of our software
//

import XCTest

class AdventureSFUUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUp() {
        super.setUp()
		
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testLogin(){
        let app = XCUIApplication()
        
        let addressComTextField = XCUIApplication().textFields["@address.com"]
        addressComTextField.tap()
        addressComTextField.typeText("k@t.ca")
        

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("T123456")
        app.buttons["Sign In"].tap()
        
        let loginFail = app.alerts["Fields Missing!"]
        //then 
        XCTAssertFalse(loginFail.exists)
        
        
        
    }
}
