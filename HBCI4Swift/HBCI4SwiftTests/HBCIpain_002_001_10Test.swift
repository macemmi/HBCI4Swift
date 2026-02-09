//
//  HBCIpain_002_001_10Test.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 12.09.25.
//  Copyright © 2025 Frank Emminghaus. All rights reserved.
//

import XCTest
import HBCI4Swift

class HBCIpain_002_001_10Test : XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    func testParser_1() {
        let path = "~/Pecunia/pain.002.001.10_1.xml" as NSString;

        do {
            let newPath = path.expandingTildeInPath;
            let document = try String(contentsOfFile: newPath);
            let parser = HBCISepaPaymentStatusParser_002_001_10();
            if let data = document.data(using: String.Encoding.utf8) {
                let result = parser.parse(data);
                XCTAssert(result?.items.count == 8);
                
            }
        }
        catch {
            XCTAssertTrue(false, "");
        }

    }
    
    func testParser_2() {
        let path = "~/Pecunia/pain.002.001.10_2.xml" as NSString;

        do {
            let newPath = path.expandingTildeInPath;
            let document = try String(contentsOfFile: newPath);
            let parser = HBCISepaPaymentStatusParser_002_001_10();
            if let data = document.data(using: String.Encoding.utf8) {
                let result = parser.parse(data);
                XCTAssert(result?.items.count == 1);
                
            }
        }
        catch {
            XCTAssertTrue(false, "");
        }

    }
}
