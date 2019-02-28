//
//  HBCIStatementsOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 31.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCIStatementsOrder: HBCIOrder {
    open let account:HBCIAccount;
    open var statements:Array<HBCIStatement>?
    open var dateFrom:Date?
    open var dateTo:Date?
    
    var offset:String?
    var mt94xString:NSString?
    var isPartial = false;

    public init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        super.init(name: "Statements", message: message);
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
            
            values = ["KTV.bic":account.bic!, "KTV.iban":account.iban!, "allaccounts":false];
        } else {
            values = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode, "allaccounts":false];
            if account.subNumber != nil {
                values["KTV.subnumber"] = account.subNumber!
            }
        }
        
        if let date = dateFrom {
            values["startdate"] = date;
        }
        if let date = dateTo {
            values["enddate"] = date;
        }
        if let ofs = offset {
            values["offset"] = ofs;
        }
        if !segment.setElementValues(values) {
            logInfo("Statements Order values could not be set");
            return false;
        }
        
        // add to message
        msg.addOrder(self);
        
        return true;
    }
    
    func getOutstandingPart(_ offset:String) ->NSString? {
        do {
            if let msg = HBCICustomMessage.newInstance(msg.dialog) {
                if let order = HBCIStatementsOrder(message: msg, account: self.account) {
                    order.dateFrom = self.dateFrom;
                    order.dateTo = self.dateTo;
                    order.offset = offset;
                    order.isPartial = true;
                    if !order.enqueue() { return nil; }
                    
                    _ = try msg.send();
                    
                    return order.mt94xString;
                }
            }
        }
        catch {
            // we don't do anything in case of errors
        }
        return nil;
    }
    
    override open func updateResult(_ result: HBCIResultMessage) {
        super.updateResult(result);
        
        // check whether result is incomplete
        self.offset = nil;
        for response in result.segmentResponses {
            if response.code == "3040" && response.parameters.count > 0 {
                self.offset = response.parameters[0];
            }
        }
        
        // now parse statements
        if let seg = resultSegments.first {
            if let booked = seg.elementValueForPath("booked") as? Data {
                if var mt94x = NSString(data: booked, encoding: String.Encoding.isoLatin1.rawValue) {
                    
                    // check whether result is incomplete
                    for response in result.segmentResponses {
                        if response.code == "3040" && response.parameters.count > 0 {
                            if let part2 = getOutstandingPart(response.parameters[0]) {
                                mt94x = mt94x.appendingFormat(part2);
                            }
                        }
                    }
                    
                    // check if we are a part or the original order
                    if isPartial {
                        self.mt94xString = mt94x;
                    } else {
                        let parser = HBCIMT94xParser(mt94xString: mt94x);
                        do {
                            self.statements = try parser.parse();
                        }
                        catch {
                            // ignore errors here so that we can continue with next account
                        }
                    }
                }
            }
        }
    }
    
}
