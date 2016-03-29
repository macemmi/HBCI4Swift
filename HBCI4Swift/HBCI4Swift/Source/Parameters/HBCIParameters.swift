//
//  HBCIParameters.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 25.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public typealias HBCISegmentCode = String;

public class HBCIParameters {
    public var bpdVersion = 0, updVersion = 0;
    public var pinTanInfos:HBCIPinTanInformation?
    var bpData:NSData?
    var bpSegments = Array<HBCISegment>();
    var tanProcessInfos:HBCITanProcessInformation?
    var supportedTanMethods = Array<String>();
    var syntax:HBCISyntax!
    
    init() {}
    
    public func data() ->NSData? {
        return bpData;
    }
    
    init(segments:Array<HBCISegment>, syntax:HBCISyntax) {
        self.syntax = syntax;
        for seg in segments {
            if seg.name == "BPA" || seg.name == "UPA" || seg.name == "KInfo" ||
                (seg.code.hasPrefix("HI") && seg.code.hasSuffix("S")) {
                    self.bpSegments.append(seg);
            }
            if seg.name == "BPA" {
                if let version = seg.elementValueForPath("version") as? Int {
                    self.bpdVersion = version;
                }
            }
            if seg.name == "UPA" {
                if let version = seg.elementValueForPath("version") as? Int {
                    self.updVersion = version;
                }
            }

            if seg.name == "RetSeg" {
                let elements = seg.elementsForPath("RetVal");
                for element in elements {
                    if let code = element.elementValueForPath("code") as? String {
                        if code == "3920" {
                            let values = element.elementValuesForPath("parm");
                            for value in values {
                                if let secfunc = value as? String {
                                    self.supportedTanMethods.append(secfunc);
                                }
                            }
                        }
                    }
                }
            }
            if seg.name == "PinTanInformation" || seg.name == "PinTanInformation_old" {
                // update PIN/TAN information - take highest version
                let infos = HBCIPinTanInformation(segment: seg);
                if infos.version != nil {
                    if self.pinTanInfos != nil  && self.pinTanInfos!.version != nil {
                        if self.pinTanInfos!.version! > infos.version! {
                            continue;
                        }
                    }
                }
                self.pinTanInfos = infos;
            }
            if seg.name == "TANPar" {
                // update TAN Process information - take highest version supported by us
                let infos = HBCITanProcessInformation(segment: seg);
                if self.tanProcessInfos != nil {
                    if self.tanProcessInfos!.version! > infos.version! {
                        continue;
                    }
                }
                // now check if we support this version
                if let segVersions = syntax.segs["TANPar"] {
                    if segVersions.isVersionSupported(infos.version!) {
                        self.tanProcessInfos = infos;
                    }
                }
            }
        }
    }
    
    convenience init(data:NSData, syntax:HBCISyntax) throws {
        var segmentData = Array<NSData>();
        var segments = Array<HBCISegment>();
        let binaries = Array<NSData>();
        var segContent = [CChar](count:data.length, repeatedValue:0);
        var i = 0, segSize = 0;
        
        var p = UnsafeMutablePointer<CChar>(data.bytes);
        
        while i < data.length {
            //q.memory = p.memory;
            segContent[segSize++] = p.memory;
            if p.memory == HBCIChar.quote.rawValue && !isEscaped(p) {
                // now we have a segment in segContent
                let data = NSData(bytes: segContent, length: segSize);
                segmentData.append(data);
                segSize = 0;
            }
            i++;
            p = p.advancedBy(1);
        }
        
        // now we have all segment strings and we can start to parse each segment
        for segData in segmentData {
            do {
                if let segment = try syntax.parseSegment(segData, binaries: binaries) {
                    // only add segments that are supported by HBCI syntax
                    segments.append(segment);
                }
            }
            catch is HBCIError {
                if let segmentString = NSString(data: segData, encoding: NSISOLatin1StringEncoding) {
                    logError("Parse error: segment \(segmentString) could not be parsed");
                    throw HBCIError.ParseError;
                } else {
                    logError("Parse error: segment (no conversion possible) could not be parsed");
                    throw HBCIError.ParseError;
                }
            }
        }
        self.init(segments: segments, syntax: syntax);
        bpData = data;
    }
    
    public func getTanMethods() ->Array<HBCITanMethod> {
        var result = Array<HBCITanMethod>();
        
        if let tpi = self.tanProcessInfos {
            for method in tpi.tanMethods {
                if self.supportedTanMethods.contains(method.secfunc) {
                    result.append(method);
                }
            }
        }
        return result;
    }
    
    public func supportedVersionsForOrder(name:String) ->Array<Int> {
        var versions = Array<Int>();
        
        for seg in bpSegments {
            if seg.name == name {
                versions.append(seg.version);
            }
        }
        
        return versions;
    }
    
    func supportedSegmentVersion(name:String) ->HBCISegmentDescription? {
        if let segVersions = syntax.segs[name] {
            // now find the right segment version
            // check which segment versions are supported by the bank
            var supportedVersions = Array<Int>();
            for seg in bpSegments {
                if seg.name == name+"Par" {
                    // check if this version is also supported by us
                    if segVersions.isVersionSupported(seg.version) {
                        supportedVersions.append(seg.version);
                    }
                }
            }
            
            if supportedVersions.count == 0 {
                // this process is not supported by the bank
                return nil;
            }
            // now sort the versions - we take the latest supported version
            supportedVersions.sortInPlace(>);
            
            return segVersions.segmentWithVersion(supportedVersions.first!);
        }
        logError("Segment \(name) is not supported by HBCI4Swift");
        return nil;
    }
    
