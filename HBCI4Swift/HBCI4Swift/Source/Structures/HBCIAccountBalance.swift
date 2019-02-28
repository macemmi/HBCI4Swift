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
    public let postingDate:Date;
    public let currency:String;
    
    public init(value:NSDecimalNumber, date:Date, currency:String) {
        self.value = value;
        self.postingDate = date;
        self.currency = currency;
    }
    
    public init?(element: HBCISyntaxElement) {
        if let value = HBCIValue(element: element), let date = element.elementValueForPath("date") as? Date {
            self.value = value.value;
            self.currency = value.currency;
            self.postingDate = date;
        } else {
            logInfo("Balance could not be extracted");
            logInfo(element.description);
            return nil;
        }
    }
}
