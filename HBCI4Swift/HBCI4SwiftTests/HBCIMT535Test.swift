//
//  HBCIMT535Test.swift
//  HBCI4SwiftTests
//
//  Created by Frank Emminghaus on 14.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//

import XCTest

class HBCIMT535Test: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMT535() {
        let path = "~/depot.txt" as NSString;

        do {
            let newPath = path.expandingTildeInPath;
            let balance = try String(contentsOfFile: newPath);
            let parser = HBCIMT535Parser(balance);
            parser.parse();
        }
        catch {
            XCTAssertTrue(false, "");
        }

    }


    
    
}
