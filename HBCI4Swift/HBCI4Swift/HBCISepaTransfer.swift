//
//  HBCISepaTransfer.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISepaTransfer {
    class Item {
        var remoteIban:String
        var remoteBic:String
        var remoteName:String
        var purpose:String?
        var endToEndId:String?
        var currency:String
        var value:NSDecimalNumber
        
        init(iban:String, bic:String, name:String, value:NSDecimalNumber, currency:String) {
            remoteIban = iban;
            remoteBic = bic;
            remoteName = name;
            self.value = value;
            self.currency = currency;
        }
    }
    
    var sourceIban:String
    var sourceBic:String
    var sourceName:String
    var batchbook:Bool = false;
    var sepaId:String?
    var paymentInfoId:String?
    var date:NSDate?
    
    var items = Array<HBCISepaTransfer.Item>();
    
    init(iban:String, bic:String, name:String) {
        sourceIban = iban;
        sourceBic = bic;
        sourceName = name;
    }
    
    func validate() ->Bool {
        if items.count == 0 {
            logError("SEPA Transfer: no transfer items");
            return false;
        }
        
        return true;
    }

}