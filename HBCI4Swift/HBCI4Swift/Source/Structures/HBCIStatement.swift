//
//  HBCIStatement.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCIStatementItem {
    open var valutaDate:Date?
    open var date:Date?
    open var docDate:Date?
    
    open var value:NSDecimalNumber?
    open var origValue:NSDecimalNumber?
    open var charge:NSDecimalNumber?
    
    open var remoteName:String?
    open var remoteIBAN:String?
    open var remoteBIC:String?
    open var remoteBankCode, remoteAccountNumber, remoteAccountSubNumber:String?
    open var remoteCountry:String?
    
    open var purpose:String?
    
    //public var localBankCode, localAccountNumber, localAccountSubNumber: String?

    open var ccNumberUms:String?
    open var ccChargeKey: String?
    open var ccChargeForeign: String?
    open var ccChargeTerminal: String?
    open var ccSettlementRef: String?
    open var origCurrency: String?
    open var isSettled:Bool?
    
    open var customerReference:String?
    open var bankReference:String?
    open var transactionText:String?
    open var transactionCode:Int?
    open var postingKey:String?
    open var currency:String?
    open var primaNota:String?
    
    open var endToEndId:String?
    open var debitorId:String?
    open var creditorId:String?
    open var ultimateDebitorId:String?
    open var ultimateCreditorId:String?
    open var purposeCode:String?
    open var mandateId:String?
    
    open var isCancellation:Bool?
    open var isSEPA:Bool?
    
    public init() {}
}

open class HBCIStatement {
    open var orderRef:String?
    open var statementRef:String?
    open var statementNumber:String?
    open var accountName:String?
    open var localAccountNumber, localBankCode, localIBAN, localBIC:String?
    
    open var startBalance:HBCIAccountBalance?
    open var endBalance:HBCIAccountBalance?
    open var valutaBalance:HBCIAccountBalance?
    open var futureValutaBalance:HBCIAccountBalance?

    open var isPreliminary:Bool?

    open var items = Array<HBCIStatementItem>();
    
    public init() {}
}
