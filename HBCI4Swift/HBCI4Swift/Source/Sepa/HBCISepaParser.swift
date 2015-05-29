//
//  HBCISepaParser.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 22.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISepaParser {
    let format:HBCISepaFormat;

    let numberFormatter = NSNumberFormatter();

    init(format:HBCISepaFormat) {
        self.format = format;
        initFormatters();
    }
    
    private func initFormatters() {
        numberFormatter.decimalSeparator = ".";
        numberFormatter.alwaysShowsDecimalSeparator = true;
        numberFormatter.minimumFractionDigits = 2;
        numberFormatter.maximumFractionDigits = 2;
        numberFormatter.generatesDecimalNumbers = true;
    }
    
    func stringToNumber(s:String) ->NSDecimalNumber? {
        if let number = numberFormatter.numberFromString(s) as? NSDecimalNumber {
            return number;
        } else {
            logError("Sepa document parser: not able to convert \(s) to a value");
            return nil;
        }
    }
    
    func stringToDate(s:String) ->NSDate? {
        let formatter = NSDateFormatter();
        formatter.dateFormat = "yyyy-MM-dd";
        if let date = formatter.dateFromString(s) {
            return date;
        } else {
            logError("Sepa document parser: not able to convert \(s) to a date");
            return nil;
        }
    }
    
    func checkTransferData(iban:String?, bic:String?, name:String?, value:NSDecimalNumber?, currency:String?) ->Bool {
        if iban == nil {
            logError("Sepa document parser: IBAN is missing");
            return false;
        }
        if bic == nil {
            logError("Sepa document parser: BIC is missing");
            return false;
        }
        if name == nil {
            logError("Sepa document parser: Creditor name is missing");
            return false;
        }
        if value == nil {
            logError("Sepa document parser: value is missing");
            return false;
        }
        if currency == nil {
            logError("Sepa document parser: currency is missing");
            return false;
        }
        return true;
    }

}
