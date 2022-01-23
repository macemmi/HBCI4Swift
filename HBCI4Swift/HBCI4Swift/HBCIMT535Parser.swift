//
//  HBCIMT535Parser.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 11.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//

import Foundation


struct HBCIMT535Tag {
    let tag:String;
    let value:String;
    
    init(tag:String, value:String) {
        self.tag = tag;
        self.value = value;
    }
    
}

class HBCIMT535Parser {
    let mt535String:String;
    var tags = Array<HBCIMT535Tag>()
    
    init(_ mt535String:String) {
        var s = mt535String.replacingOccurrences(of:"\r\n", with: "\n");
        if !s.hasPrefix("\n") {
            s = "\n"+s;
        }
        self.mt535String = s;
    }
    
    
    
    func getTagsFromString(_ mtString:String) throws ->Array<HBCIMT535Tag> {
        var residualRange: NSRange;
        var tags = Array<HBCIMT535Tag>();
        
        residualRange = NSRange(location:0, length: mtString.count);
        do {
            let regex = try NSRegularExpression(pattern: "\n:...:|\n-", options: NSRegularExpression.Options.caseInsensitive)
            var range1 = regex.rangeOfFirstMatch(in: mtString, options: NSRegularExpression.MatchingOptions(), range: residualRange);
            while range1.location != NSNotFound {
                residualRange.location = range1.location+range1.length;
                residualRange.length = mtString.count-residualRange.location;

                let range2 = regex.rangeOfFirstMatch(in: mtString as String, options: NSRegularExpression.MatchingOptions(), range: residualRange);

                if range2.location != NSNotFound {
                    var startIdx = mtString.index(mtString.startIndex, offsetBy: range1.location+2)
                    var endIdx = mtString.index(mtString.startIndex, offsetBy: range1.location+range1.length-1)
                    let tagString = String(mtString[startIdx..<endIdx]);
                    startIdx = mtString.index(mtString.startIndex, offsetBy: residualRange.location);
                    endIdx = mtString.index(mtString.startIndex, offsetBy: range2.location)
                    let value = String(mtString[startIdx..<endIdx]);
                    let tag = HBCIMT535Tag(tag: tagString, value: value);
                    tags.append(tag);
                }
                range1 = range2;
            }
        } catch let err as NSError {
            logInfo("MT535Parse error: "+err.description);
            throw HBCIError.parseError;
        }
        return tags;
    }
        
