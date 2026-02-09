//
//  HBCIAbstractSepaTransferOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 15.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCIAbstractSepaTransferOrder : HBCIOrder {
    public let transfer:HBCISepaTransfer;
    
    init?(name: String, message: HBCICustomMessage, transfer:HBCISepaTransfer) {
        self.transfer = transfer;
        super.init(name: name, message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    func enrich(_ values: inout Dictionary<String,Any>) {
    }
        
    func enqueue() ->Bool {
        if !transfer.validate() {
            return false;
        }
        
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: transfer.account.number, subNumber: transfer.account.subNumber) {
            logInfo(self.name + " is not supported for account " + transfer.account.number);
            return false;
        }
        
        // create SEPA data
        if let gen = HBCISepaGeneratorFactory.creditGenerator(self.user) {
            if let data = gen.documentForTransfer(transfer) {
                if let iban = transfer.account.iban, let bic = transfer.account.bic {
                    guard let urn_inst = gen.sepaFormat.urn_inst else {
                        logInfo("Sepa format not available");
                        return false;
                    }
                    var values:Dictionary<String,Any> = [
                        "My.iban":iban,
                        "My.bic":bic,
                        "My.number":transfer.account.number,
                        //"My.number":removeLeadingZeroes(transfer.account.number),
                        "My.KIK.country":"280",
                        "My.KIK.blz":transfer.account.bankCode,
                        "sepapain":data,
                        "sepadescr":urn_inst];
                    
                    if transfer.account.subNumber != nil {
                        values["My.subnumber"] = transfer.account.subNumber!
                    }

                    if let sepaInfo = user.parameters.sepaInfoParameters() {
                        if !sepaInfo.allowsNationalAccounts {
                            values.removeValue(forKey: "My.number");
                            values.removeValue(forKey: "My.subnumber");
                            values.removeValue(forKey: "My.KIK.country");
                            values.removeValue(forKey: "My.KIK.blz");
                        }
                    }

                    enrich(&values);
                    if self.segment.setElementValues(values) {
                        // add to dialog
                        return msg.addOrder(self);
                    } else {
                        logInfo("Could not set values for Sepa Transfer");
                    }
                } else {
                    if transfer.account.iban == nil {
                        logInfo("IBAN is missing for SEPA transfer");
                    }
                    if transfer.account.bic == nil {
                        logInfo("BIC is missing for SEPA transfer");
                    }
                }
            }
        }
        return false;
    }
    
    func updateRemoteNameForVoP(vopResult:HBCIVoPResult) -> Bool {
        
        // if any item has no match or close match, don't continue
        for item in vopResult.items {
            if item.status != HBCIVoPResultStatus.match && item.status != HBCIVoPResultStatus.closeMatch {
                return false;
            }
        }
        
        // we update the names with close match
        for item in vopResult.items {
            if item.status == HBCIVoPResultStatus.closeMatch {
                if let actualName = item.actualName {
                    for transferItem in self.transfer.items {
                        if transferItem.remoteName == item.givenName && transferItem.remoteIban == item.iban {
                            transferItem.remoteName = actualName;
                        }
                    }
                }
            }
        }
        
        guard let gen = HBCISepaGeneratorFactory.creditGenerator(self.user) else { return false }
        guard let data = gen.documentForTransfer(transfer) else { return false }
        
        if !self.msg.setElementValue(data, path: "sepapain") {
            return false;
        }
        return true;
    }
}
