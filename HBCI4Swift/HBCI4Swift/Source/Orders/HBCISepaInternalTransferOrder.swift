//
//  HBCISepaInternalTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 15.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCISepaInternalTransferPar {
    public var purposeCodes:String?
    public var supportedFormats:Array<String>?
}


public class HBCISepaInternalTransferOrder : HBCIAbstractSepaTransferOrder {
    
    public init?(message: HBCICustomMessage, transfer:HBCISepaTransfer) {
        super.init(name: "SepaInternalTransfer", message: message, transfer: transfer);
        if self.segment == nil {
            return nil;
        }
    }
    
    public override func enqueue() ->Bool {

        if transfer.date != nil {
            logError("SEPA Transfer: date is not allowed");
            return false;
        }
        
        return super.enqueue();
    }
    
    public class func getParameters(user:HBCIUser) ->HBCISepaInternalTransferPar? {
        if let seg = user.parameters.parametersForJob("SepaInternalTransfer") {
            if let elem = seg.elementForPath("ParSepaInternalTransfer") {
                var result = HBCISepaInternalTransferPar();
                result.purposeCodes = elem.elementValueForPath("PurposeCodes") as? String;
                result.supportedFormats = elem.elementValuesForPath("suppformats") as? Array<String>;
                return result;
            }
        }
        return nil;
    }

}