    func parseASegment() ->HBCICustodyAccountBalance? {
        var pageNumber:Int?
        var accountNumber:String?
        var bankCode:String?
        var date:Date?
        var prepDate:Date?
        var exists:Bool?
        var balanceNumber:Int?
        var accountBalance:HBCICustodyAccountBalance!
        
        var idx=0;
        while idx < tags.count {
            if tags[idx].tag == "16R" && tags[idx].value.hasPrefix("GENL") {
                idx+=1;
                while idx < tags.count {
                    let tag = tags[idx];
                    var val = tag.value;
                    if tag.tag == "16S" && tag.value.hasPrefix("GENL") {
                        break;
                    }
                    switch tag.tag {
                    case "28E":
                        if let indx = val.firstIndex(of: "/") {
                            pageNumber = Int(val.prefix(upTo: indx))
                        }
                        break;
                    case "97A":
                        val.removeFirst(7);
                        if var indx = val.firstIndex(of: "/") {
                            bankCode = String(val.prefix(upTo: indx))
                            indx = val.index(indx, offsetBy: 1)
                            accountNumber = String(val.suffix(from: indx))
                        }
                        break;
                    case "98A":
                        if val.hasPrefix(":PREP//") {
                            val.removeFirst(7);
                            prepDate = HBCIUtils.dateFormatter().date(from: val);
                            if prepDate == nil {
                                logInfo("MT535 Parse error: cannot parse preparation date from "+val);
                                return nil;
                            }
                        }
                        if val.hasPrefix(":STAT//") {
                            val.removeFirst(7);
                            date = HBCIUtils.dateFormatter().date(from: val);
                            if date == nil {
                                logInfo("MT535 Parse error: cannot parse posting date from "+val);
                                return nil;
                            }
                        }
                        break;
                    case "98C":
                        if val.hasPrefix(":PREP//") {
                            val.removeFirst(7);
                            prepDate = HBCIUtils.dateTimeFormatter().date(from: val);
                            if prepDate == nil {
                                logInfo("MT535 Parse error: cannot parse preparation date from "+val);
                                return nil;
                            }
                        }
                        if val.hasPrefix(":STAT//") {
                            val.removeFirst(7);
                            date = HBCIUtils.dateTimeFormatter().date(from: val);
                            if date == nil {
                                logInfo("MT535 Parse error: cannot parse posting date from "+val);
                                return nil;
                            }
                        }
                        break;
                    case "17B":
                        val.removeFirst(7);
                        exists = (val=="Y");
                        break;
                    case "13A":
                        val.removeFirst(7);
                        balanceNumber = Int(val);
                        break;

                    default:
                        break;
                    }
                    idx+=1;
                }
            } else {
                idx += 1;
            }
        }
                
        if let date=date, let accountNumber=accountNumber, let bankCode=bankCode, let pageNumber=pageNumber, let exists=exists {
            accountBalance = HBCICustodyAccountBalance(pageNumber: pageNumber, date: date, accountNumber: accountNumber, bankCode: bankCode, exists: exists);
        } else {
            logInfo("MT535 Parse error: cannot parse header");
            return nil;
        }
        accountBalance.balanceNumber = balanceNumber;
        return accountBalance;
    }
    
    func parseCSegment(balance: inout HBCICustodyAccountBalance) throws {
        var idx=0;
        while idx < tags.count {
            if tags[idx].tag == "16R" && tags[idx].value.hasPrefix("ADDINFO") {
                idx+=1;
                while idx < tags.count {
                    let tag = tags[idx];
                    var val = tag.value;
                    if tag.tag == "16S" && tag.value.hasPrefix("ADDINFO") {
                        break;
                    }
                    switch tag.tag {
                    case "19A":
                        var negative = false;
                        val.removeFirst(7);
                        if val.hasPrefix("N") {
                            negative = true;
                            val.removeFirst(1);
                        }
                        let curr = String(val.prefix(3));
                        val.removeFirst(3);
                        var totalValue = HBCIUtils.numberFormatter().number(from: val) as? NSDecimalNumber;
                        if totalValue != nil && negative == true {
                            totalValue = totalValue!.multiplying(by: NSDecimalNumber(-1));
                        }
                        if let totalValue=totalValue {
                            balance.depotValue = HBCIValue(value: totalValue, currency: curr);
                        } else {
                            logInfo("MT535 Parse error: cannot parse total value from "+val);
                            throw HBCIError.parseError
                        }
                        break;
                    default:
                        break;
                    }
                    idx+=1;
                }
            } else {
                idx+=1;
            }
        }
    }
    
    func createInstrument(s: String) -> HBCICustodyAccountBalance.FinancialInstrument? {
        var isin:String?
        var wkn:String?
        var name = "";

        var lines = s.split(separator: "\n");
        if let idLine = lines.first {
            if idLine.hasPrefix("ISIN ") {
                isin = String(idLine.suffix(from: idLine.index(idLine.startIndex, offsetBy: 5)))
            }
            if idLine.hasPrefix("/DE/") {
                wkn = String(idLine.suffix(from: idLine.index(idLine.startIndex, offsetBy: 4)))
            }
        }
        lines.removeFirst();
        if lines.count > 0 {
            let descrLine = lines[0];
            if descrLine.hasPrefix("/DE/") {
                wkn = String(descrLine.suffix(from: descrLine.index(descrLine.startIndex, offsetBy: 4)))
                lines.removeFirst();
            }
        }
        for line in lines {
            name = name + line + "\n";
        }
        name = name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
        
        if isin == nil && wkn == nil {
            return nil;
        }
        return HBCICustodyAccountBalance.FinancialInstrument(isin: isin, wkn: wkn, name: name);
    }
    
