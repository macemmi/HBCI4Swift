//
//  HBCITanMedium.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 10.04.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCITanMedium {
    public let
    category:String!,
    status:String!
    
    public var
    cardNumber:String?,
    cardSeqNumber:String?,
    cardType:Int?,
    validFrom:NSDate?,
    validTo:NSDate?,
    tanListNumber:String?,
    name:String?,
    mobileNumber:String?,
    mobileNumberSecure:String?,
    freeTans:Int?,
    lastUse:NSDate?,
    activatedOn:NSDate?
    
    
    init?(element: HBCISyntaxElement, version:Int) {
        self.category = element.elementValueForPath("mediacategory") as? String;
        self.status = element.elementValueForPath("status") as? String;
                
        self.cardNumber = element.elementValueForPath("cardnumber") as? String;
        self.cardSeqNumber = element.elementValueForPath("cardseqnumber") as? String;
        self.tanListNumber = element.elementValueForPath("tanlistnumber") as? String;
        self.freeTans = element.elementValueForPath("freetans") as? Int;
        self.lastUse = element.elementValueForPath("lastuse") as? NSDate;
        self.activatedOn = element.elementValueForPath("activatedon") as? NSDate;
        
        if version > 1 {
            self.cardType = element.elementValueForPath("cardtype") as? Int;
            self.validFrom = element.elementValueForPath("validfrom") as? NSDate;
            self.validTo = element.elementValueForPath("validto") as? NSDate;
            self.name = element.elementValueForPath("medianame") as? String;
        }
        
        if version > 2 {
            self.mobileNumberSecure = element.elementValueForPath("mobilenumber_secure") as? String;
        }
        
        if version > 3 {
            self.mobileNumber = element.elementValueForPath("mobilenumber") as? String;
        }
        
        if self.category == nil || self.status == nil {
            logError("TanMedium \(self.name ?? unknown): not all mandatory fields are provided for version \(version)");
            logError(element.description);
            return nil;

        }
    }
    
}

