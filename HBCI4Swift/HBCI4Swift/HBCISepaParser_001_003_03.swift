//
//  HBCISepaParser_001_003_03.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 22.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISepaParser_001_003_03 : HBCISepaParser, HBCISepaParserCredit {
    
    func transferForDocument(account:HBCIAccount, data:NSData) ->HBCISepaTransfer? {
        var error:NSError?
        var transfer = HBCISepaTransfer(account: account);
        
        if let document = NSXMLDocument(data: data, options: Int(NSXMLDocumentTidyXML), error: &error) {
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
                    if let elem = elems.first, valueString = elem.stringValue {
                        value = stringToNumber(valueString);
                        
                        if let node = elem.attributeForName("Ccy") {
                            currency = node.stringValue;
                        }
                    }
                    
                    if checkTransferData(iban, bic: bic, name: name, value: value, currency: currency) {
                        // create transfer item
                        var item = HBCISepaTransfer.Item(iban: iban!, bic: bic!, name: name!, value: value!, currency: currency!);
                        transfer.addItem(item, validate:false);
                    }
                }
            }
        } else {
            if let err = error {
                logError(err.description);
            } else {
                logError("Received Sepa document could not be parsed");
            }
            return nil;
        }
        return transfer;
    }
    
}