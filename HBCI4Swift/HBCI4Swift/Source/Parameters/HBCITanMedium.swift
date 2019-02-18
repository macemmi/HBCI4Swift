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
    validFrom:Date?,
    validTo:Date?,
    tanListNumber:String?,
    name:String?,
    mobileNumber:String?,
    mobileNumberSecure:String?,
    freeTans:Int?,
    lastUse:Date?,
    activatedOn:Date?
    
    
    init?(element: HBCISyntaxElement, version:Int) {
        self.category = element.elementValueForPath("mediacategory") as? String;
        self.status = element.elementValueForPath("status") as? String;
                
        self.cardNumber = element.elementValueForPath("cardnumber") as? String;
        self.cardSeqNumber = element.elementValueForPath("cardseqnumber") as? String;
        self.tanListNumber = element.elementValueForPath("tanlistnumber") as? String;
        self.freeTans = element.elementValueForPath("freetans") as? Int;
        self.lastUse = element.elementValueForPath("lastuse") as? Date;
        self.activatedOn = element.elementValueForPath("activatedon") as? Date;
        
        if version > 1 {
            self.cardType = element.elementValueForPath("cardtype") as? Int;
            self.validFrom = element.elementValueForPath("validfrom") as? Date;
            self.validTo = element.elementValueForPath("validto") as? Date;
            self.name = element.elementValueForPath("medianame") as? String;
        }
        
        if version > 2 {
            self.mobileNumberSecure = element.elementValueForPath("mobilenumber_secure") as? String;
        }
        
        if version > 3 {
            self.mobileNumber = element.elementValueForPath("mobilenumber") as? String;
        }
        
        if self.category == nil || self.status == nil {
            logDebug("TanMedium \(self.name ?? unknown): not all mandatory fields are provided for version \(version)");
            logDebug(element.description);
            return nil;

        }
    }
    
}

