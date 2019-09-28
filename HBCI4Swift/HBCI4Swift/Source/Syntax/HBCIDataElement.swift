//
//  HBCIDataElement.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 27.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

public func anonymize(_ s:String) ->String {
    if s.count == 0 {
        return s;
    }
    var result = s.substringToIndex(1);
    
    let len = s.count / 2;
    if len == 0 {
        return s;
    }
    
    for _ in 1..<len {
        result += "*";
    }
    result += s.substringFromIndex(len);
    return result;
}

class HBCIDataElement: HBCISyntaxElement {
    var _isEmpty: Bool = true;
    var value: Any?

    override init(description: HBCISyntaxElementDescription) {
        super.init(description:
            description);
    }
    
    override func elementDescription() -> String {
        return "DE name: \(self.name), value: \(messageString())\n";
    }
    
    override var isEmpty: Bool {
        return self.value == nil;
    }
    
    override func setElementValue(_ value: Any, path: String) -> Bool {
        self.value = value;
        return true;
    }
    
    func valueString() -> String {
        if let val = self.value {
            return "\(val)";
        } else {
            return "<nil>";
        }
    }
    
    func toString() ->String? {
        if self.value == nil {
            // no value
            return nil;
        }
        
        if let dataElemDescr = self.descr as? HBCIDataElementDescription {
            switch dataElemDescr.dataType! {
            case HBCIDataElementType.value:
                if let val = self.value as? NSDecimalNumber {
                    return _numberFormatter.string(from: val);
                } else {
                    logInfo("Element value \(valueString()) is not a number value");
                    return nil;
                }
            case HBCIDataElementType.date:
                if let date = self.value as? Date {
                    return _dateFormatter.string(from: date);
                } else {
                    logInfo("Element value \(valueString()) is not a date value");
                    return nil;
                }
            case HBCIDataElementType.time:
                if let time = self.value as? Date {
                    return _timeFormatter.string(from: time).escape();
                } else {
                    logInfo("Element value \(valueString()) is not a date(time) value");
                    return nil;
                }
            case HBCIDataElementType.boole:
                if let b:Bool = self.value as? Bool {
                    return b ? "J" : "N";
                } else {
                    logInfo("Element value \(valueString()) is not a boolean value");
                    return nil;
                }
            case HBCIDataElementType.binary:
                if let data = self.value as? Data {
                    let sizeString = String(format: "@%lu@", data.count)
                    if data.hasNonPrintableChars() {
                        return sizeString+data.description;
                    } else {
                        if let dataString = NSString(data: data, encoding: String.Encoding.isoLatin1.rawValue) {
                            return sizeString + (dataString as String);
                        } else {
                            logInfo("Element value \(valueString()) cannot be converted to a string");
                            return nil;
                        }
                    }
                } else {
                    logInfo("Element value \(valueString()) is not a NSData object");
                    return nil;
                }
            case HBCIDataElementType.numeric:
                if let n = self.value as? Int {
                    return "\(n)";
                } else {
                    // check if value is a numeric string
                    if let s = self.value as? String {
                        if Int(s) !=  nil {
                            return s;
                        }
                    }
                    logInfo("Element value \(valueString()) is not an Integer");
                    return nil;
                }
                
            default:
                if let s = self.value as? String {
                    return s.escape();
                } else {
                    logInfo("Element value \(valueString()) is not a string value");
                    return nil;
                }
            }
        }
        return nil;
    }
    
    override func checkValidsForPath(_ path: String, valids: Array<String>) -> Bool {
        if let descr = self.descr as? HBCIDataElementDescription {
            if let type = descr.dataType {
                switch type {
                case HBCIDataElementType.alphaNumeric, HBCIDataElementType.code:
                    if let value = self.value as? String {
                        for s in valids {
                            if s == value {
                                return true;
                            }
                        }
                        logInfo("Value \(value) of data element \(self.name) is not valid");
                        return false;
                    }
                case HBCIDataElementType.numeric:
                    if let value = self.value as? Int {
                        for s in valids {
                            if let n = Int(s) {
                                if value == n {
                                    return true;
                                }
                            } else {
                                logInfo("HBCISyntaxFileError: valid \(s) is not a number");
                                return false;
                            }
                        }
                    } else {
                        logInfo("Element value \(valueString()) is not a number");
                        return false;
                    }
                default:
                    return true; // no validation if not a string or a number
                }
            }
        } else {
            logInfo("Data element \(self.name) has invalid description");
            return false;
        }
        return true;
    }
    
    override func messageData(_ data: NSMutableData) {
        if self.value == nil {
            return;
        }
        if let descr = self.descr as? HBCIDataElementDescription {
            if descr.dataType == HBCIDataElementType.binary {
                if let myData = self.value as? Data {
                    let sizeString = NSString(format: "@%lu@", myData.count);
                    if let sizeData = sizeString.data(using: String.Encoding.isoLatin1.rawValue) {
                        data.append(sizeData);
                        data.append(myData);
                    } else {
                        logInfo("Error generating sizeString");
                    }
                } else {
                    logInfo("Value \(valueString()) cannot be converted to NSData");
                }
            } else {
                if let s = toString() {
                    data.append(s.data(using: String.Encoding.isoLatin1, allowLossyConversion:true)!);
                } else {
                    logInfo("Value \(valueString()) cannot be converted to string");
                }
            }
        }
    }
    
    override func messageString() -> String {
        if self.value == nil {
            // no value
            return "";
        }
        if name == "data" {
            return "<data>";
        }
        
        if let s = toString() {
            if name == "pin" {
                return "pin\(s.count)";
            }
            if name == "number" || name == "subnumber" || name == "iban" || name == "userid" || name == "customerid" {
                return anonymize(s);
            }
            return s;
        } else {
            return "<none>";
        }
    }
    
}
