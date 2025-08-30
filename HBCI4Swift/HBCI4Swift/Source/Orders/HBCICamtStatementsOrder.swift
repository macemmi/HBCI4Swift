//
//  HBCICamtStatementsOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 01.07.20.
//  Copyright © 2020 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCICamtStatementsOrder: HBCIOrder {
    public let account:HBCIAccount;
    open var statements:Array<HBCIStatement>
    open var dateFrom:Date?
    open var dateTo:Date?

    var offset:String?
    var camtFormat:String?
    var bookedPart:Data?
    var isPartial = false;
    var partNumber = 1;

    public init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        self.statements = Array<HBCIStatement>();
        super.init(name: "CamtStatements", message: message);
        
        if self.segment == nil {
            return nil;
        }
    }

    open func enqueue() ->Bool {
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: account.number, subNumber: account.subNumber) {
            logInfo(self.name + " is not supported for account " + account.number);
            return false;
        }
        
        var values = Dictionary<String,Any>();
        
        // check if SEPA version is supported (only globally for bank -
        // later we check if account supports this as well
        if account.iban == nil || account.bic == nil {
            logInfo("Account has no IBAN or BIC information");
            return false;
        }
        
        values = ["KTV.bic":account.bic!, "KTV.iban":account.iban!, "KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode, "allaccounts":false];
        if account.subNumber != nil {
            values["KTV.subnumber"] = account.subNumber!
        }

        if let sepaInfo = user.parameters.sepaInfoParameters() {
            if !sepaInfo.allowsNationalAccounts {
                values.removeValue(forKey: "KTV.number");
                values.removeValue(forKey: "KTV.subnumber");
                values.removeValue(forKey: "KTV.KIK.country");
                values.removeValue(forKey: "KTV.KIK.blz");
            }
        }
        
        if var date = dateFrom {
            if let maxdays = user.parameters.maxStatementDays() {
                let currentDate = Date();
                let minDate = currentDate.addingTimeInterval((Double)(maxdays * 24 * 3600 * -1));
                if minDate > date {
                    date = minDate;
                }
            }
            values["startdate"] = date;
        }
        if let date = dateTo {
            values["enddate"] = date;
        }
        if let ofs = offset {
            values["offset"] = ofs;
        }
        
        let formats = user.parameters.camtFormats();
        guard formats.count > 0 else {
            logInfo("No supported camt formats");
            return false;
        }
        for format in formats {
            if format.hasSuffix("052.001.02") || format.hasSuffix("052.001.08") {
                camtFormat = format;
                //break;
            } else {
                logDebug("Camt format "+format+" is not supported");
            }
        }
        
        guard let format = camtFormat else {
            logInfo("No supported Camt formats found");
            return false;
        }
        values["format"] = format;

        if !segment.setElementValues(values) {
            logInfo("CamtStatements Order values could not be set");
            return false;
        }
        
        // add to message
        return msg.addOrder(self);
    }

    func getOutstandingPart(_ offset:String) ->Data? {
        do {
            if let msg = HBCICustomMessage.newInstance(msg.dialog) {
                if let order = HBCICamtStatementsOrder(message: msg, account: self.account) {
                    order.dateFrom = self.dateFrom;
                    order.dateTo = self.dateTo;
                    order.offset = offset;
                    order.isPartial = true;
                    order.partNumber = self.partNumber + 1;
                    if !order.enqueue() { return nil; }
                    
                    _ = try msg.send();
                    
                    return order.bookedPart;
                }
            }
        }
        catch {
            // we don't do anything in case of errors
        }
        return nil;
    }

    override open func updateResult(_ result: HBCIResultMessage) {
        var parser:HBCICamtParser!
        
        super.updateResult(result);
        
        // check whether result is incomplete
        self.offset = nil;
        for response in result.segmentResponses {
            if response.code == "3040" && response.parameters.count > 0 {
                self.offset = response.parameters[0];
            }
        }
        
        if camtFormat!.hasSuffix("052.001.02") {
            parser = HBCICamtParser_052_001_02();
        } else {
            parser = HBCICamtParser_052_001_08();
        }
        
        // now parse statements
        self.statements.removeAll();
        for seg in resultSegments {
            if let booked_list = seg.elementValuesForPath("booked.statement") as? [Data] {
                
                for var booked in booked_list {
                    // check whether result is incomplete
                    if let offset = self.offset {
                        if partNumber >= 100 {
                            // we stop here - too many statement parts
                            logInfo("Too many statement parts but we still get response 3040 - we stop here")
                        } else {
                            if let part2 = getOutstandingPart(offset) {
                                booked.append(part2);
                            }
                        }
                    }
                    
                    // check if we are a part or the original order
                    if isPartial {
                        self.bookedPart = booked;
                    } else {
                        if let statements = parser.parse(account, data: booked, isPreliminary: false) {
                            self.statements.append(contentsOf: statements);
                        }
                    }
                }
            }
            if let notbooked = seg.elementValueForPath("notbooked") as? Data {
                if let statements = parser.parse(account, data: notbooked, isPreliminary: true) {
                    self.statements.append(contentsOf: statements);
                }
            }
        }
    }
    
}
