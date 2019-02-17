//
//  HBCIMT94xParser.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


struct HBCIMT94xTag {
    let tag:String;
    let value:NSString;
    
    init(tag:String, value:NSString) {
        self.tag = tag;
        self.value = value;
    }
}

struct HBCIMT94xField {
    let field:Int;
    let value:String;
    
    init(field:Int, value:String) {
        self.field = field;
        self.value = value;
    }
}


class HBCIMT94xParser {
    let mt94xString:NSString;
    
    init(mt94xString:NSString) {
        self.mt94xString = mt94xString;
    }
    
    func getTagsFromString(_ mtString:NSString) throws ->Array<HBCIMT94xTag> {
        let pattern = "\r\n:21:|\r\n:25:|\r\n:28C:|\r\n:60F:|\r\n:60M:|\r\n:61:|\r\n:86:|\r\n:62F:|\r\n:62M:|\r\n:64:|\r\n:65:";
        var nextTagRange, valueRange, residualRange: NSRange;
        var finished:Bool = false;
        var tagString = "20";
        var tags = Array<HBCIMT94xTag>();
        
        residualRange = NSRange(location:0, length: mtString.length);
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            while !finished {
                nextTagRange = regex.rangeOfFirstMatch(in: mtString as String, options: NSRegularExpression.MatchingOptions(), range: residualRange);
                if nextTagRange.location != NSNotFound {
                    valueRange = NSRange(location: residualRange.location, length: nextTagRange.location-residualRange.location);
                    residualRange.location = nextTagRange.location+nextTagRange.length;
                    residualRange.length = mtString.length-residualRange.location;
                    let tagValue = mtString.substring(with: valueRange);
                    let tag = HBCIMT94xTag(tag: tagString, value: tagValue as NSString);
                    tags.append(tag);
                    
                    var tagRange = nextTagRange;
                    tagRange.location += 3;
                    tagRange.length -= 4;
                    tagString = mtString.substring(with: tagRange);
                } else {
                    let tag = HBCIMT94xTag(tag: tagString, value: mtString.substring(with: residualRange) as NSString);
                    tags.append(tag);
                    finished = true;
                }
            }
        } catch let err as NSError {
            logError("MT94xParse error: "+err.description);
            throw HBCIError.parseError;
        }
        return tags;
    }
    
    func getTag86FieldsFromString(_ tag86String:NSString) throws ->Array<HBCIMT94xField> {
        var fields = Array<HBCIMT94xField>();
        var residualRange = NSRange(location: 0, length: tag86String.length);

        do {
            let regex = try NSRegularExpression(pattern: "\\?[0-9][0-9]", options: NSRegularExpression.Options.caseInsensitive)
            var range1 = regex.rangeOfFirstMatch(in: tag86String as String, options: NSRegularExpression.MatchingOptions(), range: residualRange);
            while range1.location != NSNotFound {
                residualRange.location = range1.location+range1.length;
                residualRange.length = tag86String.length-residualRange.location;
                let fieldTag = tag86String.substring(with: NSRange(location: range1.location+1, length: 2));
                let fieldNum = Int(fieldTag);
                if fieldNum == nil {
                    logError("MT94xParse error: field tag \(fieldTag) is not a number");
                    throw HBCIError.parseError;
                }

                let range2 = regex.rangeOfFirstMatch(in: tag86String as String, options: NSRegularExpression.MatchingOptions(), range: residualRange);
                if range2.location != NSNotFound {
                    let fieldValue = tag86String.substring(with: NSRange(location: residualRange.location, length: range2.location-residualRange.location));
                    let field = HBCIMT94xField(field: fieldNum!, value: fieldValue);
                    fields.append(field);
                } else {
                    let fieldValue = tag86String.substring(with: residualRange);
                    let field = HBCIMT94xField(field: fieldNum!, value: fieldValue);
                    fields.append(field);
                }
                range1 = range2;
            }
        } catch let err as NSError {
            logError("MT94xParse error: "+err.description);
            throw HBCIError.parseError;
        }
        return fields;
    }

    
    func checkSpecialDate(_ dateString:NSString) ->Date? {
        // special check for February - here banks often send 30. February
        if dateString.substring(with: NSMakeRange(2, 2)) == "02" {
            let day = dateString.substring(with: NSMakeRange(4, 2));
            if day == "30" || day == "31" {
                // take first of March and subract 1 day to come to the right day
                let march = dateString.substring(to: 2) + "0301";
                if let date = HBCIUtils.dateFormatter().date(from: march) {
                    let calendar = Calendar(identifier: Calendar.Identifier.gregorian);
                    return (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: -1, to: date, options: NSCalendar.Options.wrapComponents);
                }
            }
        }
        return nil;
    }
    
    func parseTag61ForItem(_ item:HBCIStatementItem, tagValue:NSString) throws {
        var location = 0;
        
        let valutaDateString = tagValue.substring(with: NSRange(location: 0, length: 6));
        item.valutaDate = HBCIUtils.dateFormatter().date(from: valutaDateString);
        if item.valutaDate == nil {
            item.valutaDate = checkSpecialDate(valutaDateString as NSString);
            if item.valutaDate == nil {
                logError("MT94xParse error: could not determine valuta date from "+valutaDateString);
                throw HBCIError.parseError;
            }
        }
        
        // check if posting date is provided
        var postingDateString = tagValue.substring(with: NSRange(location: 6, length: 4));
        do {
            let regex = try NSRegularExpression(pattern: "[0-9]+", options: NSRegularExpression.Options.caseInsensitive)
            var range = regex.rangeOfFirstMatch(in: postingDateString as String, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: 4));
            if range.location == 0 && range.length == 4 {
                // posting date is provided - now set the correct year
                // if it is the same month, we use the same year
                let valutaMonth = Int(valutaDateString.substringWithRange(NSRange(location: 2, length: 2)));
                let postingMonth = Int(postingDateString.substringToIndex(2));
                
                if valutaMonth == nil || postingMonth == nil {
                    logError("MT94xParse error: could not extract month from dates "+valutaDateString+"/"+postingDateString);
                    throw HBCIError.parseError;
                }
                
                if valutaMonth != postingMonth {
                    // month is different. Year of posting date is year of valuta date - 1 if month of valuta date < 4 and month of posting date >= 10
                    //                     Year of posting date is year of valuta date + 1 if month of valuta date >= 10 and month of
                    
                    if var year = Int(valutaDateString.substringToIndex(2)) {
                        if valutaMonth < 4 && postingMonth >= 10 {
                            year -= 1;
                        }
                        if valutaMonth >= 10 && postingMonth < 4 {
                            year += 1
                        }
                        postingDateString = String(format: "%0.2d", year)+postingDateString;
                    } else {
                        logError("MT94xParse error: could not extract year from valuta date string "+valutaDateString);
                        throw HBCIError.parseError;
                    }
                } else {
                    // valutaMonth = postingMonth
                    postingDateString = valutaDateString.substringToIndex(2)+postingDateString;
                }
                item.date = HBCIUtils.dateFormatter().date(from: postingDateString as String);
                if item.date == nil {
                    item.date = checkSpecialDate(postingDateString as NSString);
                    if item.date == nil {
                        logError("MT94xParse error: could not determine posting date from "+postingDateString);
                        throw HBCIError.parseError;
                    }
                }
                location = 10;
            } else {
                location = 6;
                item.date = item.valutaDate;
            }
            
            // debit credit
            if tagValue.substring(with: NSRange(location: location, length: 1)) == "R" {
                item.isCancellation = true;
                location += 1;
            }
            let debitcredit = tagValue.substring(with: NSRange(location: location, length: 1));
            location += 1;
            
            // check for currency kind
            let a = UInt32(tagValue.character(at: location));
            if a > UnicodeScalar("9").value || a < UnicodeScalar("0").value {
                location += 1;
            }
            
            range = tagValue.range(of: "N", options: NSString.CompareOptions(), range: NSRange(location: location, length: tagValue.length-location));
            if range.location == NSNotFound {
                logError("MT94xParse error: could not find N in tag61 (reststring: "+tagValue.substring(from: location));
                throw HBCIError.parseError;
            }
            let valueString = tagValue.substring(with: NSRange(location: location, length: range.location-location));
            item.value = HBCIUtils.numberFormatter().number(from: valueString) as? NSDecimalNumber;
            if item.value == nil {
                logError("MT94xParse error: could not parse value from "+valueString);
                throw HBCIError.parseError;
            }
            
            if debitcredit == "D" {
                item.value = NSDecimalNumber.zero.subtracting(item.value!);
            }
            
            // round
            item.value = HBCIUtils.round(item.value!);
            
            location = range.location+1;
            item.postingKey = tagValue.substring(with: NSRange(location: location, length: 3));
            location += 3;
            
            range = tagValue.range(of: "//", options: NSString.CompareOptions(), range: NSRange(location: location, length: tagValue.length-location));
            if range.location == NSNotFound {
                item.customerReference = tagValue.substring(from: location);
                return;
            }
            item.customerReference = tagValue.substring(with: NSRange(location: location, length: range.location-location));
            location = range.location+2;
            
            // todo
            
        }
        catch {
            throw HBCIError.parseError;
        }
        return;
    }
    
    
    func parseTag86ForItem(_ item:HBCIStatementItem, tagValue:NSString) throws {
        let transactionCode = tagValue.substring(to: 3);
        let location = 3;
        
        item.transactionCode = Int(transactionCode);
        if item.transactionCode == 999 {
            // unstructured
            item.purpose = tagValue.substring(from: location);
            return;
        }
        
        // structured
        let fieldString = tagValue.substring(from: location).replacingOccurrences(of: "\r", with: "");
        item.isSEPA = item.transactionCode >= 100 && item.transactionCode <= 199;
        
        // get fields
        do {
            let fields = try getTag86FieldsFromString(fieldString as NSString);
            var purpose = "";
            
            for field in fields {
                let fieldNum = field.field;
                switch fieldNum {
                case 0: item.transactionText = field.value;
                case 10: item.primaNota = field.value;
                case 30:
                    if (item.isSEPA!) {
                        item.remoteBIC = field.value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    } else {
                        item.remoteBankCode = field.value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    }
                case 20: purpose += field.value;
                case 31:
                    if item.isSEPA! {
                        item.remoteIBAN = field.value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    } else {
                        item.remoteAccountNumber = field.value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    }
                case 32: item.remoteName = field.value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                case 33:
                    if item.remoteName != nil {
                        item.remoteName! += field.value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    } else {
                        item.remoteName = field.value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    }
                default:
                    if (fieldNum >= 20 && fieldNum <= 29) || (fieldNum >= 60 && fieldNum <= 63) {
                        purpose += field.value;
                    }
                }
            }
            if purpose.count > 0 {
                item.purpose = purpose;
            }
        }
        catch {
            logError("MT94xParse error: not able to get field86 tags from "+fieldString);
            throw HBCIError.parseError;
        }
    }
    
    func parseBalance(_ s:NSString) ->HBCIAccountBalance? {
        let debitcredit = s.substring(to: 1);
        let dateString = s.substring(with: NSRange(location: 1, length: 6));
        let postingDate = HBCIUtils.dateFormatter().date(from: dateString);
        if postingDate == nil {
            logError("MT94xParse error: cannot parse posting date from "+dateString);
            return nil;
        }
        let currency = s.substring(with: NSRange(location: 7, length: 3));
        let valueString = s.substring(from: 10);
        if var value = HBCIUtils.numberFormatter().number(from: valueString) as? NSDecimalNumber {
            if debitcredit == "D" {
                value = NSDecimalNumber.zero.subtracting(value);
            }
            
            // round
            value = HBCIUtils.round(value);
            return HBCIAccountBalance(value: value, date: postingDate!, currency: currency);
        } else {
            logError("MT94xParse error: cannot parse value from "+valueString);
            return nil;
        }
    }
    
    func parseAccountName(_ name:NSString, statement:HBCIStatement) {
        let range = name.range(of: "/");
        if range.location == NSNotFound {
            return;
        }
        let part1 = name.substring(with: NSRange(location: 0, length: range.location));
        let part2 = name.substring(with: NSRange(location: range.location+1, length: name.length-range.location-1));
        var isBLZ = true;
        if range.location == 8 {
            // is part1 a BLZ or BIC?
            for character in part1 {
                if character < "0" || character > "9" {
                    isBLZ = false;
                    break;
                }
            }
        }
        if isBLZ {
            statement.localBankCode = part1;
        } else {
            statement.localBIC = part1;
        }
        if part2.count > 23 {
            statement.localIBAN = part2;
        } else {
            // extract account number
            var number = "";
            for character in part2 {
                if character < "0" || character > "9" {
                    break;
                } else {
                    number.append(character);
                }
            }
            statement.localAccountNumber = number;
        }
    }
    
    func parseStatement(_ rawStatement:NSString) throws ->HBCIStatement {
        var idx = 0;
        
        let rawStatementString = rawStatement as String;
        let missingTagsString = "MT94xParse error: unexpected end of tags in data "+rawStatementString;
        
        let statement = HBCIStatement();

        let tags = try getTagsFromString(rawStatement);
        var tag = tags[idx]; idx += 1;
        if tag.tag == "20" {
            statement.orderRef = tag.value as String;
        } else {
            logError("MT94xParse error: tag20 field is missing in MT94x entry "+rawStatementString);
            // we will nevertheless go on
        }
        
        if idx >= tags.count {
            logError(missingTagsString);
            throw HBCIError.parseError;
        }
        tag = tags[idx]; idx += 1;
        // optional reference
        if tag.tag == "21" {
            statement.statementRef = tag.value as String;
            if idx >= tags.count {
                logError(missingTagsString);
                throw HBCIError.parseError;
            }
            if idx >= tags.count {
                logError(missingTagsString);
                throw HBCIError.parseError;
            }
            tag = tags[idx]; idx += 1;
        }
        
        if tag.tag == "25" {
            statement.accountName = tag.value as String;
            parseAccountName(tag.value, statement: statement);
        } else {
            logError("MT94xParse error: tag25 is missing in MT94x entry "+rawStatementString);
            // we will nevertheless go on
        }
        
        // statement number
        if idx >= tags.count {
            logError(missingTagsString);
            throw HBCIError.parseError;
        }
        tag = tags[idx]; idx += 1;
        if tag.tag == "28C" {
            statement.statementNumber = tag.value as String;
        } else {
            logError("MT94xParse error: tag28C is missing in MT94x entry "+rawStatementString);
            // we will nevertheless go on
        }
        
        if idx >= tags.count {
            logError(missingTagsString);
            throw HBCIError.parseError;
        }
        tag = tags[idx]; idx += 1;
        if tag.tag == "60F" || tag.tag == "60M" {
            statement.startBalance = parseBalance(tag.value);
            if statement.startBalance == nil {
                logError("MT94xParse error: cannot parse start balance in MT94x entry "+rawStatementString);
                throw HBCIError.parseError;
            }
        } else {
            logError("MT94xParse error: start balance is missing in MT94x entry "+rawStatementString);
            throw HBCIError.parseError;
        }
        
        // statement items
        if idx >= tags.count {
            // in some cases banks send wrong MT94x data. If there are no statements the ending balance can be missing
            return statement;
        }
        tag = tags[idx]; idx += 1;
        while tag.tag == "61" {
            //items
            let item = HBCIStatementItem();
            do {
                try parseTag61ForItem(item, tagValue: tag.value);
            }
            catch {
                logError("MT94xParseError: cannot parse tag61 from "+(tag.value as String));
                throw HBCIError.parseError;
            }
            
            if idx >= tags.count {
                logError(missingTagsString);
                throw HBCIError.parseError;
            }
            tag = tags[idx]; idx += 1;
            if tag.tag == "86" {
                do {
                    try parseTag86ForItem(item, tagValue: tag.value);
                }
                catch {
                    logError("MT94xParseError: cannot parse tag86 from "+(tag.value as String));
                    throw HBCIError.parseError;
                }
                if idx >= tags.count {
                    logError(missingTagsString);
                    throw HBCIError.parseError;
                }
                tag = tags[idx]; idx += 1;
            }
            statement.items.append(item);
        }
        
        // end balance
        if tag.tag == "62F" || tag.tag == "62M" {
            statement.endBalance = parseBalance(tag.value);
            if statement.startBalance == nil {
                logError("MT94xParse error: cannot parse end balance in MT94x entry "+rawStatementString);
                // we will nevertheless go on                
            }
        } else {
            logError("MT94xParse error: end balance is missing in MT94x entry "+rawStatementString);
            // we will nevertheless go on
        }
        
        // further data
        while idx < tags.count {
            tag = tags[idx]; idx += 1;

            // valuta balace
            if tag.tag == "64" {
                statement.valutaBalance = parseBalance(tag.value);
            }
            
            // future valuta balance
            if tag.tag == "65" {
                statement.futureValutaBalance = parseBalance(tag.value);
            }
        }
        
        return statement;
    }
    
    func parse() throws ->Array<HBCIStatement> {
        var statements = Array<HBCIStatement>();
        let rawStatements = self.mt94xString.components(separatedBy: "\r\n:20:") ;
        for raw in rawStatements {
            if raw.count > 2 {
                var trimmed = raw.replacingOccurrences(of: "@@", with: "\r\n") as NSString;
                trimmed = trimmed.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as NSString;
                let ending = trimmed.substring(from: trimmed.length-3);
                if ending != "\r\n-" {
                    logError("MT94xParse error: cannot parse MT94x statement: "+(trimmed as String));
                    throw HBCIError.parseError;
                }
                trimmed = trimmed.substring(to: trimmed.length-3) as NSString;
                do {
                    let statement = try parseStatement(trimmed);
                    statements.append(statement);
                }
                catch {
                    logError("MT94xParse error: cannot parse MT94x statement: "+(trimmed as String));
                    throw HBCIError.parseError;
                }
            }
        }
        return statements;
    }

    
    
    
    
}
