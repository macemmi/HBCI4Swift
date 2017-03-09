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


open class HBCISepaInternalTransferOrder : HBCIAbstractSepaTransferOrder {
    
    public init?(message: HBCICustomMessage, transfer:HBCISepaTransfer) {
        super.init(name: "SepaInternalTransfer", message: message, transfer: transfer);
        if self.segment == nil {
            return nil;
        }
    }
    
    open override func enqueue() ->Bool {

        if transfer.date != nil {
            logError("SEPA Transfer: date is not allowed");
            return false;
        }
        
        return super.enqueue();
    }
    
    open class func getParameters(_ user:HBCIUser) ->HBCISepaInternalTransferPar? {
        guard let (elem, _) = self.getParameterElement(user, orderName: "SepaInternalTransfer") else {
            return nil;
        }
        var result = HBCISepaInternalTransferPar();
        result.purposeCodes = elem.elementValueForPath("PurposeCodes") as? String;
        result.supportedFormats = elem.elementValuesForPath("suppformats") as? Array<String>;
        return result;
    }

}
