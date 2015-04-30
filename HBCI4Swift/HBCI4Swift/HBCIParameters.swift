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
                var infos = HBCIPinTanInformation(segment: seg);
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
                var infos = HBCITanProcessInformation(segment: seg);
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
    
    convenience init?(data:NSData, syntax:HBCISyntax) {
        var segmentData = Array<NSData>();
        var segments = Array<HBCISegment>();
        var binaries = Array<NSData>();
        var segContent = UnsafeMutablePointer<CChar>.alloc(data.length);
        var i = 0, j = 0, segSize = 0;
        
        var p = UnsafeMutablePointer<CChar>(data.bytes);
        var q = segContent;
        
        while i < data.length {
            q.memory = p.memory;
            if p.memory == "'" && !isEscaped(p) {
                // now we have a segment in segContent
                let data = NSData(bytes: segContent, length: segSize+1);
                segmentData.append(data);
                q = segContent;
                p = p.advancedBy(1);
                segSize = 0;
                i++;
            } else {
                i++;
                segSize++;
                p = p.advancedBy(1);
                q = q.advancedBy(1);
            }
        }
        
        segContent.destroy();
        segContent.dealloc(data.length);
        
        // now we have all segment strings and we can start to parse each segment
        for segData in segmentData {
            let (segment, parseError) = syntax.parseSegment(segData, binaries: binaries);
            if parseError {
                if let segmentString = NSString(data: segData, encoding: NSISOLatin1StringEncoding) {
                    logError("Parse error: segment \(segmentString) could not be parsed");
                } else {
                    logError("Parse error: segment (no conversion possible) could not be parsed");
                }
                self.init();
                return nil;
            } else {
                if let seg = segment {
                    // only add segments that are supported by HBCI syntax
                    segments.append(seg);
                }
            }
        }
        
        self.init(segments: segments, syntax: syntax);
    }
    
    func getTanMethods() ->Array<HBCITanMethod> {
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
    
    func supportedVersionsForOrder(name:String) ->Array<Int> {
        var versions = Array<Int>();
        
        for seg in bpSegments {
            if seg.name == name {
                versions.append(seg.version);
            }
        }
        
        return versions;
    }
    
    func isOrderSupportedForAccount(order:HBCIOrder, number:String, subNumber:String? = nil) ->Bool {
        
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
    
    func supportedOrdersForAccount(number:String, subNumber:String? = nil) ->Array<HBCIOrderName> {
        var orderNames = Array<HBCIOrderName>();
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
                        
                        switch code {
                        case "HKKAZ": orderNames.append(HBCIOrderName.Statements);
                        default: continue;
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
    
    func supportedOrderNamesForAccount(number:String, subNumber:String?) ->Array<String> {
        var orderNames = Array<String>();
        
        let orders = supportedOrdersForAccount(number, subNumber: subNumber);
        for order in orders {
            orderNames.append(order.rawValue);
        }
        return orderNames;
    }
    
    func sepaVersion(urn:String) ->String? {
        var error:NSError?
        let pattern = "[0-9]{3}.[0-9]{3}.[0-9]{2}";
        
        if let match = urn.rangeOfString(pattern, options: NSStringCompareOptions.RegularExpressionSearch, range: nil, locale: nil) {
            return urn.substringWithRange(match);
        }
        return nil;
    }
    
    func sepaFormats(orderName:String?) ->[(version:String, urn:String)] {
        var result:[(version:String, urn:String)] = [];
        for seg in bpSegments {
            if seg.name == "SepaInfoPar" {
                if let formats = seg.elementValuesForPath("ParSEPAInfo.suppformats") as? [String] {
                    for urn in formats {
                        if let version = sepaVersion(urn) {
                            let tup:(version:String,urn:String) = (version, urn);
                            result.append(tup);
                        }
                    }
                }
            }
        }
        // sort array by version
        result.sort({$0.version > $1.version})
        return result;
    }
    
    

}
