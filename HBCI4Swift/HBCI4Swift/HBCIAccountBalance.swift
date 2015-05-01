//
//  HBCIAccountBalance.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCIAccountBalance {
    public let value:NSDecimalNumber;
    public let postingDate:NSDate;
    public let currency:String;
    
    init(value:NSDecimalNumber, date:NSDate, currency:String) {
        self.value = value;
        self.postingDate = date;
        self.currency = currency;
    }
    
    init?(element: HBCISyntaxElement) {
        if let cd = element.elementValueForPath("CreditDebit") as? String,
            value = element.elementValueForPath("BTG.value") as? NSDecimalNumber,
            curr = element.elementValueForPath("BTG.curr") as? String,
            date = element.elementValueForPath("date") as? NSDate {
                self.value = cd == "C" ? value:NSDecimalNumber.zero().decimalNumberBySubtracting(value);
                self.currency = curr;
                self.postingDate = date;
        } else {
            logError("Balance could not be extracted");
            logError(element.description);
            return nil;
        }
    }
}
