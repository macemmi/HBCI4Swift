//
//  HBCIBalanceOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 03.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCIBalanceOrder : HBCIOrder {
    public let account:HBCIAccount;
    public var bookedBalance:HBCIAccountBalance?
    public var pendingBalance:HBCIAccountBalance?
    
    
    public init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        super.init(name: "Balance", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    public func enqueue() ->Bool {
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: account.number, subNumber: account.subNumber) {
            logError(self.name + " is not supported for account " + account.number);
            return false;
        }

        // check if SEPA version is supported (only globally for bank -
        // later we check if account supports this as well
        if segment.version >= 7 {
            // we have the SEPA version
            if account.iban == nil {
                logError("Balance order has no IBAN");
                return false;
            }
            if account.bic == nil {
                logError("Balance order has no BIC");
                return false;
            }
            
            let values:Dictionary<String,AnyObject> = ["KTV.bic":account.bic!, "KTV.iban":account.iban!, "allaccounts":false];
            if !segment.setElementValues(values) {
                logError("Balance Order values could not be set");
                return false;
            }
            
            // add to message
            msg.addOrder(self);
        } else {
            // we have the old version
            var values:Dictionary<String,AnyObject> = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode, "allaccounts":false];
            if account.subNumber != nil {
                values["KTV.subnumber"] = account.subNumber!
            }
            if !segment.setElementValues(values) {
                logError("Balance Order values could not be set");
                return false;
            }

            // add to message
            msg.addOrder(self);
        }
        return true;
    }
    
    override func updateResult(result:HBCIResultMessage) {
        super.updateResult(result);
        
        if let retSeg = self.resultSegment {
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
