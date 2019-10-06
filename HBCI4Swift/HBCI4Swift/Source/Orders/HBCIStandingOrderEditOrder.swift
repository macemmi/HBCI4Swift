//
//  HBCIStandingOrderEditOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 29.03.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCISepaStandingOrderEditPar {
    public var maxTermChanges:Int;              // maximum number of terminated changes
    public var minPreDays:Int;                  // minimum setup time
    public var maxPreDays:Int;                  // maximum setup time
    public var creditorAccountChangeable:Bool;  // creditor account changeable?
    public var creditorChangeable:Bool;         // creditor changeable ?
    public var amountChangeable:Bool;           // amount changeable?
    public var usageChangeable:Bool;            // remittance information changeable?
    public var firstExecChangeable:Bool;        // first execution date changeable?
    public var timeunitChangeable:Bool;         // time unit changeable?
    public var cycleChangeable:Bool;            // execution cycle changeable?
    public var execDayChangeable:Bool;          // execution day changeable?
    public var lastExecChangeable:Bool;         // last execution date changeable?
    public var cycleMonths:String;              // allowed number of month for cycles (e.g. every 3 months)
    public var daysPerMonth:String;             // allowed days in month
    public var cycleWeeks:String?               // allowed number of weeks for cycles (e.g. every 2 weeks)
    public var daysPerWeek:String?              // allowed days in week
}


open class HBCISepaStandingOrderEditOrder: HBCIAbstractStandingOrderOrder {
    var orderId:String?
    
    
    public init?(message: HBCICustomMessage, order:HBCIStandingOrder, orderId:String?) {
        self.orderId = orderId;
        super.init(name: "SepaStandingOrderEdit", message: message, order: order);
        if self.segment == nil {
            return nil;
        }
    }
    
    open override func enqueue() -> Bool {
        if super.enqueue() {
            if let id = self.orderId {
                if(!self.segment.setElementValue(id, path: "orderid")) { return false };
            }
            return msg.addOrder(self);
        }
        return false;
    }
    
    override open func updateResult(_ result:HBCIResultMessage) {
        super.updateResult(result);
        
        for segment in resultSegments {
            standingOrder.orderId = segment.elementValueForPath("orderid") as? String;
        }
    }

    
    open class func getParameters(_ user:HBCIUser) ->HBCISepaStandingOrderEditPar? {
        guard let (elem, seg) = self.getParameterElement(user, orderName: "SepaStandingOrderEdit") else {
            return nil;
        }
        guard let minPreDays = elem.elementValueForPath("minpretime") as? Int else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter minpretime missing");
            logInfo(seg.description);
            return nil;
        }
        guard let maxPreDays = elem.elementValueForPath("maxpretime") as? Int else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter maxpretime missing");
            logInfo(seg.description);
            return nil;
        }
        guard let maxTermChanges = elem.elementValueForPath("numtermchanges") as? Int else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter numtermchanges missing");
            logInfo(seg.description);
            return nil;
        }
        guard let credAcct_c = elem.elementValueForPath("recktoeditable") as? Bool else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter recktoeditable missing");
            logInfo(seg.description);
            return nil;
        }
        guard let cred_c = elem.elementValueForPath("recnameeditable") as? Bool else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter recnameeditable missing");
            logInfo(seg.description);
            return nil;
        }
        guard let value_c = elem.elementValueForPath("valueeditable") as? Bool else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter valueeditable missing");
            logInfo(seg.description);
            return nil;
        }
        guard let usage_c = elem.elementValueForPath("usageeditable") as? Bool else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter usageeditable missing");
            logInfo(seg.description);
            return nil;
        }
        guard let firstExec_c = elem.elementValueForPath("firstexeceditable") as? Bool else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter firstexeceditable missing");
            logInfo(seg.description);
            return nil;
        }
        guard let timeUnit_c = elem.elementValueForPath("timeuniteditable") as? Bool else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter timeuniteditable missing");
            logInfo(seg.description);
            return nil;
        }
        guard let cycle_c = elem.elementValueForPath("turnuseditable") as? Bool else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter turnuseditable missing");
            logInfo(seg.description);
            return nil;
        }
        guard let execDay_c = elem.elementValueForPath("execdayeditable") as? Bool else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter execdayeditable missing");
            logInfo(seg.description);
            return nil;
        }
        guard let lastExec_c = elem.elementValueForPath("lastexeceditable") as? Bool else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter lastexeceditable missing");
            logInfo(seg.description);
            return nil;
        }
        guard let cycleMonths = elem.elementValueForPath("turnusmonths") as? String else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter turnusmonths missing");
            logInfo(seg.description);
            return nil;
        }
        guard let daysPerMonth = elem.elementValueForPath("dayspermonth") as? String else {
            logInfo("SepaStandingOrderEditParameter: mandatory parameter dayspermonth missing");
            logInfo(seg.description);
            return nil;
        }
        let cycleWeeks = elem.elementValueForPath("turnusweeks") as? String;
        let daysPerWeek = elem.elementValueForPath("daysperweek") as? String;
        
        return HBCISepaStandingOrderEditPar(maxTermChanges: maxTermChanges, minPreDays: minPreDays, maxPreDays: maxPreDays, creditorAccountChangeable: credAcct_c, creditorChangeable: cred_c, amountChangeable: value_c, usageChangeable: usage_c, firstExecChangeable: firstExec_c, timeunitChangeable: timeUnit_c, cycleChangeable: cycle_c, execDayChangeable: execDay_c, lastExecChangeable: lastExec_c, cycleMonths: cycleMonths, daysPerMonth: daysPerMonth, cycleWeeks: cycleWeeks, daysPerWeek: daysPerWeek);
    }
    
    
}
