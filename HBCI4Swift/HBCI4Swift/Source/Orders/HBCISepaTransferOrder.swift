//
//  HBCISepaTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 14.03.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCISepaTransferOrder : HBCIAbstractSepaTransferOrder {
    
    public init?(message: HBCICustomMessage, transfer:HBCISepaTransfer) {
        super.init(name: "SepaTransfer", message: message, transfer: transfer);
        if self.segment == nil {
            return nil;
        }
    }
    
    open override func enqueue() ->Bool {

        if transfer.date != nil {
            logDebug("SEPA Transfer: date is not allowed");
            return false;
        }
        
        if transfer.items.count > 1 {
            logDebug("SEPA Transfer: multiple transfers are not allowed");
            return false;
        }
        
        return super.enqueue();
    }

}
