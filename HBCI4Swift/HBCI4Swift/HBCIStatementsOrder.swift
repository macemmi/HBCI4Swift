//
//  HBCIStatementsOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 31.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCIStatementsOrder: HBCIOrder {
    public var
    iban:String?,
    bic:String?,
    accountNumber:String?,
    accountSubNumber:String?,
    bankCode:String?,
    statements:Array<HBCIStatement>?

    public init?(message: HBCICustomMessage) {
        super.init(name: "Statements", message: message);
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
                logError("Statements order has no IBAN or BIC information");
                return false;
            }
            
            let values:Dictionary<String,AnyObject> = ["KTV.bic":bic!, "KTV.iban":iban!, "allaccounts":false];
            if !segment.setElementValues(values) {
                logError("Statements order values could not be set");
                return false;
            }
            
            // add to message
            msg.addOrder(self);
        } else {
            var values:Dictionary<String,AnyObject> = ["KTV.number":accountNumber!, "KTV.KIK.country":"280", "KTV.KIK.blz":bankCode!, "allaccounts":false];
            if accountSubNumber != nil {
                values["KTV.subnumber"] = accountSubNumber!
            }
            if !segment.setElementValues(values) {
                logError("Statements Order values could not be set");
                return false;
            }
            
            // add to message
            msg.addOrder(self);
        }
        return true;
    }
    
    override func updateResult(result: HBCIResultMessage) {
        super.updateResult(result);
        
        // now parse statements
        if let seg = self.resultSegment {
            if let booked = seg.elementValueForPath("booked") as? NSData {
                if let mt94x = NSString(data: booked, encoding: NSISOLatin1StringEncoding) {
                    let parser = HBCIMT94xParser(mt94xString: mt94x);
                    self.statements = parser.parse();
                }
            }
        }
    }
    
}