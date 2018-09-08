//
//  HBCISyntaxTest.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 12.03.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import XCTest
import HBCI4Swift

class HBCISyntaxTest: XCTestCase {
    var syntax:HBCISyntax?

    override func setUp() {
        if self.syntax == nil {
            do {
                let path = Bundle(for: self.classForCoder).resourcePath;
                try self.syntax = HBCISyntax(path: path! + "/hbci300.xml");
            }
            catch {
                XCTFail("Syntax cannot be read");
                return;
            }
            XCTAssertNotNil(syntax, "Syntax cannot be read");
        }
        super.setUp()
        
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func getPointer(_ s:String) ->(UnsafePointer<CChar>, Int)? {
        if let data = s.data(using: String.Encoding.isoLatin1, allowLossyConversion: true) as NSData? {
            return (data.bytes.bindMemory(to: CChar.self, capacity: data.length), data.length);
            //return (UnsafePointer<CChar>(data.bytes), data.length);
        }
        return nil;
    }
    
    func parseDEG(_ degName:String, toParse:String) ->HBCIDataElementGroup? {
        if syntax == nil {
            XCTFail("No syntax");
            return nil;
        }
        let binaries = Array<NSData>();
        if let deg = syntax!.degs[degName] {
            if let (p, n) = getPointer(toParse) {
                let de = deg.parse(p, length: n, binaries: binaries as Array<Data>);
                XCTAssertNotNil(de, degName + " parsing failed");
                return de as? HBCIDataElementGroup;
            }
        }
        XCTAssertTrue(false, "");
        return nil;
    }
    
    func parseSEG(_ segName:String, version:Int, toParse:String) ->HBCISegment? {
        if syntax == nil {
            XCTFail("No syntax");
            return nil;
        }
        let binaries = Array<NSData>();
        if let segv = syntax!.segs[segName] {
            if let seg = segv.segmentWithVersion(version) {
                if let (p, n) = getPointer(toParse) {
                    let segment = seg.parse(p, length: n, binaries: binaries as Array<Data>);
                    XCTAssertNotNil(segment, segName + " parsing failed");
                    return segment as? HBCISegment;
                }
            }
        }
        XCTAssertTrue(false, "");
        return nil;
    }

    func testBTG1() {
        let binaries = Array<NSData>();
        let s = "152,99+";

        if syntax == nil {
            XCTFail("No syntax");
            return;
        }
        if let degBTR = syntax!.degs["BTG"] {
            let des = degBTR.children[0].elemDescr as! HBCIDataElementDescription;
            if let (p, n) = getPointer(s) {
                if let de = des.parse(p, length: n, binaries: binaries as Array<Data>) as? HBCIDataElement {
                    if let d:NSDecimalNumber = de.value as? NSDecimalNumber {
                        XCTAssertNotNil(d, "Amount conversion failed");
                        return;
                    }
                }
            }
        }
        XCTAssertTrue(false, "Amount test failed");
    }

    func testBTG2() {
        let binaries = Array<NSData>();
        let s = "0,+";

        if syntax == nil {
            XCTFail("No syntax");
            return;
        }
        if let degBTR = syntax!.degs["BTG"] {
            let des = degBTR.children[0].elemDescr as! HBCIDataElementDescription;
            if let (p, n) = getPointer(s) {
                if let de = des.parse(p, length: n, binaries: binaries as Array<Data>) as? HBCIDataElement {
                    if let d:NSDecimalNumber = de.value as? NSDecimalNumber {
                        XCTAssertEqual(d, NSDecimalNumber.zero, "Amount not zero");
                        return;
                    }
                }
            }
        }
        XCTAssertTrue(false, "Amount test failed");
    }
    
    func testSecProfile() {
        let toParse = "PIN:1:2:3+";
        parseDEG("SecProfile", toParse: toParse);
    }
    
    func testSegHead() {
        let toParse = "HNHBK:1:3+000000001881+220+1111139025+1+1111139025:1'";
        parseDEG("SegHead", toParse: toParse);
    }
    
    func testParPinTan() {
        let toParse = "5:6:6:BENUTZER:KUNDEN:HKUEB:J:HKSUB:J:HKKAZ:N:HKSLA:J:HKTUE:J:HKTUA:J:HKTUB:N:HKTUL:J:HKAOM:J:HKTAN:N'";
        parseDEG("PinTanInfo", toParse: toParse);
    }
    
    func testSepaInfo() {
        let toParse = "N:N:J:sepade?:xsd?:pain.001.001.02.xsd:urn?:swift?:xsd?:$pain.008.002.01.xsd:urn?:iso?:std?:iso?:20022?:tech?:xsd?:pain.001.002.03.xsd:urn?:iso?:std?:iso?:20022?:tech?:xsd?:pain.001.003.03.xsd:urn?:iso?:std?:iso?:20022?:tech?:xsd?:pain.008.002.02.xsd:urn?:iso?:std?:iso?:20022?:tech?:xsd?:pain.008.003.02.xsd:urn?:swift?:xsd?:$pain.001.002.02.xsd'";
        parseDEG("ParSepaInfo", toParse: toParse);
    }
    
    func testMsgHead() {
        let toParse = "HNHBK:1:3+000000006876+300+111106756+1+111106756:1'";
        parseSEG("MsgHead", version: 3, toParse: toParse);
    }
    
    func testKInfo() {
        let toParse = "HIUPD:116:6:4+XXXXXXXXXX::280:20050550++XXXXXXXXXX+0+EUR+Muster, Alexander++Giro++HKSAK:1::::+HKISA:1::::+HKSSP:1::::+HKDAB:1::::+HKTUB:1::::+HKUEB:1::::+HKSUB:1::::+HKKAZ:1::::+HKSAL:1::::+HKKDM:1::::+HKPAE:1::::+HKTLA:1::::+HKTLF:1::::+HKTSP:1::::+HKTAZ:1::::+HKLSW:1::::+HKTAN:1::::+HKSPA:1::::+HKCCS:1::::+HKCCM:1::::+HKCSE:1::::+HKCSB:1::::+HKCSA:1::::+HKCSL:1::::+HKCDE:1::::+HKCDB:1::::+HKCDN:1::::+HKCDL:1::::+HKDSB:1::::+HKDSW:1::::+HKEKA:1::::+HKQTG:1::::+HKFRD:1::::+HKLWB:1::::+HKTAB:1::::+HKTAU:1::::+HKTSY:1::::+HKMTR:1::::+HKMTF:1::::+HKMTA:1::::+HKTML:1'";
        parseSEG("KInfo", version: 6, toParse: toParse);
    }
    
    func testHitab() {
        let toParse = "HITAB:5:3:3+1+G:1:1111113199000300111::::::::::VR-NetworldCard+M:1:::::::::::mobileTAN:***::::::::20150325'";
        if let segment = parseSEG("TANMediaListRes", version: 3, toParse: toParse) {
            print(segment.description);
        }
        
    }
    
    func testComposeMsgHead() {
        if syntax == nil {
            XCTFail("No syntax");
            return;
        }
        if let segv = syntax!.segs["MsgHead"] {
            if let seg = segv.segmentWithVersion(3) {
                if let _ = seg.compose() {
                    return;
                }
            }
        }
        XCTAssertTrue(false, "");
    }
    
    func testComposeDialogAnon() {
        if syntax == nil {
            XCTFail("No syntax");
            return;
        }
        if let msg = syntax!.msgs["DialogInitAnon"] {
            if let _ = msg.compose() {
                return;
            }
        }
        XCTAssertTrue(false, "");
    }
    
    
    

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }

}
