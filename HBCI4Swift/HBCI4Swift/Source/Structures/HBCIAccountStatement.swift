//
//  HBCIAccountStatement.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.03.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

public enum HBCIAccountStatementFormat:UInt32 {
    case MT940 = 1;
    case ISO8583 = 2;
    case PDF = 3;
}

func convertAccountStatementFormat(formatString:String?) ->HBCIAccountStatementFormat? {
    if let fString = formatString, fNum = UInt32(fString) {
        return HBCIAccountStatementFormat(rawValue: fNum);
    }
    return nil;
}


public class HBCIAccountStatement {
    public let format:HBCIAccountStatementFormat!
    public let startDate:NSDate!
    public let endDate:NSDate!
    public let booked:NSData!
    public var closingInfo:String?
    public var conditionInfo:String?
    public var advertisement:String?
    public var iban:String?
    public var bic:String?
    public var name:String?
    public var receipt:NSData?
    public var year:Int?
    public var number:Int?
    public var createdOn:NSDate?
    
    
    init?(segment:HBCISegment) {
        self.format = convertAccountStatementFormat(segment.elementValueForPath("format") as? String);
        self.startDate = segment.elementValueForPath("TimeRange.startdate") as? NSDate;
        self.endDate = segment.elementValueForPath("TimeRange.enddate") as? NSDate;
        self.booked = segment.elementValueForPath("booked") as? NSData;
        
        if self.format == nil || self.startDate == nil || self.endDate == nil || self.booked == nil {
            logError("AccountStatement: mandatory parameter is missing");
            logError(segment.description);
            return nil;
        }
        
        self.closingInfo = segment.elementValueForPath("closingInfo") as? String;
        self.conditionInfo = segment.elementValueForPath("conditionInfo") as? String;
        self.conditionInfo = segment.elementValueForPath("conditionInfo") as? String;
        self.advertisement = segment.elementValueForPath("ads") as? String;
        self.iban = segment.elementValueForPath("iban") as? String;
        self.bic = segment.elementValueForPath("bic") as? String;
        self.receipt = segment.elementValueForPath("receipt") as? NSData;
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
            self.createdOn = segment.elementValueForPath("createdOn") as? NSDate;
        }
    }
    
}
