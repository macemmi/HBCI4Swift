//
//  HBCISepaInfoOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 02.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCISepaInfoOrder : HBCIOrder {
    public let accounts:Array<HBCIAccount>;
    
    public init?(message: HBCICustomMessage, accounts:Array<HBCIAccount>) {
        self.accounts = accounts;
        super.init(name: "SepaInfo", message: message);
        if self.segment == nil {
            return nil;
        }
    }

    open func enqueue() ->Bool {
        
        var idx = 0;
        for account in accounts {
            // check if order is supported
            if !user.parameters.isOrderSupportedForAccount(self, number: account.number, subNumber: account.subNumber) {
                logInfo(self.name + " is not supported for account " + account.number);
                continue;
            }
            
            if idx == 0 {
                var values:Dictionary<String,Any> = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode];
                if account.subNumber != nil {
                    values["KTV.subnumber"] = account.subNumber!
                }
                if !segment.setElementValues(values) {
                    logInfo("Sepa Info Order values could not be set");
                    return false;
                }
            } else {
                if let element = self.segment.addElement("KTV") {
                    var values:Dictionary<String,Any> = ["number":account.number, "KIK.country":"280", "KIK.blz":account.bankCode];
                    if account.subNumber != nil {
                        values["subnumber"] = account.subNumber!
                    }
                    if !element.setElementValues(values) {
                        logInfo("Sepa Info Order values could not be set");
                        return false;
                    }
                }
            }
            idx += 1;
        }
        // add to message
        msg.addOrder(self);

        return true;
    }
    
    override open func updateResult(_ result:HBCIResultMessage) {
        super.updateResult(result);
        
        if let segment = resultSegments.first {
            let infos = segment.elementsForPath("info");
            for deg in infos {
                let number = deg.elementValueForPath("number") as? String;
                let subNumber = deg.elementValueForPath("subnumber") as? String;
                let bankCode = deg.elementValueForPath("KIK.blz") as? String;
                
                if number != nil && bankCode != nil {
                    for account in accounts {
                        if account.number == number && account.bankCode == bankCode {
                            if (account.subNumber == nil && subNumber == nil) || (account.subNumber == subNumber) {
                                // found
                                account.iban = deg.elementValueForPath("iban") as? String;
                                account.bic = deg.elementValueForPath("bic") as? String;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
    
}
