//
//  HBCISepaParser_001_003_03.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 22.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISepaParser_001_003_03 : HBCISepaParser, HBCISepaParserCredit {
    
    func transferForDocument(_ account:HBCIAccount, data:Data) ->HBCISepaTransfer? {
        let transfer = HBCISepaTransfer(account: account);
        
        do {
            let document = try XMLDocument(data: data, options: XMLNode.Options(rawValue: XMLNode.Options.RawValue(Int(XMLDocument.Options.documentTidyXML.rawValue))))
            if let root = document.rootElement() {
                
                // Group Header
                // do we need something from Group Header?
                
                // Payment Info
                transfer.paymentInfoId = root.stringValueForPath("CstmrCdtTrfInitn.PmtInf.PmtInfId");
                transfer.batchbook = root.stringValueForPath("CstmrCdtTrfInitn.PmtInf.BtchBookg") == "true";
                if let dateString = root.stringValueForPath("CstmrCdtTrfInitn.PmtInf.ReqdExctnDt") {
                    transfer.date = stringToDate(dateString);
                }
                
                //  we do not take over IBAN/BIC/Owner information for account (maybe we need a special ExternalSepaTransfer class)
                
                // Transaction Info
                let elements = root.elementsForPath("CstmrCdtTrfInitn.PmtInf.CdtTrfTxInf");
                for element in elements {
                    let iban = element.stringValueForPath("CdtrAcct.Id.IBAN");
                    let bic = element.stringValueForPath("CdtrAgt.FinInstnId.BIC");
                    let name = element.stringValueForPath("Cdtr.Nm");
                    var value:NSDecimalNumber?
                    var currency:String?
                    
                    let elems = element.elementsForPath("Amt.InstdAmt");
                    if let elem = elems.first, let valueString = elem.stringValue {
                        value = stringToNumber(valueString);
                        
                        if let node = elem.attribute(forName: "Ccy") {
                            currency = node.stringValue;
                        }
                    }
                    
                    if checkTransferData(iban, bic: bic, name: name, value: value, currency: currency) {
                        // create transfer item
                        let item = HBCISepaTransfer.Item(iban: iban!, bic: bic!, name: name!, value: value!, currency: currency!);
                        item.purpose = element.stringValueForPath("RmtInf.Ustrd");
                        if !transfer.addItem(item, validate:false) { return nil; }
                    }
                }
            }
        } catch let err as NSError {
            logDebug(err.description);
            return nil;
        }
        return transfer;
    }
    
}
