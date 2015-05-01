//
//  HBCISepaTransfer.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCISepaTransfer {
    public class Item {
        public var remoteIban:String
        public var remoteBic:String
        public var remoteName:String
        public var purpose:String?
        public var endToEndId:String?
        public var currency:String
        public var value:NSDecimalNumber
        
        init(iban:String, bic:String, name:String, value:NSDecimalNumber, currency:String) {
            remoteIban = iban;
            remoteBic = bic;
            remoteName = name;
            self.value = value;
            self.currency = currency;
        }
    }
    
    public var sourceIban:String
    public var sourceBic:String
    public var sourceName:String
    public var batchbook:Bool = false;
    public var sepaId:String?
    public var paymentInfoId:String?
    public var date:NSDate?
    
    public var items = Array<HBCISepaTransfer.Item>();
    
    public init(iban:String, bic:String, name:String) {
        sourceIban = iban;
        sourceBic = bic;
        sourceName = name;
    }
    
    public func validate() ->Bool {
        if items.count == 0 {
            logError("SEPA Transfer: no transfer items");
            return false;
        }
        
        return true;
    }

}