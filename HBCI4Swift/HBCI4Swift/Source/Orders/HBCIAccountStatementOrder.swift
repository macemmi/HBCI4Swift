//
//  HBCIAccountStatementOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 22.03.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCIAccountStatementOrderPar {
    public var supportsNumber:Bool;
    public var needsReceipt:Bool;
    public var supportsLimit:Bool;
    public var formats:Array<HBCIAccountStatementFormat>;
}


public class HBCIAccountStatementOrder: HBCIOrder {
    public let account:HBCIAccount;
    public var number:Int?
    public var year:Int?
    public var format:HBCIAccountStatementFormat?
    
    // result
    public var statements = Array<HBCIAccountStatement>();

    public init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        super.init(name: "AccountStatement", message: message);
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
        
        var values = Dictionary<String,AnyObject>();
        
        // check if SEPA version is supported (only globally for bank -
        // later we check if account supports this as well
        if segment.version >= 7 {
            // we have the SEPA version
            if account.iban == nil || account.bic == nil {
                logError("Account has no IBAN or BIC information");
                return false;
            }
            
            values = ["KTV.bic":account.bic!, "KTV.iban":account.iban!, "allaccounts":false];
        } else {
            values = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode, "allaccounts":false];
            if account.subNumber != nil {
                values["KTV.subnumber"] = account.subNumber!
            }
        }
        
        if let idx = self.number {
            values["idx"] = idx;
        }
        if let year = self.year {
            values["year"] = year;
        }
        if let format = self.format {
            values["format"] = String(format.rawValue);
        }
        
        if !segment.setElementValues(values) {
            logError("AccountStatementOrder values could not be set");
            return false;
        }
        
        // add to message
        msg.addOrder(self);
        
        return true;
    }

    override func updateResult(result:HBCIResultMessage) {
        super.updateResult(result);
        
        for seg in resultSegments {
            if let statement = HBCIAccountStatement(segment: seg) {
                statements.append(statement);
            }
        }
    }
    
    public class func getParameters(user:HBCIUser) ->HBCIAccountStatementOrderPar? {
        if let seg = user.parameters.parametersForJob("AccountStatement") {
            if let elem = seg.elementForPath("ParAccountStatement") {
                guard let supportsNumber = elem.elementValueForPath("canindex") as? Bool else {
                    logError("AccountStatementParameters: mandatory parameter canindex missing");
                    logError(seg.description);
                    return nil;
                }
                guard let needsReceipt = elem.elementValueForPath("needreceipt") as? Bool else {
                    logError("AccountStatementParameters: mandatory parameter needreceipt missing");
                    logError(seg.description);
                    return nil;
                }
                guard let supportsLimit = elem.elementValueForPath("supportsLimit") as? Bool else {
                    logError("AccountStatementParameters: mandatory parameter supportsLimit missing");
                    logError(seg.description);
                    return nil;
                }
                var formats = Array<HBCIAccountStatementFormat>();
                if let fm = elem.elementValuesForPath("format") as? [String] {
                    for formatString in fm {
                        if let format = convertAccountStatementFormat(formatString) {
                            formats.append(format);
                        }
                    }
                }
                return HBCIAccountStatementOrderPar(supportsNumber: supportsNumber, needsReceipt: needsReceipt, supportsLimit: supportsLimit, formats: formats);
                
            }
        }
        return nil;
    }


}