    public func isSegmentCodeSupported(segmentCode:String, accountNumber:String? = nil, accountSubNumber:String? = nil) ->Bool {
        for seg in bpSegments {
            if seg.name == "KInfo" {
                // if account is defined, we check that the account matches
                if let number = accountNumber {
                    if let accountNumber = seg.elementValueForPath("KTV.number") as? String {
                        if accountNumber != number {
                            continue;
                        }
                    } else {
                        continue;
                    }
                    if let subNumber = accountSubNumber {
                        if let subnumber = seg.elementValueForPath("KTV.subnumber") as? String {
                            if subNumber != subnumber {
                                continue;
                            }
                        } else {
                            continue;
                        }
                    }
                }
                
                // now we have the right account, or -
                // if no account is specified we don't look for accounts just check if the order is supported in general (e.g. to get TAN media)
                let allowed = seg.elementsForPath("AllowedGV");
                for deg in allowed {
                    if let code = deg.elementValueForPath("code") as? String {
                        
                        if code != segmentCode {
                            continue;
                        }
                        
                        // now check if job is supported in pinTanInfos
                        if let ptInfos = self.pinTanInfos {
                            if ptInfos.supportedSegs[code] == nil {
                                // this is not supported via PIN/TAN
                                return false;
                            }
                        }
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    public func isOrderSupported(segmentName:String) ->Bool {
        guard let sd = supportedSegmentVersion(segmentName) else {
            return false;
        }
        
        return isSegmentCodeSupported(sd.code);
    }
    
    public func isOrderSupported(order:HBCIOrder) ->Bool {
        return isSegmentCodeSupported(order.segment.code);
    }
    
    public func isOrderSupportedForAccount(order:HBCIOrder, number:String, subNumber:String? = nil) ->Bool {
        return isSegmentCodeSupported(order.segment.code, accountNumber: number, accountSubNumber: subNumber);
    }
    
    public func isOrderSupportedForAccount(segmentName:String, number:String, subNumber:String? = nil) ->Bool {
        guard let sd = supportedSegmentVersion(segmentName) else {
            return false;
        }
        return isSegmentCodeSupported(sd.code, accountNumber: number, accountSubNumber: subNumber);
    }
    
    
    public func supportedOrderCodesForAccount(number:String, subNumber:String? = nil) ->Array<String> {
        var orderCodes = Array<String>();
        var found = false;
        
        for seg in bpSegments {
            if seg.name == "KInfo" {
                if let accountNumber = seg.elementValueForPath("KTV.number") as? String {
                    if accountNumber != number {
                        continue;
                    }
                } else {
                    continue;
                }
                if subNumber != nil {
                    if let subnumber = seg.elementValueForPath("KTV.subnumber") as? String {
                        if subNumber != subnumber {
                            continue;
                        }
                    } else {
                        continue;
                    }
                }
                found = true;
                
                
                let allowed = seg.elementsForPath("AllowedGV");
                for deg in allowed {
                    if let code = deg.elementValueForPath("code") as? String {
                        if let ptInfos = self.pinTanInfos {
                            if ptInfos.supportedSegs[code] == nil {
                                // this is not supported via PIN/TAN
                                continue;
                            }
                        }
                        
                        orderCodes.append(code);
                    }
                }
                break;
            }
        }
        
        if !found {
            logError("No account information record for account \(number) found");
        }
        return orderCodes;

    }
    
    public func supportedOrdersForAccount(number:String, subNumber:String? = nil) ->Array<String> {
        var orderNames = Array<String>();
        
        let codes = supportedOrderCodesForAccount(number, subNumber: subNumber);
        for code in codes {
            // transfer code to order names
            if let segv = syntax.codes[code] {
                orderNames.append(segv.identifier);
            }
        }
        return orderNames;
    }
    
    func parametersForJob(jobName:String) ->HBCISegment? {
        let parSegName = jobName + "Par";
        for seg in bpSegments {
            if seg.name == parSegName {
                return seg;
            }
        }
        return nil;
    }
    
    func sepaFormats(type:HBCISepaFormatType, orderName:String?) ->[HBCISepaFormat] {
        var result:[HBCISepaFormat] = [];
        for seg in bpSegments {
            if seg.name == "SepaInfoPar" {
                if let formats = seg.elementValuesForPath("ParSepaInfo.suppformats") as? [String] {
                    for urn in formats {
                        if let format = HBCISepaFormat(urn: urn) {
                            if format.type == type {
                                result.append(format);
                            }
                        }
                    }
                }
            }
        }
        // sort array by version
        result.sortInPlace({$1 < $0})
        return result;
    }
    
    public func getAccounts() ->Array<HBCIAccount> {
        var result = Array<HBCIAccount>();
        
        for seg in bpSegments {
            if seg.name == "KInfo" {
                if let account = HBCIAccount(segment: seg) {
                    result.append(account);
                }
            }
        }
        return result;
    }
    
    public var description:String {
        get {
            var result = "";
            for segment in bpSegments {
                result += segment.description;
                result += "\n";
            }
            return result;
        }
    }
    

}
