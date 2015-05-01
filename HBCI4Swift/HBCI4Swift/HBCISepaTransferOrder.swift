//
//  HBCISepaTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 14.03.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCISepaTransferOrder : HBCIOrder {
    public var transfer:HBCISepaTransfer?
    
    public init?(message: HBCICustomMessage) {
        super.init(name: "SepaTransfer", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    public func enqueue() ->Bool {
        if let seg = msg.segmentWithName("SepaTransfer") {
            if let sepaTransfer = self.transfer {
                // create SEPA data
                if let gen = HBCISepaGeneratorFactory.creditGenerator(self.user) {
                    if let data = gen.documentForTransfer(sepaTransfer) {
                        
                        var values:Dictionary<String,AnyObject> = ["My.iban":sepaTransfer.sourceIban, "My.bic":sepaTransfer.sourceBic, "sepapain":data, "sepadescr":gen.getURN()];
                        
                        if seg.setElementValues(values) {
                            self.segment = seg;
                            
                            // add to dialog
                            msg.addOrder(self);
                            return true;
                        } else {
                            logError("Could not set values for SepaTransfer");
                        }
                    } 
                }
            } else {
                logError("HBCISepaTransfer: no transfer data");
            }
        }
        return false;
    }
    
}
