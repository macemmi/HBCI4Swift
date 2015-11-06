//
//  HBCIDataElement.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 27.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCIDataElement: HBCISyntaxElement {
    var _isEmpty: Bool = true;
    var value: AnyObject?

    override init(description: HBCISyntaxElementDescription) {
        super.init(description:
            description);
    }
    
    override func elementDescription() -> String {
        let name = self.name ?? "none";
        let val: AnyObject = self.value ?? "none";
        return "DE name: \(name), value: \(val)\n";
    }
    
    override var isEmpty: Bool {
        return self.value == nil;
    }
    
    override func setElementValue(value: AnyObject, path: String) -> Bool {
        self.value = value;
        return true;
    }
    
    func toString() ->String? {
        if self.value == nil {
            // no value
            return nil;
        }
        
        if let dataElemDescr = self.descr as? HBCIDataElementDescription {
            switch dataElemDescr.dataType! {
            case HBCIDataElementType.Value:
                if let val = self.value as? NSDecimalNumber {
                    return _numberFormatter.stringFromNumber(val);
                } else {
                    logError("Element value \(self.value) is not a number value");
                    return nil;
                }
            case HBCIDataElementType.Date:
                if let date = self.value as? NSDate {
                    return _dateFormatter.stringFromDate(date);
                } else {
                    logError("Element value \(self.value) is not a date value");
                    return nil;
                }
            case HBCIDataElementType.Time:
                if let time = self.value as? NSDate {
                    return _timeFormatter.stringFromDate(time).escape();
                } else {
                    logError("Element value \(self.value) is not a date(time) value");
                    return nil;
                }
            case HBCIDataElementType.Boole:
                if let b:Bool = self.value as? Bool {
                    return b ? "J" : "N";
                } else {
                    logError("Element value \(self.value) is not a boolean value");
                    return nil;
                }
            case HBCIDataElementType.Binary:
                if let data = self.value as? NSData {
                    let sizeString = String(format: "@%lu@", data.length)
                    if data.hasNonPrintableChars() {
                        return sizeString+data.description;
                    } else {
                        if let dataString = NSString(data: data, encoding: NSISOLatin1StringEncoding) as? String {
                            return sizeString+dataString;
                        } else {
                            logError("Element value \(self.value) cannot be converted to a string");
                            return nil;
                        }
                    }
                } else {
                    logError("Element value \(self.value) is not a NSData object");
                    return nil;
                }
            case HBCIDataElementType.Numeric:
                if let n = self.value as? Int {
                    return "\(n)";
                } else {
                    // check if value is a numeric string
                    if let s = self.value as? String {
                        if Int(s) !=  nil {
                            return s;
                        }
                    }
                    logError("Element value \(self.value) is not an Integer");
                    return nil;
                }
                
            default:
                if let s = self.value as? String {
                    return s.escape();
                } else {
                    logError("Element value \(self.value) is not a string value");
                    return nil;
                }
            }
        }
        return nil;
    }
    
    override func checkValidsForPath(path: String, valids: Array<String>) -> Bool {
        if let descr = self.descr as? HBCIDataElementDescription {
            if let type = descr.dataType {
                switch type {
                case HBCIDataElementType.AlphaNumeric, HBCIDataElementType.Code:
                    if let value = self.value as? String {
                        for s in valids {
                            if s == value {
                                return true;
                            }
                        }
                        logError("Value \(value) of data element \(self.name) is not valid");
                        return false;
                    }
                case HBCIDataElementType.Numeric:
                    if let value = self.value as? Int {
                        for s in valids {
                            if let n = Int(s) {
                                if value == n {
                                    return true;
                                }
                            } else {
                                logError("HBCISyntaxFileError: valid \(s) is not a number");
                                return false;
                            }
                        }
                    } else {
                        logError("Element value \(value) is not a number");
                        return false;
                    }
                default:
                    return true; // no validation if not a string or a number
                }
            }
        } else {
            logError("Data element \(self.name) has invalid description");
            return false;
        }
        return true;
    }
    
    override func messageData(data: NSMutableData) {
        if self.value == nil {
            return;
        }
        if let descr = self.descr as? HBCIDataElementDescription {
            if descr.dataType == HBCIDataElementType.Binary {
                if let myData = self.value as? NSData {
                    let sizeString = NSString(format: "@%lu@", myData.length);
                    if let sizeData = sizeString.dataUsingEncoding(NSISOLatin1StringEncoding) {
                        data.appendData(sizeData);
                        data.appendData(myData);
                    } else {
                        logError("Error generating sizeString");
                    }
                } else {
                    logError("Value \(self.value) cannot be converted to NSData");
                }
            } else {
                if let s = toString() {
                    data.appendData(s.dataUsingEncoding(NSISOLatin1StringEncoding, allowLossyConversion:true)!);
                } else {
                    logError("Value \(self.value) cannot be converted to string");
                }
            }
        }
    }
    
    override func messageString() -> String {
        if self.value == nil {
            // no value
            return "";
        }
        
        if let s = toString() {
            if name == "pin" {
                return "pin";
            }
            return s;
        } else {
            return "<undefined>";
        }
    }
    
}
