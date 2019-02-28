//
//  HBCIDataElementGroupDescription.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 22.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation


class HBCIDataElementGroupDescription: HBCISyntaxElementDescription {
    override init(syntax: HBCISyntax, element: XMLElement) throws {
        try super.init(syntax: syntax, element: element)
        self.delimiter = HBCIChar.dpoint.rawValue;
        self.elementType = .dataElementGroup
    }
    
    override func elementDescription() -> String {
        if self.identifier == nil {
            let type = self.type ?? "none"
            let name = self.name ?? "none"
            return "DEG type: \(type), name: \(name) \n"
        } else {
            return "DEG id: \(self.identifier!) \n"
        }
    }
    
    func parseDEG(_ bytes: UnsafePointer<CChar>, length: Int, binaries:Array<Data>, optional:Bool)->HBCISyntaxElement? {
        let deg = HBCIDataElementGroup(description: self);
        var ref:HBCISyntaxElementReference;
        var refIdx = 0;
        var num = 0;
        var count = 0;
        var delimiter = CChar(":");
        
        var p: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>(mutating: bytes);
        var resLength = length;
        
        while(refIdx < self.children.count) {
            ref = self.children[refIdx];
            
            //  check if optional tail is cut
            if delimiter == HBCIChar.plus.rawValue || delimiter == HBCIChar.quote.rawValue {
                if num >= ref.minnum {
                    refIdx += 1;
                    continue; // check next
                } else {
                    // error: non-optional element but end of DEG
                    logInfo("Parse error: non-optional element \(ref.name) is missing at the end of data element group");
                    return nil;
                }
            }
            
            // DE or nested DEG?
            var parsedElem:HBCISyntaxElement?
            if ref.elemDescr.elementType == ElementType.dataElementGroup {
                if let descr = ref.elemDescr as? HBCIDataElementGroupDescription {
                    parsedElem = descr.parseDEG(p, length: resLength, binaries: binaries, optional: ref.minnum == 0 || optional);
                } else {
                    logInfo("Unexpected HBCI syntax error");
                    return nil;
                }
            } else {
                parsedElem = ref.elemDescr.parse(p, length: resLength, binaries: binaries)
            }
            
            if let element = parsedElem {
                if element.isEmpty {
                    // check if element was optional
                    if ref.minnum < num && !optional {
                        // error: minimal occurence
                        logInfo("Parse error: element \(element.name) is empty but not optional");
                        return nil;
                    } else {
                        num = 0;
                        refIdx += 1;
                    }
                } else {
                    // element is not empty
                    if ref.name != nil {
                        element.name = ref.name;
                    } else {
                        logInfo("Parse error: reference without name");
                        return nil;
                    }
                    deg.children.append(element);
                    
                    num += 1;
                    if num == ref.maxnum {
                        // new object
                        num = 0;
                        refIdx += 1;
                    }
                }
                
                p = p.advanced(by: element.length);
                delimiter = p.pointee;
                p = p.advanced(by: 1); // consume delimiter
                count += element.length + 1;
                resLength = length - count;

            } else {
            // parse error for children
            return nil;
            }
        }
        
        deg.length = count-1;
        return deg;
     }
    
    
    override func parse(_ bytes: UnsafePointer<CChar>, length: Int, binaries:Array<Data>)->HBCISyntaxElement? {
        return parseDEG(bytes, length: length, binaries: binaries, optional: false);
        /*
        var deg = HBCIDataElementGroup(description: self);
        var ref:HBCISyntaxElementReference;
        var refIdx = 0;
        var num = 0;
        var count = 0;
        var delimiter:CChar = ":";
        
        var p: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>(bytes);
        var resLength = length;
        
        while(refIdx < self.children.count) {
            ref = self.children[refIdx];
            
            //  check if optional tail is cut
            if delimiter == "+" || delimiter == "'" {
                if num >= ref.minnum {
                    refIdx++;
                    continue; // check next
                } else {
                    // error: non-optional element but end of DEG
                    logInfo("Parse error: non-optional element \(ref.name) is missing at the end of data element group");
                    return nil;
                }
            }
            
            if p.memory == ":" && refIdx > 0 {
                // empty element - check if element was optional
                if ref.minnum < num {
                    // error: minimal occurence
                    logInfo("Parse error: element \(ref.name) is empty but not optional");
                    return nil;
                } else {
                    num = 0;
                    refIdx++;
                    
                    p = p.advancedBy(1); // consume delimiter
                    count += 1;
                    resLength = length - count;
                }
            } else {
                if let element = ref.elemDescr.parse(p, length: resLength, binaries: binaries) {
                    if ref.name != nil {
                        element.name = ref.name;
                    } else {
                        logInfo("Parse error: reference without name");
                        return nil;
                    }
                    deg.children.append(element);
                    
                    if element.isEmpty {
                        // check if element was optional
                        if ref.minnum < num {
                            // error: minimal occurence
                            logInfo("Parse error: element \(element.name) is empty but not optional");
                            return nil;
                        } else {
                            num = 0;
                            refIdx++;
                        }
                    } else {
                        num++;
                        if num == ref.maxnum {
                            // new object
                            num = 0;
                            refIdx++;
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
        
        deg.length = count-1;
        return deg;
        */
    }
    
    override func getElement() -> HBCISyntaxElement? {
        return HBCIDataElementGroup(description: self);
    }
    
    
}
