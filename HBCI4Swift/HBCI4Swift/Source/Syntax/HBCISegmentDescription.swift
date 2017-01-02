//
//  HBCISegmentDescription.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 27.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISegmentDescription: HBCISyntaxElementDescription {
    let code:String;
    let version:Int;
    
    init(syntax:HBCISyntax, element:NSXMLElement, code:String, version:Int) throws {
        self.code = code;
        self.version = version;
        try super.init(syntax: syntax, element: element);
        self.delimiter = HBCIChar.plus.rawValue;
        self.elementType = ElementType.Segment;
    }
    
    override func elementDescription() -> String {
        if self.identifier == nil {
            let type = self.type ?? "none"
            let name = self.name ?? "none"
            return "SEG type: \(type), name: \(name) \n"
        } else {
            return "SEG id: \(self.identifier!) \n"
        }
    }

    override func parse(bytes: UnsafePointer<CChar>, length: Int, binaries:Array<NSData>)->HBCISyntaxElement? {
        let seg = HBCISegment(description: self);
        var ref:HBCISyntaxElementReference;
        var refIdx = 0;
        var num = 0;
        var count = 0;
        var delimiter = HBCIChar.plus.rawValue;
        
        var p: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>(bytes);
        var resLength = length;
        
        while(refIdx < self.children.count) {
            ref = self.children[refIdx];
            
            //  check if optional tail is cut
            if delimiter == HBCIChar.quote.rawValue {
                if num >= ref.minnum {
                    refIdx += 1;
                    continue; // check next
                } else {
                    // error: non-optional element but end of SEG
                    logError("Parse error: non-optional element is missing at the end of data element group");
                    return nil;
                }
            }
            
            if p.memory == HBCIChar.plus.rawValue && refIdx > 0 {
                // empty element - check if element was optional
                if ref.minnum < num {
                    // error: minimal occurence
                    logError("Parse error: element \(ref.name) is empty but not optional");
                    return nil;
                } else {
                    num = 0;
                    refIdx += 1;
                    
                    p = p.advancedBy(1); // consume delimiter
                    count += 1;
                    resLength = length - count;
                }
            } else {
                if let element = ref.elemDescr.parse(p, length: resLength, binaries: binaries) {
                    if ref.name != nil {
                        element.name = ref.name;
                    } else {
                        logError("Parse error: reference without name");
                        return nil;
                    }
                    seg.children.append(element);
                    
                    if element.isEmpty {
                        // check if element was optional
                        if ref.minnum < num {
                            // error: minimal occurence
                            logError("Parse error: element \(ref.name) is empty but not optional");
                            return nil;
                        } else {
                            num = 0;
                            refIdx += 1;
                        }
                    } else {
                        num += 1;
                        if num == ref.maxnum {
                            // new object
                            num = 0;
                            refIdx += 1;
                        }
                    }
                    
                    p = p.advancedBy(element.length);
                    delimiter = p.memory;
                    p = p.advancedBy(1); // consume delimiter
                    count += element.length + 1;
                    resLength = length - count;
                } else {
                    // parse error for children
                    return nil;
                }
            }
        }
        
        seg.length = count-1;
        if seg.name == "" {
            seg.name = seg.descr.type ?? "";
        }
        return seg;
    }
    
    func parse(segData:NSData, binaries:Array<NSData>) ->HBCISegment? {
        return parse(UnsafePointer<CChar>(segData.bytes), length: segData.length, binaries: binaries) as? HBCISegment;
    }
    
    override func getElement() -> HBCISyntaxElement? {
        return HBCISegment(description: self);
    }


}


