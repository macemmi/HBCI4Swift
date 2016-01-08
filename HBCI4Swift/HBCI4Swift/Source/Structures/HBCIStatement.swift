//
//  HBCIStatement.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCIStatementItem {
    public var valutaDate:NSDate?
    public var date:NSDate?
    public var docDate:NSDate?
    
    public var value:NSDecimalNumber?
    public var origValue:NSDecimalNumber?
    public var charge:NSDecimalNumber?
    
    public var remoteName:String?
    public var remoteIBAN:String?
    public var remoteBIC:String?
    public var remoteBankCode, remoteAccountNumber, remoteAccountSubNumber:String?
    public var remoteCountry:String?
    
    public var purpose:String?
    
    //public var localBankCode, localAccountNumber, localAccountSubNumber: String?

    public var ccNumberUms:String?
    public var ccChargeKey: String?
    public var ccChargeForeign: String?
    public var ccChargeTerminal: String?
    public var ccSettlementRef: String?
    public var origCurrency: String?
    public var isSettled:Bool?
    
    public var customerReference:String?
    public var bankReference:String?
    public var transactionText:String?
    public var transactionCode:Int?
    public var postingKey:String?
    public var currency:String?
    public var primaNota:String?
    
    public var isCancellation:Bool?
    public var isSEPA:Bool?
    
    init() {}
}

public class HBCIStatement {
    public var orderRef:String?
    public var statementRef:String?
    public var statementNumber:String?
    public var accountName:String?
    public var localAccountNumber, localBankCode, localIBAN, localBIC:String?
    
    public var startBalance:HBCIAccountBalance?
    public var endBalance:HBCIAccountBalance?
    public var valutaBalance:HBCIAccountBalance?
    public var futureValutaBalance:HBCIAccountBalance?
    
    public var items = Array<HBCIStatementItem>();
    
    init() {}
}
