//
//  HBCISepaTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 14.03.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCISepaTransferOrder : HBCIOrder {
    public let transfer:HBCISepaTransfer;
    
    public init?(message: HBCICustomMessage, transfer:HBCISepaTransfer) {
        self.transfer = transfer;
        super.init(name: "SepaTransfer", message: message);
        if self.segment == nil {
            return nil;
        }
        
    }
    
    public func enqueue() ->Bool {
        if !transfer.validate() {
            return false;
        }
        
        if let seg = msg.segmentWithName("SepaTransfer") {
            // create SEPA data
            if let gen = HBCISepaGeneratorFactory.creditGenerator(self.user) {
                if let data = gen.documentForTransfer(transfer) {
                    if let iban = transfer.account.iban, bic = transfer.account.bic {
                        var values:Dictionary<String,AnyObject> = ["My.iban":iban, "My.bic":bic, "sepapain":data, "sepadescr":gen.getURN()];
                        if seg.setElementValues(values) {
                            self.segment = seg;
                            
                            // add to dialog
                            msg.addOrder(self);
                            return true;
                        } else {
                            logError("Could not set values for SepaTransfer");
                        }
                    } else {
                        if transfer.account.iban == nil {
                            logError("IBAN is missing for SEPA transfer");
                        }
                        if transfer.account.bic == nil {
                            logError("BIC is missing for SEPA transfer");
                        }
                    }
                }
            }
        }
        return false;
    }
    
}
