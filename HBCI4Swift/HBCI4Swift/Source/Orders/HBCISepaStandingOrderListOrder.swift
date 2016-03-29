//
//  HBCISepaStandingOrderListOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCISepaStandingOrderListOrder : HBCIOrder {
    public let account:HBCIAccount;
    public var standingOrders = [HBCIStandingOrder]();
    public var offset:String?
    
    public init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        super.init(name: "SepaStandingOrderList", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    public func enqueue() -> Bool {
        
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: account.number, subNumber: account.subNumber) {
            logError(self.name + " is not supported for account " + account.number);
            return false;
        }

        if let gen = HBCISepaGeneratorFactory.creditGenerator(self.user) {
            if let iban = account.iban, bic = account.bic {
                var values:Dictionary<String,AnyObject> = ["My.iban":iban, "My.bic":bic, "sepadescr":gen.sepaFormat.urn];
                if let ofs = offset {
                    values["offset"] = ofs;
                }
                if self.segment.setElementValues(values) {
                    // add to dialog
                    msg.addOrder(self);
                    return true;
                } else {
                    logError("Could not set values for StandingOrderList");
                }
            } else {
                if account.iban == nil {
                    logError("IBAN is missing for StandingOrderList");
                }
                if account.bic == nil {
                    logError("BIC is missing for StandingOrderList");
                }
            }
        }
        return true;
    }
    
    override func updateResult(result:HBCIResultMessage) {
        super.updateResult(result);
        
        // check whether result is incomplete
        self.offset = nil;
        for response in result.segmentResponses {
            if response.code == "3040" && response.parameters.count > 0 {
                self.offset = response.parameters[0];
            }
        }
        
        for segment in resultSegments {
            if let urn = segment.elementValueForPath("sepadescr") as? String, pain = segment.elementValueForPath("sepapain") as? NSData {
                if let parser = HBCISepaParserFactory.creditParser(urn) {
                    if let transfer = parser.transferForDocument(account, data: pain) {
                        // get standing order data
                        let lastDate = segment.elementValueForPath("details.lastdate") as? NSDate;
                        
                        if let unit = segment.elementValueForPath("details.timeunit") as? String,
                            startDate = segment.elementValueForPath("details.firstdate") as? NSDate,
                            day = segment.elementValueForPath("details.execday") as? Int,
                            cycle = segment.elementValueForPath("details.turnus") as? Int,
                            cycleUnit = HBCIStandingOrderCycleUnit(rawValue: unit) {
                                let stord = HBCIStandingOrder(transfer: transfer, startDate: startDate, cycle: cycle, day: day, cycleUnit: cycleUnit);
                                stord.lastDate = lastDate;
                                stord.orderId = segment.elementValueForPath("orderid") as? String;
                                standingOrders.append(stord);
                        } else {
                            logError("StandingOrder: could not parse data from segment: " + segment.description);
                        }
                    }
                }
            }
        }
    }
    


    
}
