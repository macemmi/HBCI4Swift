//
//  HBCISepaDatedTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 15.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

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
    
}
