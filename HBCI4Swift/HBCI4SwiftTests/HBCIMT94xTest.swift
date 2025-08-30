//
//  HBCIMT94xTest.swift
//  HBCI4SwiftTests
//
//  Created by Frank Emminghaus on 16.09.18.
//  Copyright © 2018 Frank Emminghaus. All rights reserved.
//

import XCTest

class HBCIMT94xTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMT94x() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let path = "~/ums.txt" as NSString;

        do {
            let newPath = path.expandingTildeInPath;
            let ums = try String(contentsOfFile: newPath);
            let parser = HBCIMT94xParser(mt94xString: ums as NSString);
            var statements = try parser.parse();
            statements.removeAll();
            
            let iban = parser.extractIBAN("DE19500400240004020470/DE19500400240004020470")
            XCTAssert(iban == "DE19500400240004020470", "");
        }
        catch {
            XCTAssertTrue(false, "");
        }
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
