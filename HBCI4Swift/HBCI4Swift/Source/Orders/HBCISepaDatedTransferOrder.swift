//
//  HBCISepaDatedTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 15.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCISepaDatedTransferPar {
    public var minPreDays:Int
    public var maxPreDays:Int
}

public class HBCISepaDatedTransferOrder : HBCIAbstractSepaTransferOrder {

    public init?(message: HBCICustomMessage, transfer:HBCISepaTransfer) {
        super.init(name: "SepaDatedTransfer", message: message, transfer: transfer);
        if self.segment == nil {
            return nil;
        }
    }
    
    public override func enqueue() ->Bool {

        if transfer.date == nil {
            logError("SEPA Dated Transfer: date is missing");
            return false;
        }
        return super.enqueue();
    }
    
    public class func getParameters(user:HBCIUser) ->HBCISepaDatedTransferPar? {
        if let seg = user.parameters.parametersForJob("SepaDatedTransfer") {
            if let elem = seg.elementForPath("ParSepaDatedTransfer") {
                let minPreDays = elem.elementValueForPath("minpretime") as! Int;
                let maxPreDays = elem.elementValueForPath("maxpretime") as! Int;
                return HBCISepaDatedTransferPar(minPreDays: minPreDays, maxPreDays: maxPreDays);
            }
        }
        return nil;
    }
    
}
