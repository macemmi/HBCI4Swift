//
//  HBCISepaTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 26.09.25.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCISepaInstantTransferOrder : HBCIAbstractSepaTransferOrder {
    
    public init?(message: HBCICustomMessage, transfer:HBCISepaTransfer) {
        super.init(name: "SepaInstantTransfer", message: message, transfer: transfer);
        if self.segment == nil {
            return nil;
        }
    }
    
    open override func enqueue() ->Bool {

        if transfer.date != nil {
            logInfo("SEPA Instant Transfer: date is not allowed");
            return false;
        }
        
        if transfer.items.count > 1 {
            logInfo("SEPA Transfer: multiple transfers are not allowed");
            return false;
        }
        
        transfer.realtime = true;
        
        return super.enqueue();
    }
    
    override func enrich(_ values: inout Dictionary<String, Any>) {
        guard let (elem, _) = HBCIOrder.getParameterElement(user, orderName: "SepaInstantTransfer") else {
            return ;
        }
        if let canChange = elem.elementValueForPath("canChange") as? Bool {
            if canChange {
                values["allowChange"] = true;
            }
        }
    }

}
