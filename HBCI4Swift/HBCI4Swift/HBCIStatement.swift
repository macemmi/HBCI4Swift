//
//  HBCIStatement.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCIStatementItem {
    var valutaDate:NSDate?
    var date:NSDate?
    var docDate:NSDate?
    
    var value:NSDecimalNumber?
    var origValue:NSDecimalNumber?
    var charge:NSDecimalNumber?
    
    var remoteName:String?
    var remoteIBAN:String?
    var remoteBIC:String?
    var remoteBankCode, remoteAccountNumber, remoteAccountSubNumber:String?
    var remoteCountry:String?
    
    var purpose:String?
    
    //var localBankCode, localAccountNumber, localAccountSubNumber: String?

    var ccNumberUms:String?
    var ccChargeKey: String?
    var ccChargeForeign: String?
    var ccChargeTerminal: String?
    var ccSettlementRef: String?
    var origCurrency: String?
    var isSettled:Bool?
    
    var customerReference:String?
    var bankReference:String?
    var transactionText:String?
    var transactionCode:Int?
    var postingKey:String?
    var currency:String?
    var primaNota:String?
    
    var isCancellation:Bool?
    var isSEPA:Bool?
    
    init() {}
}

class HBCIStatement {
    var orderRef:String?
    var statementRef:String?
    var statementNumber:String?
    var accountName:String?
    var localAccountNumber, localBankCode, localIBAN, localBIC:String?
    
    var startBalance:HBCIAccountBalance?
    var endBalance:HBCIAccountBalance?
    var valutaBalance:HBCIAccountBalance?
    var futureValutaBalance:HBCIAccountBalance?
    
    var statementItems = Array<HBCIStatementItem>();
    
    init() {}
}
