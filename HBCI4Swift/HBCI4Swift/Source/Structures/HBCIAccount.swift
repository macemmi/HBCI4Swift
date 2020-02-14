//
//  HBCIAccount.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCIAccount {
    public let  number:String
    public let  subNumber:String?
    public let  bankCode:String
    open var    iban:String?
    open var    bic:String?
    open var    name:String?
    public let  owner:String
    public let  currency:String
    open var    type:Int?
    open var    allowed = Array<String>();
    
    public init(number:String, subNumber:String?, bankCode:String, owner:String, currency:String) {
        self.number = number;
        self.subNumber = subNumber;
        self.bankCode = bankCode;
        self.owner = owner;
        self.currency = currency;
    }
    
    init?(segment:HBCISegment) {
        guard let number = segment.elementValueForPath("KTV.number") as? String else {
            return nil;
        }
        self.subNumber = segment.elementValueForPath("KTV.subnumber") as? String;
        guard let bankCode = segment.elementValueForPath("KTV.KIK.blz") as? String else {
            return nil;
        }
        self.number = number;
        self.bankCode = bankCode;
        guard var owner = segment.elementValueForPath("name1") as? String else {
            return nil;
        }
        if let name2 = segment.elementValueForPath("name2") as? String {
            owner = owner + name2;
        }
        self.owner = owner;
        self.name = segment.elementValueForPath("konto") as? String;
        guard let currency = segment.elementValueForPath("cur") as? String else {
            return nil;
        }
        self.currency = currency;
        
        if segment.version >= 5 {
            self.type = segment.elementValueForPath("acctype") as? Int;
        }
        
        if segment.version >= 6 {
            self.iban = segment.elementValueForPath("iban") as? String;
        }
        
        // allowed processes
        let syntax = segment.descr.syntax;
        if let allowedGVs = segment.elementsForPath("AllowedGV") as? Array<HBCIDataElementGroup> {
            for deg in allowedGVs {
                if let code = deg.elementValueForPath("code") as? String {
                    // translate code to String
                    if let segv = syntax.codes[code] {
                        allowed.append(segv.identifier);
                    }
                }
            }
        }
    }
}
