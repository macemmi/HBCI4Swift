//
//  HBCISyntaxElementDescription.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 20.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

enum ElementType {
    case none, message, segment, dataElementGroup, dataElement
}

class HBCISyntaxElementDescription: CustomStringConvertible, CustomDebugStringConvertible {
    let syntax: HBCISyntax;
    var syntaxElement: XMLElement;
    var children = Array<HBCISyntaxElementReference>();
    var values = Dictionary<String, Any>();
    var valids = Dictionary<String, Array<String>>();
    var identifier, name, type: String?;
    var delimiter = HBCIChar.qmark.rawValue;
    var elementType: ElementType = .none;
    var stringValue: String?;
    
    init(syntax:HBCISyntax, element:XMLElement) throws {
        self.syntax = syntax;
        self.syntaxElement = element;
        
        self.identifier = element.valueForAttribute("id");
        self.name = element.valueForAttribute("name");
        self.type = element.valueForAttribute("type");
        
        if let children = element.children {
            for node in children {
                if node.kind == XMLNode.Kind.element {
                    let childElem = node as! XMLElement;
                    
                    if childElem.name == "DEG" || childElem.name == "SEG" || childElem.name == "DE" {
                        var child: HBCISyntaxElementDescription?
                        
                        if childElem.name == "DE" {
                            child = try HBCIDataElementDescription(syntax: self.syntax, element: childElem);
                        } else {
                            // structured element
                            if let type = childElem.valueForAttribute("type") {
                                if childElem.name == "DEG" {
                                    child = self.syntax.degs[type];
                                }
                                if childElem.name == "SEG" {
                                    // for messages and message composition: we take the highest supported segment version
                                    // (as we only parse messages, this part is only used for message composition)
                                    if let versions = self.syntax.segs[type] {
                                        child = versions.latestVersion();
                                    }
                                }
                                
                                if child == nil {
                                    // no reference found
                                    logError("Type \(type) not found in syntax");
                                    throw HBCIError.syntaxFileError;
                                }
                            }
                        }
                        let ref = try HBCISyntaxElementReference(element: childElem, description: child!);
                        self.children.append(ref);
                    } else if childElem.name == "valids" {
                        // handle valids
                        parseValidsForElement(childElem);
                    } else if childElem.name == "value" {
                        // handle values
                        if(!parseValueForElement(childElem)) {
                            logError("Syntax file error: value element \(childElem) could not be parsed");
                        }
                    } else if childElem.name == "default" {
                        // do nothing. Handled in HBCIMessageDescription
                    } else {
                        // invalid
                        logError("Syntax file error: invalid child element \(childElem)");
                        throw HBCIError.syntaxFileError;
                    }
                }
            }
        }
    }
    
    func elementDescription() -> String {
        return "name: \(self.name) value: \(self.stringValue) \n";
    }
    
    func descriptionWithLevel(_ level: Int) -> String {
        var s:String = "";
        for _ in 0 ..< level {
            s += "\t";
        }
        s += elementDescription();
        for element in self.children as [HBCISyntaxElementReference] {
            s += element.elemDescr.descriptionWithLevel(level+1);
        }
        return s;
    }

    var description: String {
        get { return descriptionWithLevel(0); }
    }
    
    var debugDescription: String {
        get { return descriptionWithLevel(0); }
    }
    
    func parseValueForElement(_ elem: XMLElement) ->Bool {
        if let path = elem.valueForAttribute("path") {
            if let value = elem.stringValue {
                self.values[path] = value;
                return true;
            }
        }
        return false;
    }
    
    func parseValidsForElement(_ elem: XMLElement) {
        var values: Array<String> = [];
        
        if let path = elem.valueForAttribute("path") {
            if let children = elem.children {
                for node in children {
                    if node.kind == XMLNode.Kind.element {
                        let element = node as! XMLElement;
                        if element.name == "validvalue" && element.stringValue != nil {
                            values.append(element.stringValue!);
                        }
                    }
                }
            }
            self.valids[path] = values;
        }
    }
    
    func parse(_ bytes: UnsafePointer<CChar>, length: Int, binaries:Array<Data>) ->HBCISyntaxElement? {
        return nil;
    }
    
    func getElement() ->HBCISyntaxElement? {
        return nil;
    }
    
    func compose() ->HBCISyntaxElement? {
        if let element = self.getElement() {
            for ref in self.children {
                if let child = ref.elemDescr.compose() {
                    child.name = ref.name;
                    element.children.append(child);
                } else {
                    return nil;
                }
            }
            
            // set values
            for (path, value) in self.values {
                if(!element.setElementValue(value, path: path)) {
                    return nil;
                }
            }
            
            return element;
        } else {
            return nil;
        }
    }
    
}
