//
//  HBCIDataElementGroupDescription.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 22.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation


class HBCIDataElementGroupDescription: HBCISyntaxElementDescription {
    override init(syntax: HBCISyntax, element: NSXMLElement) throws {
        try super.init(syntax: syntax, element: element)
        self.delimiter = HBCIChar.dpoint.rawValue;
        self.elementType = .DataElementGroup
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
    
    func parseDEG(bytes: UnsafePointer<CChar>, length: Int, binaries:Array<NSData>, optional:Bool)->HBCISyntaxElement? {
        let deg = HBCIDataElementGroup(description: self);
        var ref:HBCISyntaxElementReference;
        var refIdx = 0;
        var num = 0;
        var count = 0;
        var delimiter = CChar(":");
        
        var p: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>(bytes);
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
                    logError("Parse error: non-optional element \(ref.name) is missing at the end of data element group");
                    return nil;
                }
            }
            
            // DE or nested DEG?
            var parsedElem:HBCISyntaxElement?
            if ref.elemDescr.elementType == ElementType.DataElementGroup {
                if let descr = ref.elemDescr as? HBCIDataElementGroupDescription {
                    parsedElem = descr.parseDEG(p, length: resLength, binaries: binaries, optional: ref.minnum == 0 || optional);
                } else {
                    logError("Unexpected HBCI syntax error");
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
                        logError("Parse error: element \(element.name) is empty but not optional");
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
                        logError("Parse error: reference without name");
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
        
        deg.length = count-1;
        return deg;
     }
    
    
    override func parse(bytes: UnsafePointer<CChar>, length: Int, binaries:Array<NSData>)->HBCISyntaxElement? {
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
                    logError("Parse error: non-optional element \(ref.name) is missing at the end of data element group");
                    return nil;
                }
            }
            
            if p.memory == ":" && refIdx > 0 {
                // empty element - check if element was optional
                if ref.minnum < num {
                    // error: minimal occurence
                    logError("Parse error: element \(ref.name) is empty but not optional");
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
                        logError("Parse error: reference without name");
                        return nil;
                    }
                    deg.children.append(element);
                    
                    if element.isEmpty {
                        // check if element was optional
                        if ref.minnum < num {
                            // error: minimal occurence
                            logError("Parse error: element \(element.name) is empty but not optional");
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