//
//  HBCISepaStandingOrderNewOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCISepaStandingOrderNewPar {
    public var maxUsage:Int;
    public var minPreDays:Int;
    public var maxPreDays:Int;
    public var cycleMonths:String;
    public var daysPerMonth:String;
    public var cycleWeeks:String?
    public var daysPerWeek:String?
}

open class HBCISepaStandingOrderNewOrder : HBCIOrder {
    var standingOrder:HBCIStandingOrder;
    
    public init?(message: HBCICustomMessage, order:HBCIStandingOrder) {
        self.standingOrder = order;
        super.init(name: "SepaStandingOrderNew", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    open func enqueue() ->Bool {
        if !standingOrder.validate() {
            return false;
        }
        
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: standingOrder.account.number, subNumber: standingOrder.account.subNumber) {
            logDebug(self.name + " is not supported for account " + standingOrder.account.number);
            return false;
        }
        
        // create SEPA data
        if let gen = HBCISepaGeneratorFactory.creditGenerator(self.user) {
            if let data = gen.documentForTransfer(standingOrder) {
                if let iban = standingOrder.account.iban, let bic = standingOrder.account.bic {
                    var values:Dictionary<String,Any> = ["My.iban":iban,
                                                         "My.bic":bic,
                                                         "sepapain":data,
                                                         "sepadescr":gen.sepaFormat.urn,
                                                         "details.firstdate":standingOrder.startDate,
                                                         "details.timeunit":standingOrder.cycleUnit == HBCIStandingOrderCycleUnit.monthly ? "M":"W",
                                                         "details.turnus":standingOrder.cycle,
                                                         "details.execday":standingOrder.executionDay ];
                    if let lastDate = standingOrder.lastDate {
                        values["details.lastdate"] = lastDate;
                    }
                    if self.segment.setElementValues(values) {
                        // add to dialog
                        msg.addOrder(self);
                        return true;
                    } else {
                        logDebug("Could not set values for Sepa Standing Order");
                    }
                } else {
                    if standingOrder.account.iban == nil {
                        logDebug("IBAN is missing for SEPA Standing Order");
                    }
                    if standingOrder.account.bic == nil {
                        logDebug("BIC is missing for SEPA Standing Order");
                    }
                }
            }
        }
        return false;
    }
    
    override open func updateResult(_ result:HBCIResultMessage) {
        super.updateResult(result);
        
        for segment in resultSegments {
            standingOrder.orderId = segment.elementValueForPath("orderid") as? String;
        }
    }

    open class func getParameters(_ user:HBCIUser) ->HBCISepaStandingOrderNewPar? {
        guard let (elem, seg) = self.getParameterElement(user, orderName: "SepaStandingOrderNew") else {
            return nil;
        }
        guard let maxUsage = elem.elementValueForPath("maxusage") as? Int else {
            logDebug("SepaStandingOrderNewParameter: mandatory parameter maxusage missing");
            logDebug(seg.description);
            return nil;
        }
        guard let minPreDays = elem.elementValueForPath("minpretime") as? Int else {
            logDebug("SepaStandingOrderNewParameter: mandatory parameter minpretime missing");
            logDebug(seg.description);
            return nil;
        }
        guard let maxPreDays = elem.elementValueForPath("maxpretime") as? Int else {
            logDebug("SepaStandingOrderNewParameter: mandatory parameter maxpretime missing");
            logDebug(seg.description);
            return nil;
        }
        guard let cm = elem.elementValueForPath("turnusmonths") as? String else {
            logDebug("SepaStandingOrderNewParameter: mandatory parameter turnusmonths missing");
            logDebug(seg.description);
            return nil;
        }
        guard let dpm = elem.elementValueForPath("dayspermonth") as? String else {
            logDebug("SepaStandingOrderNewParameter: mandatory parameter dayspermonth missing");
            logDebug(seg.description);
            return nil;
        }
        let cw = elem.elementValueForPath("turnusweeks") as? String;
        let dpw = elem.elementValueForPath("daysperweek") as? String;
        return HBCISepaStandingOrderNewPar(maxUsage: maxUsage, minPreDays: minPreDays, maxPreDays: maxPreDays, cycleMonths: cm, daysPerMonth: dpm, cycleWeeks: cw, daysPerWeek: dpw);
    }

    
}
