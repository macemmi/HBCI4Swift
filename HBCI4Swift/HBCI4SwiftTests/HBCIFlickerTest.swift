//
//  HBCIFlickerTest.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 30.01.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import XCTest
@testable import HBCI4Swift

class HBCIFlickerTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test1() {
        do {
            let code = try HBCIFlickerCode(code: "039870110490631098765432100812345678041,00");
            let result = try code.render();
            XCTAssertEqual(result, "1784011049063F059876543210041234567844312C303019");
        }
        catch {
            XCTFail("Flicker code parse error");
        }
    }

    func test2() {
        do {
            let code = try HBCIFlickerCode(code: "039870110418751012345678900812030000040,20");
            let result = try code.render();
            XCTAssertEqual(result, "1784011041875F051234567890041203000044302C323015");
        }
        catch {
            XCTFail("Flicker code parse error");
        }
    }
    
    func test3() {
        do {
            let code = try HBCIFlickerCode(code: "0248A0120452019980812345678");
            let result = try code.render();
            XCTAssertEqual(result, "0D85012045201998041234567855");
        }
        catch {
            XCTFail("Flicker code parse error");
        }
    }
    
    func test4() {
        do {
            let code = try HBCIFlickerCode(code: "...TAN-Nummer: CHLGUC 002624088715131306389726041,00CHLGTEXT0244 Sie h...");
            let result = try code.render();
            XCTAssertEqual(result, "0F04871513130338972614312C30303B");
        }
        catch {
            XCTFail("Flicker code parse error");
        }
    }
    
    func test5() {
        do {
            let code = try HBCIFlickerCode(code: "0248A01204520199808123F5678");
            let result = try code.render();
            XCTAssertEqual(result, "118501204520199848313233463536373875");
        }
        catch {
            XCTFail("Flicker code parse error");
        }
    }
    
    func test6() {
        do {
            let code = HBCIFlickerCode();
            code.version = .hhd14;
            code.startCode.data = "1120492";
            code.startCode.length = 7;
            code.startCode.controlBytes.append(1);
            code.de1.data = "30084403";
            code.de1.length = 8;
            code.de2.data = "450,00";
            code.de2.length = 6;
            code.de3.data = "2";
            code.de3.length = 1;
            
            let result = try code.render();
            XCTAssertEqual(result, "1584011120492F0430084403463435302C3030012F05");
        }
        catch {
            XCTFail("Flicker code parse error");
        }
    }
    
    func test7() {
        do {
            let code = try HBCIFlickerCode(code: "190277071234567041,00");
            
            let expected = HBCIFlickerCode();
            expected.lc = 19;
            expected.startCode.lde      = 2;
            expected.startCode.length   = 2;
            expected.startCode.data     = "77";
            expected.de1.lde      = 7;
            expected.de1.length   = 7;
            expected.de1.data     = "1234567";
            expected.de2.lde      = 4;
            expected.de2.length   = 4;
            expected.de2.data     = "1,00";
            
            XCTAssertTrue(code == expected);
        }

        catch {
            XCTFail("Flicker code parse error");
        }
    }
    
    func test8() {
        do {
            let code = try HBCIFlickerCode(code: "250891715637071234567041,00");
            XCTAssertTrue(code.version == HHDVersion.hhd13);
            
        }
        catch {
            
        }
    }
    

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
