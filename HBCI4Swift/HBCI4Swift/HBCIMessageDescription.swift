//
//  HBCIMessageDescription.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 03.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCIMessageDescription: HBCISyntaxElementDescription {
    var defaults:Dictionary<String, AnyObject> = [:];
    
    override init?(syntax: HBCISyntax, element: NSXMLElement) {
        super.init(syntax: syntax, element: element);
        self.delimiter = "'";
        self.elementType = ElementType.Message;
        
        let defs = element.elementsForName("default") as! [NSXMLElement];
        for def in defs {
            if let path = def.valueForAttribute("path") {
                if let s = def.stringValue {
                    self.defaults[path] = s;
                }
            }
        }
    }
    
    override func compose() -> HBCISyntaxElement? {
        if var element = super.compose() {
            for (path, value) in self.defaults {
                element.setElementValue(value, path: path);
            }
            return element;
        }
        return nil;
    }
    
    override func getElement() -> HBCISyntaxElement? {
        return HBCIMessage(description: self);
    }
    
    

}