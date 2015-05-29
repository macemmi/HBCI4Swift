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
        
        public init(iban:String, bic:String, name:String, value:NSDecimalNumber, currency:String) {
            remoteIban = iban;
            remoteBic = bic;
            remoteName = name;
            self.value = value;
            self.currency = currency;
        }
    }
    
    public var account:HBCIAccount;
    public var batchbook:Bool = false;
    public var sepaId:String?
    public var paymentInfoId:String?
    public var date:NSDate?
    
    var items = Array<HBCISepaTransfer.Item>();
    
    public init(account:HBCIAccount) {
        self.account = account;
    }
    
    public func addItem(item: HBCISepaTransfer.Item, validate:Bool = true) -> Bool {
        if validate {
            // validate item
            if count(item.remoteIban) == 0 {
                logError("Remote IBAN not specified");
                return false;
            }
            if count(item.remoteBic) == 0 {
                logError("Remote BIC not specified");
                return false;
            }
            if count(item.remoteName) == 0 {
                logError("Remote Name not specified");
                return false;
            }
            if item.value.compare(NSDecimalNumber.zero()) != NSComparisonResult.OrderedDescending {
                logError("Transfer value must be positive");
                return false;
            }            
        }
        
        self.items.append(item);
        return true;
    }
    
    public func validate() ->Bool {
        if items.count == 0 {
            logError("SEPA Transfer: no transfer items");
            return false;
        }
        
        if account.iban == nil {
            logError("SEPA Transfer: missing IBAN");
            return false;
        }
        
        if account.bic == nil {
            logError("SEPA Transfer: missing BIC");
        }
        
        return true;
    }

}