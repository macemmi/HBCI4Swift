//
//  HBCIBalanceOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 03.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCIBalanceOrder : HBCIOrder {
    open let account:HBCIAccount;
    open var bookedBalance:HBCIAccountBalance?
    open var pendingBalance:HBCIAccountBalance?
    
    
    public init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        super.init(name: "AccountBalance", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    open func enqueue() ->Bool {
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: account.number, subNumber: account.subNumber) {
            logDebug(self.name + " is not supported for account " + account.number);
            return false;
        }

        // check if SEPA version is supported (only globally for bank -
        // later we check if account supports this as well
        if segment.version >= 7 {
            // we have the SEPA version
            if account.iban == nil {
                logDebug("Balance order has no IBAN");
                return false;
            }
            if account.bic == nil {
                logDebug("Balance order has no BIC");
                return false;
            }
            
            let values:Dictionary<String,Any> = ["KTV.bic":account.bic!, "KTV.iban":account.iban!, "allaccounts":false];
            if !segment.setElementValues(values) {
                logDebug("Balance Order values could not be set");
                return false;
            }
            
            // add to message
            msg.addOrder(self);
        } else {
            // we have the old version
            var values:Dictionary<String,Any> = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode, "allaccounts":false];
            if account.subNumber != nil {
                values["KTV.subnumber"] = account.subNumber!
            }
            if !segment.setElementValues(values) {
                logDebug("Balance Order values could not be set");
                return false;
            }

            // add to message
            msg.addOrder(self);
        }
        return true;
    }
    
    override open func updateResult(_ result:HBCIResultMessage) {
        super.updateResult(result);
        
        if let retSeg = resultSegments.first {
            if let deg = retSeg.elementForPath("booked") as? HBCIDataElementGroup {
                self.bookedBalance = HBCIAccountBalance(element: deg);
                if self.bookedBalance == nil {
                    return;
                }
            }
            if let deg = retSeg.elementValueForPath("pending") as? HBCIDataElementGroup {
                self.pendingBalance = HBCIAccountBalance(element: deg);
            }
        }
    }


}
