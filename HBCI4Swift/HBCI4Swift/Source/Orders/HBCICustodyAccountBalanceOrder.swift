//
//  HBCICustodyAccountBalanceOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 07.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCICustodyAccountBalanceOrder : HBCIOrder {
    public let account:HBCIAccount;
    public var balance:HBCICustodyAccountBalance?

    
    public init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        super.init(name: "CustodyAccountBalance", message: message);

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

        var values:Dictionary<String,Any> = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode ];
        if account.subNumber != nil {
            values["KTV.subnumber"] = account.subNumber!
        }
        if !segment.setElementValues(values) {
            logInfo("Custody Account Balance Order values could not be set");
            return false;
        }

        // add to message
        return msg.addOrder(self);
    }

    override open func updateResult(_ result:HBCIResultMessage) {
        super.updateResult(result);
        
        if let retSeg = resultSegments.first {
            if let de = retSeg.elementForPath("info") as? HBCIDataElement {
                if let info = de.value as? Data {
                    if let mt535 = String(data: info, encoding: String.Encoding.isoLatin1) {
                        let parser = HBCIMT535Parser(mt535);
                        self.balance = parser.parse();
                    }
                }
            }
        }
    }


}
