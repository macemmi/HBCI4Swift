//
//  HBCIBalanceOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 03.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCIBalanceOrder : HBCIOrder {
    public var iban:String?
    public var bic:String?
    public var accountNumber:String?
    public var accountSubNumber:String?
    public var bankCode:String?
    public var bookedBalance:HBCIAccountBalance?
    public var pendingBalance:HBCIAccountBalance?
    
    
    public init?(message: HBCICustomMessage) {
        super.init(name: "Balance", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    public func enqueue() ->Bool {
        if bankCode == nil || accountNumber == nil {
            logError(self.name + " order has no BLZ or Account information");
            return false;
        }
        
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: accountNumber!, subNumber: accountSubNumber) {
            logError(self.name + " is not supported for account " + accountNumber!);
            return false;
        }

        // check if SEPA version is supported (only globally for bank -
        // later we check if account supports this as well
        if segment.version >= 7 {
            // we have the SEPA version
            if iban == nil || bic == nil {
                logError("Balance order has no IBAN or BIC information");
                return false;
            }
            
            let values:Dictionary<String,AnyObject> = ["KTV.bic":bic!, "KTV.iban":iban!, "allaccounts":false];
            if !segment.setElementValues(values) {
                logError("Balance Order values could not be set");
                return false;
            }
            
            // add to message
            msg.addOrder(self);
        } else {
            // we have the old version
            if bankCode == nil || accountNumber == nil {
                logError("Balance order has no BLZ or Account information");
                return false;
            }
            var values:Dictionary<String,AnyObject> = ["KTV.number":accountNumber!, "KTV.KIK.country":"280", "KTV.KIK.blz":bankCode!, "allaccounts":false];
            if accountSubNumber != nil {
                values["KTV.subnumber"] = accountSubNumber!
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
