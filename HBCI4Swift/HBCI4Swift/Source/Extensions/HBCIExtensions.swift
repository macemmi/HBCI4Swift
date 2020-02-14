//
//  HBCIExtensions.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 11.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

extension Data {
    func hasNonPrintableChars() ->Bool {
        var p = UnsafeMutablePointer<UInt8>(mutating: (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count));
        for _ in 0..<self.count {
            let c = p.pointee;
            if !((c >= 0x20 && c <= 0x7E) || c >= 0xA1 || c == 0x0A || c == 0x0D) {
                return true;
            }
            p = p.advanced(by: 1);
        }
        
        return false;
    }
}

extension XMLElement {
    func elementsForPath(_ path:String) ->[XMLElement] {
        var result = Array<XMLElement>();
        
        let (name, newPath) = firstComponent(path);
        
        if let nodes = self.children {
            for node in nodes {
                if node.kind == XMLNode.Kind.element {
                    if let child = node as? XMLElement {
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
    
    func stringValueForPath(_ path:String) ->String? {
        let elems = elementsForPath(path);
        return elems.first?.stringValue;
    }
    
    func createPath(_ path:String) ->XMLElement {
        let (name, newPath) = firstComponent(path);
        
        if let nodes = self.children {
            for node in nodes {
                if node.kind == XMLNode.Kind.element {
                    if let child = node as? XMLElement {
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
        let child = XMLElement(name: name);
        self.addChild(child);
        if newPath == nil {
            return child;
        } else {
            return child.createPath(newPath!);
        }
    }
    
    func setStringValueForPath(_ value:String, path:String) {
        let elem = createPath(path);
        elem.stringValue = value;
    }
}


extension String {

    func substringToIndex(_ index:Int) ->String {
        return String(self[..<self.index(startIndex, offsetBy: index)]);
    }
    
    func substringFromIndex(_ index:Int) ->String {
        return String(self.suffix(from: self.index(startIndex, offsetBy: index)));
    }
    
    func substringWithRange(_ range:NSRange) ->String {
        return String(self[self.index(startIndex, offsetBy: range.location) ..< self.index(startIndex, offsetBy: range.location+range.length)]);
    }
    
    func escape() ->String? {
        if let chars = self.cString(using: String.Encoding.isoLatin1) {
            var res = Array<CChar>();
            for x in chars {
                if  x == HBCIChar.plus.rawValue ||
                    x == HBCIChar.dpoint.rawValue ||
                    x == HBCIChar.quote.rawValue ||
                    x == HBCIChar.qmark.rawValue ||
                    x == HBCIChar.amper.rawValue {
                    res.append(HBCIChar.qmark.rawValue);
                }
                res.append(x);
            }
            return String(cString: res, encoding: String.Encoding.isoLatin1);
        } else {
            logInfo("String "+self+" could not be converted to ISOLatin1");
            return nil;
        }
    }
}
