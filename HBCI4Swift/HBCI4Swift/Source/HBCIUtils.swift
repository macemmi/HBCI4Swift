//
//  HBCIUtils.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

var _instance:HBCIUtils?

private var __dateFormatter:DateFormatter?
private var __timeFormatter:DateFormatter?
private var __dateTimeFormatter:DateFormatter?
private var __numberFormatter:NumberFormatter?
private var __numberHandler:NSDecimalNumberHandler?


class HBCIUtils {
    
    init() {
    }
    
    class func instance() ->HBCIUtils {
        if let inst = _instance {
            return inst;
        } else {
            _instance = HBCIUtils();
            return _instance!;
        }
    }
    
    class func dateFormatter() ->DateFormatter {
        if let formatter = __dateFormatter {
            return formatter;
        } else {
            let formatter = DateFormatter();
            formatter.dateFormat = "yyyyMMdd";
            formatter.timeZone = TimeZone(identifier: "Europe/Berlin");
            __dateFormatter = formatter;
            return formatter;
        }
    }
    
    class func timeFormatter() ->DateFormatter {
        if let formatter = __timeFormatter {
            return formatter;
        } else {
            let formatter = DateFormatter();
            formatter.dateFormat = "HHmmss";
            formatter.timeZone = TimeZone(identifier: "Europe/Berlin");
            __timeFormatter = formatter;
            return formatter;
        }
    }
    
    class func dateTimeFormatter() ->DateFormatter {
        if let formatter = __dateTimeFormatter {
            return formatter;
        } else {
            let formatter = DateFormatter();
            formatter.dateFormat = "yyyyMMddHHmmss";
            formatter.timeZone = TimeZone(identifier: "Europe/Berlin");
            __dateTimeFormatter = formatter;
            return formatter;

        }
    }
    
    class func numberFormatter() ->NumberFormatter {
        if let formatter = __numberFormatter {
            return formatter;
        } else {
            let formatter = NumberFormatter();
            formatter.decimalSeparator = ",";
            formatter.alwaysShowsDecimalSeparator = true;
            formatter.minimumFractionDigits = 0;
            formatter.maximumFractionDigits = 2;
            formatter.generatesDecimalNumbers = true;
            __numberFormatter = formatter;
            return formatter;
        }
    }
    
    class func numberHandler() ->NSDecimalNumberHandler {
        if let handler = __numberHandler {
            return handler;
        } else {
            let handler = NSDecimalNumberHandler(roundingMode: NSDecimalNumber.RoundingMode.plain, scale: 2, raiseOnExactness: true, raiseOnOverflow: true, raiseOnUnderflow: true, raiseOnDivideByZero: true);
            __numberHandler = handler;
            return handler;
        }
    }
    
    class func round(_ x:NSDecimalNumber) ->NSDecimalNumber {
        return x.rounding(accordingToBehavior: HBCIUtils.numberHandler());
    }
    
}
