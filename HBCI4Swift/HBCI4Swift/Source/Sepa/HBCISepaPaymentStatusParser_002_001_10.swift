//
//  HBCISepaPaymentStatusParser_002_001_10.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 11.09.25.
//  Copyright © 2025 Frank Emminghaus. All rights reserved.
//

open class HBCISepaPaymentStatusParser_002_001_10 {
    
    public init() {
        
    }
    
    public func parse(_ data:Data) -> HBCIVoPResult?  {
        var result:HBCIVoPResult;
        var textMatch = "";
        var textNoMatch = "";
        var textCloseMatch = ""
        var textNA = "";
        var groupStatus: HBCIVoPResultStatus?
        var items = [HBCIVoPResultItem]();
        
        
        do {
            let document = try XMLDocument(data: data, options: XMLNode.Options(rawValue: XMLNode.Options.RawValue(Int(XMLDocument.Options.documentTidyXML.rawValue))))
            
            logDebug(document.description);
            
            if let root = document.rootElement() {
                // Group Header
                // do we need something from Group Header?
                
                // Group Information and status
                guard let groupInfo = root.elementsForPath("CstmrPmtStsRpt.OrgnlGrpInfAndSts").first else {
                    logDebug("Error while parsing paymet result: group info is missing");
                    return nil;
                }
                if let groupStatusCode = groupInfo.stringValueForPath("GrpSts") {
                    groupStatus = HBCIVoPResultStatus(rawValue: groupStatusCode);
                }
                
                for userInfo in groupInfo.elementsForPath("StsRsnInf.AddtlInf") {
                    if let s = userInfo.stringValue {
                        if s.hasPrefix(HBCIVoPResultStatus.match.rawValue) {
                            textMatch += s.substringFromIndex(5) + "\n";
                        }
                        if s.hasPrefix(HBCIVoPResultStatus.noMatch.rawValue) {
                            textNoMatch += s.substringFromIndex(5) + "\n";
                        }
                        if s.hasPrefix(HBCIVoPResultStatus.closeMatch.rawValue) {
                            textCloseMatch += s.substringFromIndex(5) + "\n";
                        }
                        if s.hasPrefix(HBCIVoPResultStatus.notApplicable.rawValue) {
                            textNA += s.substringFromIndex(5) + "\n";
                        }
                    }
                }
                
                // Payment status
                for paymentInfo in root.elementsForPath("CstmrPmtStsRpt.OrgnlPmtInfAndSts") {
                    for transactionInfo in paymentInfo.elementsForPath("TxInfAndSts") {
                        if let code = transactionInfo.stringValueForPath("TxSts") {
                            
                            let status = HBCIVoPResultStatus(rawValue: code);
                            guard let iban = transactionInfo.stringValueForPath("OrgnlTxRef.CdtrAcct.Id.IBAN") else {
                                logDebug("Error while parsing paymet result: IBAN is missing");
                                continue;
                            }
                            guard let givenName = transactionInfo.stringValueForPath("OrgnlTxRef.Cdtr.Pty.Nm") else {
                                logDebug("Error while parsing paymet result: name is missing");
                                continue;
                            }
                            
                            let item = HBCIVoPResultItem(status: status!, iban: iban, givenName: givenName);

                            if status == HBCIVoPResultStatus.closeMatch {
                                item.actualName = transactionInfo.stringValueForPath("StsRsnInf.AddtlInf")
                            }
                            if status == HBCIVoPResultStatus.notApplicable {
                                item.naReasonCode = transactionInfo.stringValueForPath("StsRsnInf.Rsn.Cd");
                                item.naReasonInf = transactionInfo.stringValueForPath("StsRsnInf.AddtlInf");
                                logInfo("VoP is not supported, reason code is \(item.naReasonCode!), additional information: \(item.naReasonInf ?? "none")");                                
                            }
                            
                            items.append(item);
                        }

                    }
                }
                
                if groupStatus == nil {
                    groupStatus = HBCIVoPResultStatus.match;
                    for item in items {
                        if item.status != HBCIVoPResultStatus.match {
                            groupStatus = HBCIVoPResultStatus.withMismatches;
                            break;
                        }
                    }
                }
                
                result = HBCIVoPResult(status: groupStatus!, textMatch: textMatch, textNoMatch: textNoMatch, textCloseMatch: textCloseMatch, textNA: textNA);
                result.items = items;
                return result;
            }
        }
        catch {
        }
        
        return nil;
    }

}
