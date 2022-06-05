//
//  HBCICamtParser_052_001_08.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 04.06.22.
//  Copyright © 2022 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCICamtParser_052_001_08 : HBCICamtParser {
    
    func parse(_ account:HBCIAccount, data:Data, isPreliminary:Bool) ->[HBCIStatement]? {
        
        do {
            let document = try XMLDocument(data: data, options: XMLNode.Options(rawValue: XMLNode.Options.RawValue(Int(XMLDocument.Options.documentTidyXML.rawValue))))
            if let root = document.rootElement() {
                var result = [HBCIStatement]();
                let utility = HBCISepaUtility();
                
                // Group Header
                // do we need something from Group Header?

                let reports = root.elementsForPath("BkToCstmrAcctRpt.Rpt");
                for report in reports {
                    let statement = HBCIStatement();
                    
                    for balanceElement in report.elementsForPath("Bal") {
                        if let balance = HBCIAccountBalance(element: balanceElement) {
                            switch balance.type {
                            case AccountBalanceType.PreviouslyClosedBooked: statement.startBalance = balance; break;
                            case AccountBalanceType.ClosingAvailable: statement.valutaBalance = balance; break;
                            case AccountBalanceType.ForwardAvailable: statement.futureValutaBalance = balance; break;
                            default: statement.endBalance = balance; break;
                            }
                        }
                    }
                    statement.statementRef = report.stringValueForPath("Id");
                    statement.statementNumber = report.stringValueForPath("ElctrncSeqNb")
                    statement.localIBAN = report.stringValueForPath("Acct.Id.IBAN");
                    statement.localBIC = report.stringValueForPath("Acct.Svcr.FinInstnId.BICFI");
                    
                    statement.isPreliminary = isPreliminary;
                    
                    for entry in report.elements(forName: "Ntry") {
                        let item = HBCIStatementItem();
                        
                        guard let status = entry.stringValueForPath("Sts.Cd") else {
                            return nil;
                        }
                        
                        guard let amtElem = entry.elements(forName: "Amt").first else {
                            return nil;
                        }
                        guard let amount = HBCIValue(element: amtElem) else {
                            return nil;
                        }
                        guard let dc = entry.stringValueForPath("CdtDbtInd") else {
                            return nil;
                        }
                        if dc == "DBIT" {
                            item.value = NSDecimalNumber.zero.subtracting(amount.value);
                        } else {
                            item.value = amount.value;
                        }
                        
                        if status == "INFO" {
                            continue;
                        }
                        
                        if isPreliminary == false && status != "BOOK" {
                            continue;
                        }
                        
                        item.currency = amount.currency;
                        if let dateString = entry.stringValueForPath("BookgDt.Dt") {
                            item.date = utility.stringToDate(dateString);
                        }
                        if let dateString = entry.stringValueForPath("ValDt.Dt") {
                            item.valutaDate = utility.stringToDate(dateString);
                        }
                        item.bankReference = entry.stringValueForPath("AcctSvcrRef");
                        item.transactionText = entry.stringValueForPath("AddtlNtryInf");
                        guard let detElem = entry.elementsForPath("NtryDtls.TxDtls").first else {
                            return nil;
                        }
                        if dc == "DBIT" {
                            item.remoteIBAN = detElem.stringValueForPath("RltdPties.CdtrAcct.Id.IBAN");
                            item.remoteBIC = detElem.stringValueForPath("RltdAgts.CdtrAgt.FinInstnId.BICFI");
                            item.remoteName = detElem.stringValueForPath("RltdPties.Cdtr.Pty.Nm");
                        } else {
                            item.remoteIBAN = detElem.stringValueForPath("RltdPties.DbtrAcct.Id.IBAN");
                            item.remoteBIC = detElem.stringValueForPath("RltdAgts.DbtrAgt.FinInstnId.BICFI");
                            item.remoteName = detElem.stringValueForPath("RltdPties.Dbtr.Pty.Nm");
                        }
                        var purpose = "";
                        for purpElem in detElem.elementsForPath("RmtInf.Ustrd") {
                            purpose = purpose + (purpElem.stringValue ?? "");
                        }
                        if purpose.count == 0 {
                            if let transactionText = item.transactionText {
                                if transactionText.count > 0 {
                                    let parts = transactionText.split(separator: ";");
                                    item.transactionText = String(parts.first ?? "");
                                    for part in parts {
                                        purpose += part;
                                    }
                                }
                            }
                        }
                        item.purpose = purpose;
                        
                        item.endToEndId = detElem.stringValueForPath("Refs.EndToEndId");
                        item.customerReference = detElem.stringValueForPath("Refs.InstrId");
                        item.mandateId = detElem.stringValueForPath("Refs.MndtId");
                        item.debitorId = detElem.stringValueForPath("RltdPties.Dbtr.Pty.Nm");
                        item.creditorId = detElem.stringValueForPath("RltdPties.Cdtr.Pty.Nm");
                        item.ultimateDebitorId = detElem.stringValueForPath("RltdPties.UltmtDbtr.Pty.Nm");
                        item.ultimateCreditorId = detElem.stringValueForPath("RltdPties.UltmtCdtr.Pty.Nm");
                        item.purposeCode = detElem.stringValueForPath("Purp.Cd");
                        
                        item.isSEPA = true;
                        item.isCancellation = false;
                        statement.items.append(item);
                    }
                    
                    result.append(statement);
                }
                return result;
            }
        }
        catch let err as NSError {
            logInfo(err.description);
            return nil;
        }
        return nil;
    }
}
