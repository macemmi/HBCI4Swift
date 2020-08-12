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
            logInfo("Value could not be extracted");
            logInfo(element.description);
            return nil;
        }
    }
    
    public init?(element: XMLElement) {
        let utility = HBCISepaUtility();
        
        guard let stringValue = element.stringValue else {
            return nil;
        }
        guard let value = utility.stringToNumber(stringValue) else {
            return nil;
        }
        self.value = value;
        guard let currency = element.attribute(forName: "Ccy")?.stringValue else {
            return nil;
        }
        self.currency = currency;
    }
}
