//
//  HBCIAccountBalance.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public enum AccountBalanceType : String {
    case ClosingBooked = "CLBD", ClosingAvailable = "CLAV", ForwardAvailable = "FWAV", InterimBooked = "ITBD", PreviouslyClosedBooked = "PRCD", OpeningBooked = "OPBD", InterimOpen = "ITOP", Unknown = ""
}

public struct HBCIAccountBalance {
    public let value:NSDecimalNumber;
    public let postingDate:Date;
    public let currency:String;
    public let type:AccountBalanceType;
    
    public init(value:NSDecimalNumber, date:Date, currency:String, type:AccountBalanceType) {
        self.value = value;
        self.postingDate = date;
        self.currency = currency;
        self.type = type;
    }
    
    public init?(element: HBCISyntaxElement) {
        if let value = HBCIValue(element: element), let date = element.elementValueForPath("date") as? Date {
            self.value = value.value;
            self.currency = value.currency;
            self.postingDate = date;
            self.type = AccountBalanceType.Unknown;
        } else {
            logInfo("Balance could not be extracted");
            logInfo(element.description);
            return nil;
        }
    }
    
    public init?(element:XMLElement) {
        let utility = HBCISepaUtility();
        
        let amtElements = element.elements(forName: "Amt");
        guard let amtElement = amtElements.first  else {
            return nil;
        }
        guard let hbciValue = HBCIValue(element: amtElement) else {
            return nil;
        }
        
        guard let dateString = element.stringValueForPath("Dt.Dt") else {
            return nil;
        }
        guard let postingDate = utility.stringToDate(dateString) else {
            return nil;
        }
        self.postingDate = postingDate;
        
        guard let balanceType = element.stringValueForPath("Tp.CdOrPrtry.Cd") else {
            return nil;
        }
        
        if let balanceSubType = element.stringValueForPath("Tp.SubTp.Cd") {
            if balanceSubType == "CLBD" {
                self.type = .InterimBooked
            } else {
                self.type = .InterimOpen
            }
        } else {
            self.type = AccountBalanceType(rawValue: balanceType)!
        }
        
        guard let dc = element.stringValueForPath("CdtDbtInd") else {
            return nil;
        }
        if dc == "DBIT" {
            self.value = NSDecimalNumber.zero.subtracting(hbciValue.value);
        } else {
            self.value = hbciValue.value;
        }
        self.currency = hbciValue.currency;
        
    }
}
