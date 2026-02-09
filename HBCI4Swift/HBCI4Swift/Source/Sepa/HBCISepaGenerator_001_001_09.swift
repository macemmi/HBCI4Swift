//
//  HBCISepaGenerator_001_001_09_GBIC_4.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.09.25.
//  Copyright © 2020 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISepaGenerator_001_001_09 : HBCISepaGenerator, HBCISepaGeneratorCredit {
    
    func documentForTransfer(_ transfer: HBCISepaTransfer) -> Data? {
        
        if transfer.items.count == 0 {
            logInfo("SEPA document error: not items");
            return nil;
        }
        
        // calculate total
        var total = NSDecimalNumber.zero;
        for item in transfer.items {
            total = total.adding(item.value);
        }
        
        // Group Header
        root.setStringValueForPath(transfer.sepaId ?? defaultMessageId(), path: "CstmrCdtTrfInitn.GrpHdr.MsgId");
        root.setStringValueForPath(sepaISODateString(), path: "CstmrCdtTrfInitn.GrpHdr.CreDtTm");
        root.setStringValueForPath(transfer.items.count.description, path: "CstmrCdtTrfInitn.GrpHdr.NbOfTxs");
        if let totalValue = numberToString(total) {
            root.setStringValueForPath(totalValue, path: "CstmrCdtTrfInitn.GrpHdr.CtrlSum");
        } else {
            logInfo("Value \(total) cannot be converted to sepa string");
            return nil;
        }
        root.setStringValueForPath(transfer.account.owner, path: "CstmrCdtTrfInitn.GrpHdr.InitgPty.Nm");

        // Payment Info
        root.setStringValueForPath(transfer.paymentInfoId ?? defaultMessageId() , path: "CstmrCdtTrfInitn.PmtInf.PmtInfId");
        root.setStringValueForPath("TRF", path: "CstmrCdtTrfInitn.PmtInf.PmtMtd");
        root.setStringValueForPath(transfer.batchbook ? "true":"false", path: "CstmrCdtTrfInitn.PmtInf.BtchBookg");
        root.setStringValueForPath(transfer.items.count.description, path: "CstmrCdtTrfInitn.PmtInf.NbOfTxs");
        if let totalValue = numberToString(total) {
            root.setStringValueForPath(totalValue, path: "CstmrCdtTrfInitn.PmtInf.CtrlSum");
        } else {
            logInfo("Value \(total) cannot be converted to sepa string");
            return nil;
        }
        
        root.setStringValueForPath("SEPA", path: "CstmrCdtTrfInitn.PmtInf.PmtTpInf.SvcLvl.Cd");
        
        // only for realtime
        if transfer.realtime {
            root.setStringValueForPath("INST", path: "CstmrCdtTrfInitn.PmtInf.PmtTpInf.LclInstrm.Cd");
        }
        
        root.setStringValueForPath(transfer.date == nil ? "1999-01-01":sepaDateString(transfer.date!), path: "CstmrCdtTrfInitn.PmtInf.ReqdExctnDt.Dt");
        root.setStringValueForPath(transfer.account.owner, path: "CstmrCdtTrfInitn.PmtInf.Dbtr.Nm");
        root.setStringValueForPath(transfer.account.iban!, path: "CstmrCdtTrfInitn.PmtInf.DbtrAcct.Id.IBAN");
        root.setStringValueForPath(transfer.account.bic!, path: "CstmrCdtTrfInitn.PmtInf.DbtrAgt.FinInstnId.BICFI");
        root.setStringValueForPath("SLEV", path: "CstmrCdtTrfInitn.PmtInf.ChrgBr");
        
        // Transaction Info
        for item in transfer.items {
            let parent = root.createPath("CstmrCdtTrfInitn.PmtInf");
            let elem = XMLElement(name: "CdtTrfTxInf");
            
            elem.setStringValueForPath(item.endToEndId ?? "NOTPROVIDED", path: "PmtId.EndToEndId");
            
            // amount
            if let amountValue = numberToString(item.value) {
                elem.setStringValueForPath(amountValue, path: "Amt.InstdAmt");
                
                let attr = XMLNode(kind: XMLNode.Kind.attribute);
                attr.name = "Ccy";
                attr.stringValue = item.currency;
                let amElem = elem.createPath("Amt.InstdAmt");
                amElem.addAttribute(attr);
            }
            elem.setStringValueForPath(item.remoteBic, path: "CdtrAgt.FinInstnId.BICFI");
            elem.setStringValueForPath(item.remoteName, path: "Cdtr.Nm");
            elem.setStringValueForPath(item.remoteIban, path: "CdtrAcct.Id.IBAN");
            if let purpose = item.purpose {
                elem.setStringValueForPath(purpose, path: "RmtInf.Ustrd");
            }
            parent.addChild(elem);
        }
        
        if !validate() {
            logInfo(document.description);
            return nil;
        }
        
        // create data from xml document
        return document.xmlData;
    }
    
}
