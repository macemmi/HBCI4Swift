//
//  HBCISepaGenerator_001_003_03.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISepaGenerator_001_003_03 : HBCISepaGenerator, HBCISepaGeneratorCredit {
    
    func documentForTransfer(transfer: HBCISepaTransfer) -> NSData? {
        
        if transfer.items.count == 0 {
            logError("SEPA document error: not items");
            return nil;
        }
        
        // calculate total
        var total = NSDecimalNumber.zero();
        for item in transfer.items {
            total = total.decimalNumberByAdding(item.value);
        }
        
        // Group Header
        root.setStringValueForPath(transfer.sepaId ?? defaultMessageId(), path: "CstmrCdtTrfInitn.GrpHdr.MsgId");
        root.setStringValueForPath(sepaISODateString(), path: "CstmrCdtTrfInitn.GrpHdr.CreDtTm");
        root.setStringValueForPath(transfer.items.count.description, path: "CstmrCdtTrfInitn.GrpHdr.NbOfTxs");
        root.setStringValueForPath(transfer.account.owner, path: "CstmrCdtTrfInitn.GrpHdr.InitgPty.Nm");
        
        // Payment Info
        root.setStringValueForPath(transfer.paymentInfoId ?? defaultMessageId() , path: "CstmrCdtTrfInitn.PmtInf.PmtInfId");
        root.setStringValueForPath("TRF", path: "CstmrCdtTrfInitn.PmtInf.PmtMtd");
        root.setStringValueForPath(transfer.batchbook ? "true":"false", path: "CstmrCdtTrfInitn.PmtInf.BtchBookg");
        root.setStringValueForPath(transfer.items.count.description, path: "CstmrCdtTrfInitn.PmtInf.NbOfTxs");
        if let totalValue = numberToString(total) {
            root.setStringValueForPath(totalValue, path: "CstmrCdtTrfInitn.PmtInf.CtrlSum");
        } else {
            logError("Value \(total) cannot be converted to sepa string");
            return nil;
        }
        
        root.setStringValueForPath("SEPA", path: "CstmrCdtTrfInitn.PmtInf.PmtTpInf.SvcLvl.Cd");
        root.setStringValueForPath(transfer.date == nil ? "1999-01-01":sepaDateString(transfer.date!), path: "CstmrCdtTrfInitn.PmtInf.ReqdExctnDt");
        root.setStringValueForPath(transfer.account.owner, path: "CstmrCdtTrfInitn.PmtInf.Dbtr.Nm");
        root.setStringValueForPath(transfer.account.iban!, path: "CstmrCdtTrfInitn.PmtInf.DbtrAcct.Id.IBAN");
        root.setStringValueForPath(transfer.account.bic!, path: "CstmrCdtTrfInitn.PmtInf.DbtrAgt.FinInstnId.BIC");
        root.setStringValueForPath("SLEV", path: "CstmrCdtTrfInitn.PmtInf.ChrgBr");
        
        // Transaction Info
        for item in transfer.items {
            let parent = root.createPath("CstmrCdtTrfInitn.PmtInf");
            let elem = NSXMLElement(name: "CdtTrfTxInf");
            
            elem.setStringValueForPath(item.endToEndId ?? "NOTPROVIDED", path: "PmtId.EndToEndId");
            
            // amount
            if let amountValue = numberToString(item.value) {
                elem.setStringValueForPath(amountValue, path: "Amt.InstdAmt");
                
                let attr = NSXMLNode(kind: NSXMLNodeKind.AttributeKind);
                attr.name = "Ccy";
                attr.stringValue = item.currency;
                let amElem = elem.createPath("Amt.InstdAmt");
                amElem.addAttribute(attr);
            }
            elem.setStringValueForPath(item.remoteBic, path: "CdtrAgt.FinInstnId.BIC");
            elem.setStringValueForPath(item.remoteName, path: "Cdtr.Nm");
            elem.setStringValueForPath(item.remoteIban, path: "CdtrAcct.Id.IBAN");
            if let purpose = item.purpose {
                elem.setStringValueForPath(purpose, path: "RmtInf.Ustrd");
            }
            parent.addChild(elem);
        }
        
        validate();
        
        print(document.description);
        
        
        // create data from xml document
        return document.XMLData;
    }
    
}
