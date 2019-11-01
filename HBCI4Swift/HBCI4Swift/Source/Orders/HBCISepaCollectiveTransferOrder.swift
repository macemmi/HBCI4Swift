//
//  HBCISepaCollectiveTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 24.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCISepaCollectiveTransferPar {
    public var maxNum:Int;
    public var needsTotal:Bool;
    public var singleTransferAllowed:Bool;
}


open class HBCISepaCollectiveTransferOrder : HBCIAbstractSepaTransferOrder {
    
    public init?(message: HBCICustomMessage, transfer:HBCISepaTransfer) {
        super.init(name: "SepaCollectiveTransfer", message: message, transfer: transfer);
        if self.segment == nil {
            return nil;
        }
    }
    
    open override func enqueue() ->Bool {
        
        if transfer.date != nil {
            logInfo("SEPA Transfer: date is not allowed");
            return false;
        }
        return super.enqueue();
    }
    
    override func enrich(_ values: inout Dictionary<String,Any>) {
        if let parameters = HBCISepaCollectiveTransferOrder.getParameters(self.user) {
            if parameters.needsTotal {
                values["Total.value"] = self.transfer.total();
                values["Total.curr"] = self.transfer.items[0].currency;
            }            
        }
    }

    open class func getParameters(_ user:HBCIUser) ->HBCISepaCollectiveTransferPar? {
        guard let (elem, seg) = self.getParameterElement(user, orderName: "SepaCollectiveTransfer") else {
            logInfo("SepaCollectiveTransferParameters not found!");
            return nil;
        }
        guard let maxNum = elem.elementValueForPath("maxnum") as? Int else {
            logInfo("SepaCollectiveTransferParameters: mandatory parameter maxnum missing");
            logInfo(seg.description);
            return nil;
        }
        guard let needsTotal = elem.elementValueForPath("needtotal") as? Bool else {
            logInfo("SepaCollectiveTransferParameters: mandatory parameter needtotal missing");
            logInfo(seg.description);
            return nil;
        }
        guard let sta = elem.elementValueForPath("cansingletransfer") as? Bool else {
            logInfo("SepaCollectiveTransferParameters: mandatory parameter cansingletransfer missing");
            logInfo(seg.description);
            return nil;
        }
        return HBCISepaCollectiveTransferPar(maxNum: maxNum, needsTotal: needsTotal, singleTransferAllowed: sta);
    }


}
