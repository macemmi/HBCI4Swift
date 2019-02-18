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

    let numberFormatter = NumberFormatter();

    init(format:HBCISepaFormat) {
        self.format = format;
        initFormatters();
    }
    
    fileprivate func initFormatters() {
        numberFormatter.decimalSeparator = ".";
        numberFormatter.alwaysShowsDecimalSeparator = true;
        numberFormatter.minimumFractionDigits = 2;
        numberFormatter.maximumFractionDigits = 2;
        numberFormatter.generatesDecimalNumbers = true;
    }
    
    func stringToNumber(_ s:String) ->NSDecimalNumber? {
        if let number = numberFormatter.number(from: s) as? NSDecimalNumber {
            return number;
        } else {
            logDebug("Sepa document parser: not able to convert \(s) to a value");
            return nil;
        }
    }
    
    func stringToDate(_ s:String) ->Date? {
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd";
        if let date = formatter.date(from: s) {
            return date;
        } else {
            logDebug("Sepa document parser: not able to convert \(s) to a date");
            return nil;
        }
    }
    
    func checkTransferData(_ iban:String?, bic:String?, name:String?, value:NSDecimalNumber?, currency:String?) ->Bool {
        if iban == nil {
            logDebug("Sepa document parser: IBAN is missing");
            return false;
        }
        if bic == nil {
            logDebug("Sepa document parser: BIC is missing");
            return false;
        }
        if name == nil {
            logDebug("Sepa document parser: Creditor name is missing");
            return false;
        }
        if value == nil {
            logDebug("Sepa document parser: value is missing");
            return false;
        }
        if currency == nil {
            logDebug("Sepa document parser: currency is missing");
            return false;
        }
        return true;
    }

}
