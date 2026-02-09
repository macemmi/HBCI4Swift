//
//  HBCIAbstractStandingOrderOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 29.03.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCIAbstractStandingOrderOrder: HBCIOrder {
    var standingOrder:HBCIStandingOrder;
    
    init?(name:String, message:HBCICustomMessage, order:HBCIStandingOrder) {
        self.standingOrder = order;
        super.init(name: name, message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    open func enqueue() ->Bool {
        // todo: validation only needed if transfer data is mandatory
        if !standingOrder.validate() {
            return false;
        }
        
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: standingOrder.account.number, subNumber: standingOrder.account.subNumber) {
            logInfo(self.name + " is not supported for account " + standingOrder.account.number);
            return false;
        }
        
        // create SEPA data
        if let gen = HBCISepaGeneratorFactory.creditGenerator(self.user) {
            if let data = gen.documentForTransfer(standingOrder) {
                if let iban = standingOrder.account.iban, let bic = standingOrder.account.bic {
                    guard let urn_inst = gen.sepaFormat.urn_inst else {
                        logInfo("Sepa format not available");
                        return false;
                    }

                    var values:Dictionary<String,Any> = [
                        "My.iban":iban,
                        "My.bic":bic,
                        "My.number":removeLeadingZeroes(standingOrder.account.number),
                        "My.KIK.country":"280",
                        "My.KIK.blz":standingOrder.account.bankCode,
                        "sepapain":data,
                        "sepadescr":urn_inst,
                        "details.firstdate":standingOrder.startDate,
                        "details.timeunit":(standingOrder.cycleUnit == HBCIStandingOrderCycleUnit.monthly ? "M":"W"),
                        "details.turnus":standingOrder.cycle,
                        "details.execday":standingOrder.executionDay
                    ];
                    
                    if standingOrder.account.subNumber != nil {
                        values["My.subnumber"] = standingOrder.account.subNumber!
                    }
                    
                    if let sepaInfo = user.parameters.sepaInfoParameters() {
                        if !sepaInfo.allowsNationalAccounts {
                            values.removeValue(forKey: "My.number");
                            values.removeValue(forKey: "My.subnumber");
                            values.removeValue(forKey: "My.KIK.country");
                            values.removeValue(forKey: "My.KIK.blz");
                        }
                    }

                    if let lastDate = standingOrder.lastDate {
                        values["details.lastdate"] = lastDate;
                    }
                    
                    if self.segment.setElementValues(values) {
                        return true;
                    } else {
                        logInfo("Could not set values for Sepa Standing Order");
                    }
                } else {
                    if standingOrder.account.iban == nil {
                        logInfo("IBAN is missing for SEPA Standing Order");
                    }
                    if standingOrder.account.bic == nil {
                        logInfo("BIC is missing for SEPA Standing Order");
                    }
                }
            }
        }
        return false;
    }



}
