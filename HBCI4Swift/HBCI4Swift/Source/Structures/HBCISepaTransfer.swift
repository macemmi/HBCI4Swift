//
//  HBCISepaTransfer.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCISepaTransfer {
    open class Item {
        open var remoteIban:String
        open var remoteBic:String
        open var remoteName:String
        open var purpose:String?
        open var endToEndId:String?
        open var currency:String
        open var value:NSDecimalNumber
        
        public init(iban:String, bic:String, name:String, value:NSDecimalNumber, currency:String) {
            remoteIban = iban;
            remoteBic = bic;
            remoteName = name;
            self.value = value;
            self.currency = currency;
        }
    }
    
    open var account:HBCIAccount;
    open var batchbook:Bool = false;
    open var realtime:Bool = false;
    open var sepaId:String?
    open var paymentInfoId:String?
    open var date:Date?
    
    open var items = Array<HBCISepaTransfer.Item>();
    
    public init(account:HBCIAccount) {
        self.account = account;
    }
    
    open func addItem(_ item: HBCISepaTransfer.Item, validate:Bool = true) -> Bool {
        if validate {
            // validate item
            if item.remoteIban.count == 0 {
                logInfo("Remote IBAN not specified");
                return false;
            }
            if item.remoteBic.count == 0 {
                logInfo("Remote BIC not specified");
                return false;
            }
            if item.remoteName.count == 0 {
                logInfo("Remote Name not specified");
                return false;
            }
            if item.value.compare(NSDecimalNumber.zero) != ComparisonResult.orderedDescending {
                logInfo("Transfer value must be positive");
                return false;
            }            
        }
        
        self.items.append(item);
        return true;
    }
    
    open func validate() ->Bool {
        if items.count == 0 {
            logInfo("SEPA Transfer: no transfer items");
            return false;
        }
        
        if account.iban == nil {
            logInfo("SEPA Transfer: missing IBAN");
            return false;
        }
        
        if account.bic == nil {
            logInfo("SEPA Transfer: missing BIC");
            return false;
        }
        
        return true;
    }
    
    open func total() -> NSDecimalNumber {
        var total = NSDecimalNumber.zero;
        for item in self.items {
            total = total.adding(item.value);
        }
        return total;
    }

}
