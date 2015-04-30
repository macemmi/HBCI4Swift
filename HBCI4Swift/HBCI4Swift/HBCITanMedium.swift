//
//  HBCITanMedium.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 10.04.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCITanMedium {
    var category:String
    var status:String
    var cardNumber:String?
    var cardSeqNumber:String?
    var cardType:Int?
    var validFrom:NSDate?
    var validTo:NSDate?
    var tanListNumber:String?
    var name:String?
    var mobileNumber:String?
    var mobileNumberSecure:String?
    var freeTans:Int?
    var lastUse:NSDate?
    var activatedOn:NSDate?
    
    
    init?(element: HBCISyntaxElement) {
        if let cat = element.elementValueForPath("mediacategory") as? String {
            self.category = cat;
        } else {
            self.category = ""
            self.status = "";
            return nil;
        }
        if let status = element.elementValueForPath("status") as? String {
            self.status = status;
        } else {
            self.status = "";
            return nil;
        }
        self.cardNumber = element.elementValueForPath("cardnumber") as? String;
        self.cardSeqNumber = element.elementValueForPath("cardseqnumber") as? String;
        self.cardType = element.elementValueForPath("cardtype") as? Int;
        self.validFrom = element.elementValueForPath("validfrom") as? NSDate;
        self.validTo = element.elementValueForPath("validto") as? NSDate;
        self.tanListNumber = element.elementValueForPath("tanlistnumber") as? String;
        self.name = element.elementValueForPath("medianame") as? String;
        self.mobileNumber = element.elementValueForPath("mobilenumber") as? String;
        self.mobileNumberSecure = element.elementValueForPath("mobilenumber_secure") as? String;
        self.freeTans = element.elementValueForPath("freetans") as? Int;
        self.lastUse = element.elementValueForPath("lastuse") as? NSDate;
        self.activatedOn = element.elementValueForPath("activatedon") as? NSDate;
    }
    
}

