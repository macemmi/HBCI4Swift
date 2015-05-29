//
//  HBCIUtils.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

var _instance:HBCIUtils?

private var __dateFormatter:NSDateFormatter?
private var __timeFormatter:NSDateFormatter?
private var __numberFormatter:NSNumberFormatter?
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
    
    class func dateFormatter() ->NSDateFormatter {
        if let formatter = __dateFormatter {
            return formatter;
        } else {
            let formatter = NSDateFormatter();
            formatter.dateFormat = "yyyyMMdd";
            formatter.timeZone = NSTimeZone(name: "Europe/Berlin");
            __dateFormatter = formatter;
            return formatter;
        }
    }
    
    class func timeFormatter() ->NSDateFormatter {
        if let formatter = __timeFormatter {
            return formatter;
        } else {
            let formatter = NSDateFormatter();
            formatter.dateFormat = "HHmmss";
            formatter.timeZone = NSTimeZone(name: "Europe/Berlin");
            __timeFormatter = formatter;
            return formatter;
        }
    }
    
    class func numberFormatter() ->NSNumberFormatter {
        if let formatter = __numberFormatter {
            return formatter;
        } else {
            let formatter = NSNumberFormatter();
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
            let handler = NSDecimalNumberHandler(roundingMode: NSRoundingMode.RoundPlain, scale: 2, raiseOnExactness: true, raiseOnOverflow: true, raiseOnUnderflow: true, raiseOnDivideByZero: true);
            __numberHandler = handler;
            return handler;
        }
    }
    
    class func round(x:NSDecimalNumber) ->NSDecimalNumber {
        return x.decimalNumberByRoundingAccordingToBehavior(HBCIUtils.numberHandler());
    }
    
}