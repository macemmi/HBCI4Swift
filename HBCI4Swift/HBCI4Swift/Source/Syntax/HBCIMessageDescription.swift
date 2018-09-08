//
//  HBCIMessageDescription.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 03.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCIMessageDescription: HBCISyntaxElementDescription {
    var defaults:Dictionary<String, Any> = [:];
    
    override init(syntax: HBCISyntax, element: XMLElement) throws {
        try super.init(syntax: syntax, element: element);
        self.delimiter = HBCIChar.quote.rawValue;
        self.elementType = ElementType.message;
        
        let defs = element.elements(forName: "default") ;
        for def in defs {
            if let path = def.valueForAttribute("path") {
                if let s = def.stringValue {
                    self.defaults[path] = s;
                }
            }
        }
    }
    
    override func compose() -> HBCISyntaxElement? {
        if let element = super.compose() {
            for (path, value) in self.defaults {
                if !element.setElementValue(value, path: path) { return nil; }
            }
            return element;
        }
        return nil;
    }
    
    override func getElement() -> HBCISyntaxElement? {
        return HBCIMessage(description: self);
    }
    
    

}
