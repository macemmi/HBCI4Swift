//
//  HBCIAbstractSepaTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 15.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCIAbstractSepaTransferOrder : HBCIOrder {
    open let transfer:HBCISepaTransfer;
    
    init?(name: String, message: HBCICustomMessage, transfer:HBCISepaTransfer) {
        self.transfer = transfer;
        super.init(name: name, message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    func enqueue() ->Bool {
        if !transfer.validate() {
            return false;
        }
        
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: transfer.account.number, subNumber: transfer.account.subNumber) {
            logDebug(self.name + " is not supported for account " + transfer.account.number);
            return false;
        }
        
        // create SEPA data
        if let gen = HBCISepaGeneratorFactory.creditGenerator(self.user) {
            if let data = gen.documentForTransfer(transfer) {
                if let iban = transfer.account.iban, let bic = transfer.account.bic {
                    let values:Dictionary<String,Any> = [
                        "My.iban":iban,
                        "My.bic":bic,
                        "sepapain":data,
                        "sepadescr":gen.sepaFormat.urn];
                    if self.segment.setElementValues(values) {
                        // add to dialog
                        msg.addOrder(self);
                        return true;
                    } else {
                        logDebug("Could not set values for Sepa Transfer");
                    }
                } else {
                    if transfer.account.iban == nil {
                        logDebug("IBAN is missing for SEPA transfer");
                    }
                    if transfer.account.bic == nil {
                        logDebug("BIC is missing for SEPA transfer");
                    }
                }
            }
        }
        return false;
    }
}
