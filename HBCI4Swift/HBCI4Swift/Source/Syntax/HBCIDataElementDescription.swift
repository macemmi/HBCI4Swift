//
//  HBCIDataElementDescription.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 21.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

enum HBCIDataElementType {
    case AlphaNumeric,  // FinTS character set withoug CR/LF
    Binary,
    Code,
    Country,
    Currency,
    DTAUS,
    Date,
    Digits,  // 0-9, leading zeroes are allowed
    ID,
    Boole,
    Numeric, // 0-9, leading zeroes not allowed
    Time,
    Value
}

var _dateFormatter: NSDateFormatter!
var _timeFormatter: NSDateFormatter!
var _numberFormatter: NSNumberFormatter!
var _numberHandler: NSDecimalNumberHandler!


class HBCIDataElementDescription: HBCISyntaxElementDescription {
    let minsize = 0, maxsize = 0;
    var dataType: HBCIDataElementType!
    
    override init?(syntax: HBCISyntax, element: NSXMLElement) {
        super.init(syntax: syntax, element: element)
        self.delimiter = "+"
        self.elementType = .DataElement
        
        if let type = self.type {
            if(!setDataType(type)) {
                logError("Syntax file error: unknown data type \(self.type!)");
                return nil;
            }
        } else {
            logError("Syntax file error: Data Element has no type");
            return nil;
        }
        
        initFormatters()
    }
    
    func initFormatters() {
        if _dateFormatter == nil {
            _dateFormatter = NSDateFormatter()
            _dateFormatter.dateFormat = "yyyyMMdd"
            _dateFormatter.timeZone = NSTimeZone(name: "Europe/Berlin")
        }
        if _timeFormatter == nil {
            _timeFormatter = NSDateFormatter()
            _timeFormatter.dateFormat = "HHmmss"
            _timeFormatter.timeZone = NSTimeZone(name: "Europe/Berlin")
        }
        if _numberFormatter == nil {
            _numberFormatter = NSNumberFormatter()
            _numberFormatter.decimalSeparator = ","
            _numberFormatter.alwaysShowsDecimalSeparator = true
            _numberFormatter.minimumFractionDigits = 0
            _numberFormatter.maximumFractionDigits = 2
            _numberFormatter.generatesDecimalNumbers = true;
        }
        if _numberHandler == nil {
            _numberHandler = NSDecimalNumberHandler(roundingMode: NSRoundingMode.RoundPlain, scale: 2, raiseOnExactness: true, raiseOnOverflow: true, raiseOnUnderflow: true, raiseOnDivideByZero: true);
        }
    }
    
    func setDataType(type:String) ->Bool {
        switch type {
            case "AN": self.dataType = .AlphaNumeric
            case "Code": self.dataType = .Code
            case "Bin": self.dataType = .Binary
            case "Ctr": self.dataType = .Country
            case "Cur": self.dataType = .Currency
            case "DTAUS": self.dataType = .DTAUS
            case "Date": self.dataType = .Date
            case "Dig": self.dataType = .Digits
            case "ID": self.dataType = .ID
            case "JN": self.dataType = .Boole
            case "Num": self.dataType = .Numeric
            case "Time": self.dataType = .Time
            case "Wrt": self.dataType = .Value
        default: self.dataType = nil; return false;
        }
        return true;
    }
    
    override func elementDescription() ->String {
        let s = self.stringValue ?? "none"
        let n = self.name ?? "none"
        return "DE name: \(n) value: \(s) \n"
    }
    
    override func parse(bytes: UnsafePointer<CChar>, length: Int, binaries:Array<NSData>) ->HBCISyntaxElement? {
        var de = HBCIDataElement(description: self);
        de.name = self.name ?? "";
        
        // check if first character is a delimiter
        var sidx = 0, tidx = 0;
        var escaped: Bool = false;
        var target = [CChar](count:length+1, repeatedValue:0);
        var p = UnsafeMutablePointer<CChar>(bytes);
        while sidx < length {
            let c = bytes[sidx];
            if (c == HBCIChar_plus || c == HBCIChar_dpoint || c == HBCIChar_quote) && !escaped {
                // end detected
                break;
            }
            escaped = false;
            if c == HBCIChar_qmark && !escaped {
                escaped = true;
            }
            
            if escaped {
                // advance source but not target pointer
                sidx++;
            } else {
                target[tidx++] = bytes[sidx++];
                escaped = false;
            }
        }
        
        target[tidx] = 0;
        if sidx > 0 && tidx > 0 {
            if let sValue = String(CString: target, encoding: NSISOLatin1StringEncoding) {
                
                if let type = self.dataType {
                    switch type {
                    case .Value:
                        if let value = _numberFormatter.numberFromString(sValue) {
                            // formatter returns a NSDecimalNumber
                            de.value = (value as! NSDecimalNumber).decimalNumberByRoundingAccordingToBehavior(_numberHandler);
                        } else {
                            logError("Parse error: string \(sValue) cannot be converted to a number");
                            return nil;
                        }
                        
                    case .Boole: de.value = (sValue == "J");
                    case .Date:
                        if let date = _dateFormatter.dateFromString(sValue) {
                            de.value = date;
                        } else {
                            logError("Parse error: string \(sValue) cannot be converted to a date");
                            return nil;
                        }
                    case .Time:
                        if let time = _timeFormatter.dateFromString(sValue) {
                            de.value = time;
                        } else {
                            logError("Parse error: string \(sValue) cannot be converted to a time");
                            return nil;
                        }
                    case .Binary:
                        if sValue.hasPrefix("@") && sValue.hasSuffix("@") {
                            let range = Range<String.Index>(start: advance(sValue.startIndex, 1), end: advance(sValue.endIndex, -1));
                            let idxString = sValue.substringWithRange(range);
                            if let idx = idxString.toInt() {
                                de.value = binaries[idx];
                            }
                        } else {
                            logError("Invalid binary tag: \(sValue)");
                            return nil;
                        }
                    case .Numeric:
                        de.value = sValue.toInt();
                        
                        
                    default: de.value = sValue;
                    }
                }
            } else {
                logError("Parse error: data cannot be converted to String");
                return nil;
            }
        } 
        
        de.length = (sidx<=length) ? sidx:length;
        return de;
    }
    
    override func getElement() -> HBCISyntaxElement? {
        return HBCIDataElement(description: self);
    }
}

