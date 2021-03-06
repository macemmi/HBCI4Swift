//
//  HBCISepaStandingOrderDeleteOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 27.03.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCISepaStandingOrderDeletePar {
    public var minPreDays:Int;
    public var maxPreDays:Int;
    public var supportsTerminated:Bool;
    public var requiresOrderData:Bool;
}

open class HBCISepaStandingOrderDeleteOrder: HBCIOrder {
    var standingOrder:HBCIStandingOrder;
    var orderId:String?
    
    
    public init?(message: HBCICustomMessage, order:HBCIStandingOrder, orderId:String?) {
        self.orderId = orderId;
        self.standingOrder = order;
        super.init(name: "SepaStandingOrderDelete", message: message);
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
                    var values:Dictionary<String,Any> = ["My.iban":iban, "My.bic":bic, "sepapain":data, "sepadescr":gen.sepaFormat.urn, "details.firstdate":standingOrder.startDate,
                        "details.timeunit":standingOrder.cycleUnit == HBCIStandingOrderCycleUnit.monthly ? "M":"W", "details.turnus":standingOrder.cycle,
                        "details.execday":standingOrder.executionDay];
                    if let lastDate = standingOrder.lastDate {
                        values["details.lastdate"] = lastDate;
                    }
                    if let id = self.orderId {
                        values["orderid"] = id;
                    }
                    if self.segment.setElementValues(values) {
                        // add to dialog
                        return msg.addOrder(self);
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

    open class func getParameters(_ user:HBCIUser) ->HBCISepaStandingOrderDeletePar? {
        guard let (elem, seg) = self.getParameterElement(user, orderName: "SepaStandingOrderDelete") else {
            return nil;
        }
        guard let minPreDays = elem.elementValueForPath("minpretime") as? Int else {
            logInfo("SepaStandingOrderDeleteParameter: mandatory parameter minpretime missing");
            logInfo(seg.description);
            return nil;
        }
        guard let maxPreDays = elem.elementValueForPath("maxpretime") as? Int else {
            logInfo("SepaStandingOrderDeleteParameter: mandatory parameter maxpretime missing");
            logInfo(seg.description);
            return nil;
        }
        guard let supportsTerminated = elem.elementValueForPath("cantermdel") as? Bool else {
            logInfo("SepaStandingOrderDeleteParameter: mandatory parameter cantermdel missing");
            logInfo(seg.description);
            return nil;
        }
        guard let requiresOrderData = elem.elementValueForPath("orderdata_required") as? Bool else {
            logInfo("SepaStandingOrderDeleteParameter: mandatory parameter orderdata_required missing");
            logInfo(seg.description);
            return nil;
            
        }
        return HBCISepaStandingOrderDeletePar(minPreDays: minPreDays, maxPreDays: maxPreDays, supportsTerminated: supportsTerminated, requiresOrderData: requiresOrderData);
    }
    
}
