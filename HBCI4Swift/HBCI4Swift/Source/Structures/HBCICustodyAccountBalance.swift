//
//  HBCICustodyAccountBalance.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 11.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//

import Foundation


public class HBCICustodyAccountBalance {
    public enum NumberType : Int16 {
        case pieces=0, values
    }
    
    public class FinancialInstrument {
        public class SubBalance {
            public let balance:NSDecimalNumber  // in pieces or value, according to numberType
            public let qualifier:String
            public let numberType:NumberType
            public let isAvailable:Bool;
            
            init(balance: NSDecimalNumber, qualifier:String, numberType:NumberType, isAvailable:Bool) {
                self.balance = balance;
                self.isAvailable = isAvailable;
                self.qualifier = qualifier;
                self.numberType = numberType;
            }
        }
        
        public let isin:String?
        public let wkn:String?
        public let name:String
        public var totalNumber:NSDecimalNumber!
        public var numberType:NumberType!
        public var currentPrice: HBCIValue?
        public var priceLocation:String?
        public var priceDate:Date?
        public var depotValue:HBCIValue?                // in depot currency
        public var accruedInterestValue:HBCIValue?
        public var depotCurrency:String?
        public var startPrice:HBCIValue?
        public var interestRate:NSDecimalNumber?
        public var balances = Array<SubBalance>();
        
        init?(isin:String?, wkn:String?, name:String) {
            if isin == nil && wkn == nil {
                return nil;
            }
            self.isin = isin;
            self.wkn = wkn;
            self.name = name;
        }
        
        func addBalance(balance:SubBalance) {
            balances.append(balance);
        }
        
    }
        
    
    public init(pageNumber:Int, date:Date, accountNumber:String, bankCode:String, exists:Bool) {
        self.pageNumber = pageNumber;
        self.accountNumber = accountNumber;
        self.bankCode = bankCode;
        self.date = date;
        self.exists = exists;
    }
    
    public let pageNumber:Int
    public let date:Date
    public let accountNumber:String
    public let bankCode:String
    public let exists:Bool;
    public var balanceNumber:Int?
    public var prepDate:Date?
    public var depotValue:HBCIValue!
    public var instruments = Array<FinancialInstrument>();
    
}
