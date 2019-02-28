//
//  HBCIAccountStatement.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.03.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

public enum HBCIAccountStatementFormat:UInt32 {
    case mt940 = 1;
    case iso8583 = 2;
    case pdf = 3;
}

func convertAccountStatementFormat(_ formatString:String?) ->HBCIAccountStatementFormat? {
    if let fString = formatString, let fNum = UInt32(fString) {
        return HBCIAccountStatementFormat(rawValue: fNum);
    }
    return nil;
}


open class HBCIAccountStatement {
    open let format:HBCIAccountStatementFormat!
    open let startDate:Date!
    open let endDate:Date!
    open let booked:Data!
    open var closingInfo:String?
    open var conditionInfo:String?
    open var advertisement:String?
    open var iban:String?
    open var bic:String?
    open var name:String?
    open var receipt:Data?
    open var year:Int?
    open var number:Int?
    open var createdOn:Date?
    
    
    init?(segment:HBCISegment) {
        self.format = convertAccountStatementFormat(segment.elementValueForPath("format") as? String);
        self.startDate = segment.elementValueForPath("TimeRange.startdate") as? Date;
        self.endDate = segment.elementValueForPath("TimeRange.enddate") as? Date;
        self.booked = segment.elementValueForPath("booked") as? Data;
        
        if self.format == nil || self.startDate == nil || self.endDate == nil || self.booked == nil {
            logInfo("AccountStatement: mandatory parameter is missing");
            logInfo(segment.description);
            return nil;
        }
        
        self.closingInfo = segment.elementValueForPath("closingInfo") as? String;
        self.conditionInfo = segment.elementValueForPath("conditionInfo") as? String;
        self.conditionInfo = segment.elementValueForPath("conditionInfo") as? String;
        self.advertisement = segment.elementValueForPath("ads") as? String;
        self.iban = segment.elementValueForPath("iban") as? String;
        self.bic = segment.elementValueForPath("bic") as? String;
        self.receipt = segment.elementValueForPath("receipt") as? Data;
        self.name = segment.elementValueForPath("name") as? String;
        if let name = self.name {
            if let name2 = segment.elementValueForPath("name2") as? String {
                if let name3 = segment.elementValueForPath("name3") as? String {
                    self.name = name + name2 + name3;
                } else {
                    self.name = name + name2;
                }
            }
        }
        
        if segment.version >= 5 {
            self.year = segment.elementValueForPath("year") as? Int;
            self.number = segment.elementValueForPath("idx") as? Int;
            self.createdOn = segment.elementValueForPath("createdOn") as? Date;
        }
    }
    
}
