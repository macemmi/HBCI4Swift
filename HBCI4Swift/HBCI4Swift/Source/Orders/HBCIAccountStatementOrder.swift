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


open class HBCIAccountStatementOrder: HBCIOrder {
    public let account:HBCIAccount;
    open var number:Int?
    open var year:Int?
    open var format:HBCIAccountStatementFormat?
    
    // result
    open var statements = Array<HBCIAccountStatement>();

    public init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        super.init(name: "AccountStatement", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    open func enqueue() ->Bool {
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: account.number, subNumber: account.subNumber) {
            logInfo(self.name + " is not supported for account " + account.number);
            return false;
        }
        
        var values = Dictionary<String,Any>();
        
        // check if SEPA version is supported (only globally for bank -
        // later we check if account supports this as well
        if segment.version >= 7 {
            // we have the SEPA version
            if account.iban == nil || account.bic == nil {
                logInfo("Account has no IBAN or BIC information");
                return false;
            }
            
            values = ["KTV.bic":account.bic!, "KTV.iban":account.iban!];
        } else {
            values = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode];
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
            logInfo("AccountStatementOrder values could not be set");
            return false;
        }
        
        // add to message
        msg.addOrder(self);
        
        return true;
    }

    override open func updateResult(_ result:HBCIResultMessage) {
        super.updateResult(result);
        
        for seg in resultSegments {
            if let statement = HBCIAccountStatement(segment: seg) {
                statements.append(statement);
            }
        }
    }
    
    open class func getParameters(_ user:HBCIUser) ->HBCIAccountStatementOrderPar? {
        guard let (elem, seg) = self.getParameterElement(user, orderName: "AccountStatement") else {
            return nil;
        }
        guard let supportsNumber = elem.elementValueForPath("canindex") as? Bool else {
            logInfo("AccountStatementParameters: mandatory parameter canindex missing");
            logInfo(seg.description);
            return nil;
        }
        guard let needsReceipt = elem.elementValueForPath("needreceipt") as? Bool else {
            logInfo("AccountStatementParameters: mandatory parameter needreceipt missing");
            logInfo(seg.description);
            return nil;
        }
        guard let supportsLimit = elem.elementValueForPath("canmaxentries") as? Bool else {
            logInfo("AccountStatementParameters: mandatory parameter supportsLimit missing");
            logInfo(seg.description);
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
