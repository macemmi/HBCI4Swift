//
//  HBCIParameters.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 25.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCIParameters {
    public var bpdVersion = 0, updVersion = 0;
    var bpData:NSData?
    var bpSegments = Array<HBCISegment>();
    var pinTanInfos:HBCIPinTanInformation?
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
                    if self.pinTanInfos != nil {
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
            let (segment, parseError) = syntax.parseSegment(segData, binaries: binaries);
            if parseError {
                if let segmentString = NSString(data: segData, encoding: NSISOLatin1StringEncoding) {
                    throw createError(HBCIErrorCode.ParseError , message: "Parse error: segment \(segmentString) could not be parsed", arguments: nil);
                } else {
                    throw createError(HBCIErrorCode.ParseError, message: "Parse error: segment (no conversion possible) could not be parsed", arguments: nil);
                }
            } else {
                if let seg = segment {
                    // only add segments that are supported by HBCI syntax
                    segments.append(seg);
                }
            }
        }
        self.init(segments: segments, syntax: syntax);
        bpData = data;
    }
    
    public func getTanMethods() ->Array<HBCITanMethod> {
        var result = Array<HBCITanMethod>();
        
        for segment in bpSegments {
            if segment.name == "TANPar" {
                let procs = segment.elementsForPath("ParTAN.TANProcessParams");
                for proc in procs {
                    if let method = HBCITanMethod(element: proc, version:segment.version) {
                        result.append(method);
                    }
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
    
    public func isOrderSupported(order:HBCIOrder) ->Bool {
        
        for seg in bpSegments {
            if seg.name == "KInfo" {
                // we don't look for accounts just check if the order is supported in general (e.g. to get TAN media)
                let allowed = seg.elementsForPath("AllowedGV");
                for deg in allowed {
                    if let code = deg.elementValueForPath("code") as? String {
                        
                        if code != order.segment.code {
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
    
    public func isOrderSupportedForAccount(order:HBCIOrder, number:String, subNumber:String? = nil) ->Bool {
        
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
                
                // now we have the right segment for the requested account
                let allowed = seg.elementsForPath("AllowedGV");
                for deg in allowed {
                    if let code = deg.elementValueForPath("code") as? String {
                        
                        if code != order.segment.code {
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
    
    public func supportedOrdersForAccount(number:String, subNumber:String? = nil) ->Array<String> {
        var orderNames = Array<String>();
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
                        
                        // transfer code to order names
                        if let segv = syntax.codes[code] {
                            orderNames.append(segv.identifier);
                        }
                    }
                }
                break;
            }
        }
        
        if !found {
            logError("No account information record for account \(number) found");
        }
        return orderNames;
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
    
    

}
