//
//  HBCIValue.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 21.04.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCIValue {
    public let value:NSDecimalNumber;
    public let currency:String;
    
    public init(value:NSDecimalNumber, date:Date, currency:String) {
        self.value = value;
        self.currency = currency;
    }
    
    public init?(element: HBCISyntaxElement) {
        if let cd = element.elementValueForPath("debitcredit") as? String,
            let value = element.elementValueForPath("value") as? NSDecimalNumber,
            let curr = element.elementValueForPath("curr") as? String {
                self.value = cd == "C" ? value:NSDecimalNumber.zero.subtracting(value);
                self.currency = curr;
        } else {
            logDebug("Value could not be extracted");
            logDebug(element.description);
            return nil;
        }
    }
}
