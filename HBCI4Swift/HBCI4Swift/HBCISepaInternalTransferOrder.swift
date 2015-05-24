//
//  HBCISepaInternalTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 15.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

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
}