//
//  HBCIStatementsOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 31.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCIStatementsOrder: HBCIOrder {
    public let account:HBCIAccount;
    public var statements:Array<HBCIStatement>?

    public init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        super.init(name: "Statements", message: message);
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
            if account.iban == nil || account.bic == nil {
                logError("Account has no IBAN or BIC information");
                return false;
            }
            
            let values:Dictionary<String,AnyObject> = ["KTV.bic":account.bic!, "KTV.iban":account.iban!, "allaccounts":false];
            if !segment.setElementValues(values) {
                logError("Statements order values could not be set");
                return false;
            }
            
            // add to message
            msg.addOrder(self);
        } else {
            var values:Dictionary<String,AnyObject> = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode, "allaccounts":false];
            if account.subNumber != nil {
                values["KTV.subnumber"] = account.subNumber!
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
        if let seg = resultSegments.first {
            if let booked = seg.elementValueForPath("booked") as? NSData {
                if let mt94x = NSString(data: booked, encoding: NSISOLatin1StringEncoding) {
                    let parser = HBCIMT94xParser(mt94xString: mt94x);
                    self.statements = parser.parse();
                }
            }
        }
    }
    
}