    func parse70E(s: String, instrument: inout HBCICustodyAccountBalance.FinancialInstrument) {
        let lines = s.split(separator: "\n");
        for var line in lines {
            if line.hasPrefix("1") {
                line.removeFirst(1);
                instrument.depotCurrency = String(line.prefix(3));
            }
            if line.hasPrefix("2") {
                line.removeFirst(1);
                let fields = line.split(separator: "+");
                if fields.count > 1 && fields[0].count > 0 && fields[1].count > 0 {
                    if let price = HBCIUtils.numberFormatter().number(from: String(fields[0])) as? NSDecimalNumber {
                        instrument.startPrice = HBCIValue(value: price, currency: String(fields[1]));
                    } else {
                        logInfo("MT535 Parse error: cannot parse instrument price from "+String(fields[0]));
                    }
                }
                if fields.count > 2 && fields[2].count > 0 {
                    instrument.interestRate = HBCIUtils.numberFormatter().number(from: String(fields[2])) as? NSDecimalNumber;
                }
            }
        }
    }
    
    func parseB1Segment(balTags:Array<HBCIMT535Tag>) throws ->HBCICustodyAccountBalance.FinancialInstrument.SubBalance? {
        var idx=0;
        var qualifier:String
        var numberType:HBCICustodyAccountBalance.NumberType;
        var isAvailable:Bool
        
        while idx < balTags.count {
            let tag = balTags[idx];
            var val = tag.value;
            switch tag.tag {
            case "93C":
                val.removeFirst(1);
                qualifier = String(val.prefix(4));
                val.removeFirst(6);
                if val.hasPrefix("UNIT") {
                    numberType = HBCICustodyAccountBalance.NumberType.pieces;
                } else {
                    numberType = HBCICustodyAccountBalance.NumberType.values;
                }
                val.removeFirst(5);
                isAvailable = val.hasPrefix("AVAI");
                val.removeFirst(5);
                var negative = false;
                if val.hasPrefix("N") {
                    negative = true;
                    val.removeFirst(1);
                }
                guard var balance = HBCIUtils.numberFormatter().number(from: val) as? NSDecimalNumber else {
                    logInfo("MT535 Parse error: cannot parse balance from "+val);
                    throw HBCIError.parseError;
                }
                if negative {
                    balance = balance.multiplying(by: NSDecimalNumber(-1));
                }
                return HBCICustodyAccountBalance.FinancialInstrument.SubBalance(balance: balance, qualifier: qualifier, numberType: numberType, isAvailable: isAvailable);
                
            default:
                break;
            }
            idx+=1;
        }
        return nil;
    }
    
