//
//  HBCIExtensions.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 11.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

extension NSData {
    func hasNonPrintableChars() ->Bool {
        var p = UnsafeMutablePointer<CChar>(self.bytes);
        for idx in 0..<self.length {
            let c = UInt8(p.memory);
            if !((c >= 0x20 && c <= 0x7E) || c >= 0xA1 || c == 0x0A || c == 0x0D) {
                return true;
            }
            p = p.advancedBy(1);
        }
        
        return false;
    }
}

extension NSXMLElement {
    func elementsForPath(path:String) ->[NSXMLElement] {
        var result = Array<NSXMLElement>();
        
        let (name, newPath) = firstComponent(path);
        
        if let nodes = self.children as? [NSXMLNode] {
            for node in nodes {
                if node.kind == NSXMLNodeKind.NSXMLElementKind {
                    if let child = node as? NSXMLElement {
                        if child.name == name {
                            if newPath == nil {
                                result.append(child);
                            } else {
                                return child.elementsForPath(newPath!);
                            }
                        }
                    }
                }
            }
        }
        return result;
    }
    
    func stringValueForPath(path:String) ->String? {
        let elems = elementsForPath(path);
        return elems.first?.stringValue;
    }
    
    func createPath(path:String) ->NSXMLElement {
        let (name, newPath) = firstComponent(path);
        
        if let nodes = self.children as? [NSXMLNode] {
            for node in nodes {
                if node.kind == NSXMLNodeKind.NSXMLElementKind {
                    if let child = node as? NSXMLElement {
                        if child.name == name {
                            if newPath == nil {
                                return child;
                            } else {
                                return child.createPath(newPath!);
                            }
                        }
                    }
                }
            }
        }
        let child = NSXMLElement(name: name);
        self.addChild(child);
        if newPath == nil {
            return child;
        } else {
            return child.createPath(newPath!);
        }
    }
    
    func setStringValueForPath(value:String, path:String) {
        let elem = createPath(path);
        elem.stringValue = value;
    }
}


extension String {
    func substringToIndex(index:Int) ->String {
        return self.substringToIndex(advance(startIndex, index));
    }
    
    func substringFromIndex(index:Int) ->String {
        return self.substringFromIndex(advance(startIndex, index));
    }
    
    func substringWithRange(range:NSRange) ->String {
        return self.substringWithRange(Range(start: advance(startIndex, range.location), end: advance(startIndex, range.location+range.length)));
        
    }
    
    func escape() ->String? {
        if let chars = self.cStringUsingEncoding(NSISOLatin1StringEncoding) {
            var res = Array<CChar>();
            for x in chars {
                if x == "+" || x == ":" || x == "'" || x == "?" {
                    res.append("?");
                }
                res.append(x);
            }
            return String(CString: res, encoding: NSISOLatin1StringEncoding);
        } else {
            logError("String "+self+" could not be converted to ISOLatin1");
            return nil;
        }
    }
}
