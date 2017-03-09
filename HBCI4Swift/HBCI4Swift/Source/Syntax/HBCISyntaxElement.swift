//
//  HBCISyntaxElement.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 27.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCISyntaxElement {
    let descr: HBCISyntaxElementDescription
    var children = Array<HBCISyntaxElement>();
    var name: String = "";
    var length = 0;
    let type:ElementType;
    
    init(description: HBCISyntaxElementDescription) {
        descr = description;
        type = descr.elementType;
    }
    
    func elementDescription() ->String {
        return "";
    }
    
    func descriptionWithLevel(_ level: Int) ->String {
        var s:String = "";
        for _ in 0..<level {
            s += "\t";
        }
        s += elementDescription();
        for element in self.children as [HBCISyntaxElement] {
            s += element.descriptionWithLevel(level+1);
        }
        return s;
    }
    /*
    func description() -> String {
        return descriptionWithLevel(0);
    }
    */
    
    var description: String {
        return descriptionWithLevel(0);
    }
    
    var debugDescription: String {
        return descriptionWithLevel(0);
    }

    
    var isEmpty: Bool {
        for elem in self.children {
            if !elem.isEmpty {
                return false;
            }
        }
        return true;
    }
    
    open func setElementValue(_ value:Any, path:String) ->Bool {
        let (name, newPath) = firstComponent(path);
        
        for elem in self.children {
            if elem.name == name {
                if newPath != nil {
                    return elem.setElementValue(value, path: newPath!);
                } else {
                    if elem.type == ElementType.dataElement {
                        if let de = elem as? HBCIDataElement {
                            de.value = value;
                            return true;
                        }
                    }
                    logError("Value cannot be set for \(name) (no data element)");
                    return false;
                }
            }
        }
        
        logError("Child element \(name) in \(self.name) not found");
        return false;
    }
    
    open func setElementValues(_ values:Dictionary<String,Any>) ->Bool {
        for (path, value) in values {
            if !setElementValue(value, path: path) {
                return false;
            }
        }
        return true;
    }
    
    /*
    func elementValueForPath(comps:Array<String>) ->Any? {
        let name = comps[0];
        var newComps = comps;
        newComps.removeAtIndex(0);
        for elem in self.children {
            if elem.name == name {
                if elem.type == ElementType.DataElement {
                    if let de = elem as? HBCIDataElement {
                        return de.value;
                    }
                } else {
                    // no data element
                    if newComps.count > 0 {
                        return elem.elementValueForPath(newComps);
                    } else {
                        logError("Value cannot be read from \(name) (no data element)");
                        return nil;
                    }
                }
            }
        }
        logError("Child element \(name) in \(self.name) not found");
        return nil;
    }
    */
    
    open func elementValueForPath(_ path:String) ->Any? {
        let (name, newPath) = firstComponent(path);
        
        for elem in self.children {
            if elem.name == name {
                if elem.type == ElementType.dataElement {
                    if let de = elem as? HBCIDataElement {
                        return de.value;
                    }
                } else {
                    // no data element
                    if newPath != nil {
                        return elem.elementValueForPath(newPath!);
                    } else {
                        logError("Value cannot be read from \(name) (no data element)");
                        return nil;
                    }
                }
            }
        }
        // if element was not found, check if it is optional
        for ref in self.descr.children {
            if ref.name == name {
                if ref.minnum == 0 {
                    // element is optional - don't issue error message
                    return nil;
                }
            }
        }
        logError("Child element \(name) in \(self.name) not found");
        return nil;
    }
    
    open func elementValuesForPath(_ path:String) ->Array<Any> {
        var result = Array<Any>();
        let (name, newPath) = firstComponent(path);

        for elem in self.children {
            if elem.name == name {
                if elem.type == ElementType.dataElement {
                    if let de = elem as? HBCIDataElement {
                        if let value:Any = de.value {
                            result.append(value);
                        }
                    }
                } else {
                    // no data element
                    if newPath != nil {
                        let res = elem.elementValuesForPath(newPath!);
                        result += res;
                    } else {
                        logError("Get element value: newPath = nil but \(name) is no data element");
                    }
                }
            }
        }
        return result;
    }
    
    open func elementForPath(_ path:String) ->HBCISyntaxElement? {
        let (name, newPath) = firstComponent(path);
        
        for elem in self.children {
            if elem.name == name {
                if newPath == nil {
                    return elem;
                } else {
                    return elem.elementForPath(newPath!);
                }
            }
        }
        return nil;
    }
    
    open func elementsForPath(_ path:String) ->Array<HBCISyntaxElement> {
        var result = Array<HBCISyntaxElement>();
        let (name, newPath) = firstComponent(path);
        
        for elem in self.children {
            if elem.name == name {
                if newPath == nil {
                    result.append(elem);
                } else {
                    return elem.elementsForPath(newPath!);
                }
            }
        }
        return result;
    }

    
    open func checkValidsForPath(_ path:String, valids:Array<String>) ->Bool {
        let (name, newPath) = firstComponent(path);
        
        for elem in self.children {
            if elem.name == name {
                if newPath != nil {
                    if !elem.checkValidsForPath(newPath!, valids: valids) {
                        return false;
                    }
                } else {
                    if !elem.checkValidsForPath("", valids: valids) {
                        return false;
                    }
                }
            }
        }
        return true;
    }
    
    open func messageData(_ data:NSMutableData) {
        var delim = self.descr.delimiter;
        for idx in 0..<self.children.count {
            let element = self.children[idx];
            element.messageData(data);
            if idx < self.children.count - 1 {
                data.append(&delim, length: 1);
            }
        }
        
        // now remove unneccesary delimiters from the end
        var size = data.length;
        let content = data.bytes.assumingMemoryBound(to: CChar.self);
        for _ in 0..<self.children.count {
            let p = content.advanced(by: size-1);
            if p.pointee == delim {
                size -= 1;
            } else {
                break;
            }
        }
        if size < data.length {
            data.length = size;
        }
    }
    
    open func messageString() ->String {
        let delim = self.descr.delimiter;
        let delimStr = String(Character(UnicodeScalar(Int(delim))!));
        var empties = "";
        var result = ""
        for idx in 0..<self.children.count {
            let element = self.children[idx];
            let elemStr = element.messageString();
            if elemStr.characters.count == 0 {
                empties += delimStr;
            } else {
                if empties.characters.count > 0 {
                    result += empties;
                    empties = "";
                }
                result += elemStr;
                empties += delimStr;
            }
        }
        return result;
    }
    
    func validate() ->Bool {
        var idx = 0, childCount = 0, elemIdx = 0;
        var success = true;
        //var stop = false;
        
        while idx < self.descr.children.count {
            let ref = self.descr.children[idx];
            let childElem = self.children[elemIdx];
            
            if self.name == "KeyReq" {
                //stop = true;
            }
            
            if ref.elemDescr === childElem.descr {
                if !childElem.isEmpty {
                    childCount += 1;
                    if !childElem.validate() {
                        success = false;
                    }
                }
                elemIdx += 1;
            }
            if !(ref.elemDescr === childElem.descr) || elemIdx >= self.children.count {
                // we have a different element
                if childCount < ref.minnum {
                    logError("Element \(self.name): child element \(ref.name) occured \(childCount) times but must occur at least \(ref.minnum) times");
                }
                if childCount > ref.maxnum {
                    logError("Element \(self.name): child element \(ref.name) occured \(childCount) times but must occur at most \(ref.maxnum) times");
                }
                if elemIdx < self.children.count {
                    childCount = 0;
                }
                idx += 1;
            }
        }
        return success;
    }
    
    open func addElement(_ name:String) ->HBCISyntaxElement? {
        var idx = 0;
        var reference:HBCISyntaxElementReference?
        
        // first get reference with name
        for ref in self.descr.children {
            if ref.name == name {
                // now check if it is a multi element
                if ref.maxnum <= 1 {
                    logError("Element \(name) could not be added - only one instance is allowed");
                    return nil;
                }
                reference = ref;
                break;
            }
        }
        if reference == nil {
            logError("Reference for \(name) could not be found");
            return nil;
        }
        
        while idx < children.count {
            let childElem = children[idx];
            if childElem.name == name {
                // now we have the right child element
                if let child = reference!.elemDescr.compose() {
                    child.name = reference!.name;
                    self.children.append(child);
                    return child;
                } else {
                    return nil;
                }
            }
            idx += 1;
        }
        return nil;
    }
    
}
