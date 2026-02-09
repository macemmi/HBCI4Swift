//
//  HBCISepaStandingOrderListOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCISepaStandingOrderListOrder : HBCIOrder {
    public let account:HBCIAccount;
    open var standingOrders = [HBCIStandingOrder]();
    open var offset:String?
    
    public init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        super.init(name: "SepaStandingOrderList", message: message);
        
        if self.segment == nil {
            return nil;
        }
    }
    
    open func enqueue() -> Bool {
        
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: account.number, subNumber: account.subNumber) {
            logInfo(self.name + " is not supported for account " + account.number);
            return false;
        }

        if let gen = HBCISepaGeneratorFactory.creditGenerator(self.user) {
            if let iban = account.iban, let bic = account.bic {
                var values:Dictionary<String,Any> = [
                    "My.iban":iban,
                    "My.bic":bic,
                    "My.number":removeLeadingZeroes(account.number),
                    "My.KIK.country":"280",
                    "My.KIK.blz":account.bankCode,
                    "sepadescr":gen.sepaFormat.urn];

                if account.subNumber != nil {
                    values["My.subnumber"] = account.subNumber!
                }

                if let sepaInfo = user.parameters.sepaInfoParameters() {
                    if !sepaInfo.allowsNationalAccounts {
                        values.removeValue(forKey: "My.number");
                        values.removeValue(forKey: "My.subnumber");
                        values.removeValue(forKey: "My.KIK.country");
                        values.removeValue(forKey: "My.KIK.blz");
                    }
                }
                
                if let ofs = offset {
                    values["offset"] = ofs;
                }
                if self.segment.setElementValues(values) {
                    // add to dialog
                    return msg.addOrder(self);
                } else {
                    logInfo("Could not set values for StandingOrderList");
                }
            } else {
                if account.iban == nil {
                    logInfo("IBAN is missing for StandingOrderList");
                }
                if account.bic == nil {
                    logInfo("BIC is missing for StandingOrderList");
                }
            }
        }
        return true;
    }
    
    override open func updateResult(_ result:HBCIResultMessage) {
        super.updateResult(result);
        
        // check whether result is incomplete
        self.offset = nil;
        for response in result.segmentResponses {
            if response.code == "3040" && response.parameters.count > 0 {
                self.offset = response.parameters[0];
            }
        }
        
        for segment in resultSegments {
            if let urn = segment.elementValueForPath("sepadescr") as? String, let pain = segment.elementValueForPath("sepapain") as? Data {
                if let parser = HBCISepaParserFactory.creditParser(urn) {
                    if let transfer = parser.transferForDocument(account, data: pain) {
                        // get standing order data
                        let lastDate = segment.elementValueForPath("details.lastdate") as? Date;
                        
                        if let unit = segment.elementValueForPath("details.timeunit") as? String,
                            let startDate = segment.elementValueForPath("details.firstdate") as? Date,
                            let day = segment.elementValueForPath("details.execday") as? Int,
                            let cycle = segment.elementValueForPath("details.turnus") as? Int,
                            let cycleUnit = HBCIStandingOrderCycleUnit(rawValue: unit) {
                                let stord = HBCIStandingOrder(transfer: transfer, startDate: startDate, cycle: cycle, day: day, cycleUnit: cycleUnit);
                                stord.lastDate = lastDate;
                                stord.orderId = segment.elementValueForPath("orderid") as? String;
                                standingOrders.append(stord);
                        } else {
                            logInfo("StandingOrder: could not parse data from segment: " + segment.description);
                        }
                    }
                }
            }
        }
    }
    


    
}