    func parseSingleBSegment(segTags:Array<HBCIMT535Tag>) throws ->HBCICustodyAccountBalance.FinancialInstrument? {
        let firstTag = segTags[0];
        
        if firstTag.tag != "35B" {
            return nil;
        }
        // process first tag to get basic instrument data
        guard var result = createInstrument(s: firstTag.value) else {
            return nil;
        }
        
        var idx=1;
        while idx < segTags.count {
            let tag = segTags[idx];
            switch tag.tag {
            case "90B":
                var val = tag.value;
                val.removeFirst(12);
                result.currentPrice = HBCIValue(s: val);
                break;
            case "98A":
                var val = tag.value;
                val.removeFirst(7);
                result.priceDate = HBCIUtils.dateFormatter().date(from: val);
                break;
            case "98C":
                var val = tag.value;
                val.removeFirst(7);
                result.priceDate = HBCIUtils.dateTimeFormatter().date(from: val);
                break;
            case "93B":
                var val = tag.value;
                val.removeFirst(7);
                if val.hasPrefix("UNIT/") {
                    result.numberType = HBCICustodyAccountBalance.NumberType.pieces;
                } else {
                    result.numberType = HBCICustodyAccountBalance.NumberType.values;
                }
                val.removeFirst(5);
                var negative = false;
                if val.hasPrefix("N") {
                    negative = true;
                    val.removeFirst(1);
                }
                if let totalNumber = HBCIUtils.numberFormatter().number(from: val) as? NSDecimalNumber {
                    result.totalNumber = totalNumber
                    if negative {
                        result.totalNumber = totalNumber.multiplying(by: NSDecimalNumber(-1));
                    }
                } else {
                    logInfo("MT535 Parse error: cannot parse total number from "+val);
                    throw HBCIError.parseError;
                }
                break;
            case "94B":
                var val = tag.value;
                val.removeFirst(7);
                result.priceLocation = val;
                break;
            case "19A":
                var val = tag.value;
                if val.hasPrefix(":HOLD") {
                    val.removeFirst(7);
                    var negative = false;
                    if val.hasPrefix("N") {
                        negative = true;
                        val.removeFirst(1);
                    }
                    if var value = HBCIValue(s: val) {
                        if negative {
                            value = HBCIValue(value: value.value.multiplying(by: NSDecimalNumber(-1)), currency: value.currency);
                        }
                        result.depotValue = value;
                    } else {
                        logInfo("MT535 Parse error: cannot parse stock value from "+val);
                    }
                }
                if val.hasPrefix(":ACRU") {
                    val.removeFirst(7);
                    var negative = false;
                    if val.hasPrefix("N") {
                        negative = true;
                        val.removeFirst(1);
                    }
                    if var value = HBCIValue(s: val) {
                        if negative {
                            value = HBCIValue(value: value.value.multiplying(by: NSDecimalNumber(-1)), currency: value.currency);
                        }
                        result.accruedInterestValue = value;
                    } else {
                        logInfo("MT535 Parse error: cannot parse stock interest value from "+val);
                    }
                }
                break;
            case "70E":
                var val = tag.value;
                if val.hasPrefix(":HOLD") {
                    val.removeFirst(7);
                    parse70E(s: val, instrument: &result);
                }
            case "16R":
                if tag.value.hasPrefix("SUBBAL") {
                    idx+=1;
                    var balTags = Array<HBCIMT535Tag>();
                    while idx < segTags.count {
                        if segTags[idx].tag == "16S" && segTags[idx].value.hasPrefix("SUBBAL") {
                            // parse B1 segments
                            if let balance = try parseB1Segment(balTags: balTags) {
                                result.balances.append(balance);
                            }
                            break;
                        } else {
                            balTags.append(segTags[idx]);
                            idx+=1;
                        }
                    }
                }
                break;
                
            default: break;
            }
            idx+=1;
        }
        return result;
    }
    
    
    func parseBSegments(balance: inout HBCICustodyAccountBalance) throws {
        var idx=0;
        
        while idx < tags.count {
            if tags[idx].tag == "16R" && tags[idx].value.hasPrefix("FIN") {
                var segTags = Array<HBCIMT535Tag>();
                idx+=1;
                while idx < tags.count {
                    if tags[idx].tag == "16S" && tags[idx].value.hasPrefix("FIN") {
                        idx += 1;
                        break;
                    } else {
                        segTags.append(tags[idx]);
                        idx += 1;
                    }
                }
                // now parse single B segment
                if let segment = try parseSingleBSegment(segTags: segTags) {
                    balance.instruments.append(segment);
                }
            } else {
                idx+=1;
            }
        }
    }

    
    func parse() -> HBCICustodyAccountBalance? {
        do {
            self.tags = try getTagsFromString(self.mt535String);
            guard var balance = parseASegment() else {
                logInfo("MT535 Parse error: cannot parse account balance string " + self.mt535String);
                return nil;
            }
            try parseBSegments(balance: &balance);
            try parseCSegment(balance: &balance);
            return balance;
        }
        catch  {
            logInfo("MT535 Parse error: cannot parse tags from account balance string " + self.mt535String);
        }
        return nil;
    }


}
