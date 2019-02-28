//
//  HBCISepaDatedTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 15.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCISepaDatedTransferPar {
    public var minPreDays:Int;
    public var maxPreDays:Int;
}

open class HBCISepaDatedTransferOrder : HBCIAbstractSepaTransferOrder {

    public init?(message: HBCICustomMessage, transfer:HBCISepaTransfer) {
        super.init(name: "SepaDatedTransfer", message: message, transfer: transfer);
        if self.segment == nil {
            return nil;
        }
    }
    
    open override func enqueue() ->Bool {

        if transfer.date == nil {
            logInfo("SEPA Dated Transfer: date is missing");
            return false;
        }
        return super.enqueue();
    }
    
    open class func getParameters(_ user:HBCIUser) ->HBCISepaDatedTransferPar? {
        guard let (elem, seg) = self.getParameterElement(user, orderName: "SepaDatedTransfer") else {
            return nil;
        }
        guard let minPreDays = elem.elementValueForPath("minpretime") as? Int else {
            logInfo("SepaDatedTransferParameters: mandatory parameter minpretime missing");
            logInfo(seg.description);
            return nil;
        }
        guard let maxPreDays = elem.elementValueForPath("maxpretime") as? Int else {
            logInfo("SepaDatedTransferParameters: mandatory parameter maxpretime missing");
            logInfo(seg.description);
            return nil;
        }
        return HBCISepaDatedTransferPar(minPreDays: minPreDays, maxPreDays: maxPreDays);
    }
    
}
