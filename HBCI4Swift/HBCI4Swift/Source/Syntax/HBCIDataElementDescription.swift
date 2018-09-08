//
//  HBCIDataElementDescription.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 21.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

enum HBCIDataElementType {
    case alphaNumeric,  // FinTS character set withoug CR/LF
    binary,
    code,
    country,
    currency,
    dtaus,
    date,
    digits,  // 0-9, leading zeroes are allowed
    id,
    boole,
    numeric, // 0-9, leading zeroes not allowed
    time,
    value
}

var _dateFormatter: DateFormatter!
var _timeFormatter: DateFormatter!
var _numberFormatter: NumberFormatter!
var _numberHandler: NSDecimalNumberHandler!


class HBCIDataElementDescription: HBCISyntaxElementDescription {
    let minsize = 0, maxsize = 0;
    var dataType: HBCIDataElementType!
    
    override init(syntax: HBCISyntax, element: XMLElement) throws {
        try super.init(syntax: syntax, element: element)
        self.delimiter = HBCIChar.plus.rawValue;
        self.elementType = .dataElement
        
        if let type = self.type {
            if(!setDataType(type)) {
                logError("Syntax file error: unknown data type \(self.type!)");
                throw HBCIError.syntaxFileError;
            }
        } else {
            logError("Syntax file error: Data Element has no type");
            throw HBCIError.syntaxFileError;
        }
        
        initFormatters()
    }
    
    func initFormatters() {
        if _dateFormatter == nil {
            _dateFormatter = DateFormatter()
            _dateFormatter.dateFormat = "yyyyMMdd"
            _dateFormatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        }
        if _timeFormatter == nil {
            _timeFormatter = DateFormatter()
            _timeFormatter.dateFormat = "HHmmss"
            _timeFormatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        }
        if _numberFormatter == nil {
            _numberFormatter = NumberFormatter()
            _numberFormatter.decimalSeparator = ","
            _numberFormatter.alwaysShowsDecimalSeparator = true
            _numberFormatter.minimumFractionDigits = 0
            _numberFormatter.maximumFractionDigits = 2
            _numberFormatter.generatesDecimalNumbers = true;
        }
        if _numberHandler == nil {
            _numberHandler = NSDecimalNumberHandler(roundingMode: NSDecimalNumber.RoundingMode.plain, scale: 2, raiseOnExactness: true, raiseOnOverflow: true, raiseOnUnderflow: true, raiseOnDivideByZero: true);
        }
    }
    
    func setDataType(_ type:String) ->Bool {
        switch type {
            case "AN": self.dataType = .alphaNumeric
            case "Code": self.dataType = .code
            case "Bin": self.dataType = .binary
            case "Ctr": self.dataType = .country
            case "Cur": self.dataType = .currency
            case "DTAUS": self.dataType = .dtaus
            case "Date": self.dataType = .date
            case "Dig": self.dataType = .digits
            case "ID": self.dataType = .id
            case "JN": self.dataType = .boole
            case "Num": self.dataType = .numeric
            case "Time": self.dataType = .time
            case "Wrt": self.dataType = .value
        default: self.dataType = nil; return false;
        }
        return true;
    }
    
    override func elementDescription() ->String {
        let s = self.stringValue ?? "none"
        let n = self.name ?? "none"
        return "DE name: \(n) value: \(s) \n"
    }
    
    override func parse(_ bytes: UnsafePointer<CChar>, length: Int, binaries:Array<Data>) ->HBCISyntaxElement? {
        let de = HBCIDataElement(description: self);
        de.name = self.name ?? "";
        
        // check if first character is a delimiter
        var sidx = 0, tidx = 0;
        var escaped: Bool = false;
        var target = [CChar](repeating: 0, count: length+1);
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
                sidx += 1;
            } else {
                target[tidx] = bytes[sidx];
                tidx += 1; sidx += 1;
                escaped = false;
            }
        }
        
        target[tidx] = 0;
        if sidx > 0 && tidx > 0 {
            if let sValue = String(cString: target, encoding: String.Encoding.isoLatin1) {
                
                if let type = self.dataType {
                    switch type {
                    case .value:
                        if let value = _numberFormatter.number(from: sValue) {
                            // formatter returns a NSDecimalNumber
                            de.value = (value as! NSDecimalNumber).rounding(accordingToBehavior: _numberHandler);
                        } else {
                            logError("Parse error: string \(sValue) cannot be converted to a number");
                            return nil;
                        }
                        
                    case .boole: de.value = (sValue == "J");
                    case .date:
                        if let date = _dateFormatter.date(from: sValue) {
                            de.value = date;
                        } else {
                            logError("Parse error: string \(sValue) cannot be converted to a date");
                            return nil;
                        }
                    case .time:
                        if let time = _timeFormatter.date(from: sValue) {
                            de.value = time;
                        } else {
                            logError("Parse error: string \(sValue) cannot be converted to a time");
                            return nil;
                        }
                    case .binary:
                        if sValue.hasPrefix("@") && sValue.hasSuffix("@") {
                            let range = Range<String.Index>(sValue.index(sValue.startIndex, offsetBy: 1) ..< sValue.index(sValue.endIndex, offsetBy: -1));
                            let idxString = sValue[range];
                            if let idx = Int(idxString) {
                                de.value = binaries[idx];
                            }
                        } else {
                            logError("Invalid binary tag: \(sValue)");
                            return nil;
                        }
                    case .numeric:
                        de.value = Int(sValue);
                        
                        
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

