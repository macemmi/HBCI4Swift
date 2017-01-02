//
//  HBCIResultMessage.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 05.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

func isEscaped(pointer:UnsafePointer<CChar>) ->Bool {
    var count = 0;
    var p = UnsafeMutablePointer<CChar>(pointer);
    p = p.advancedBy(-1);
    while p.memory == HBCIChar.qmark.rawValue {
        p = p.advancedBy(-1);
        count += 1;
    }
    return count%2 == 1;
}

func isDelimiter(pointer:UnsafePointer<CChar>) ->Bool {
    if pointer.memory == HBCIChar.plus.rawValue || pointer.memory == HBCIChar.dpoint.rawValue || pointer.memory == HBCIChar.quote.rawValue {
        if !isEscaped(pointer) {
            return true;
        }
    }
    return false;
}

func checkForDataTag(pointer:UnsafePointer<CChar>) ->(dataLength:Int, tagLength:Int) {
    // first check if we are at the beginning of a syntax element
    let prev = pointer.advancedBy(-1);
    if !isDelimiter(prev) {
        return (0,0);
    }
    
    // now search for ending @
    var p = pointer.advancedBy(1);
    var i = 0;
    while p.memory != HBCIChar.amper.rawValue {
        if p.memory < 0x30 || p.memory > 0x39 {
            // no number
            return (0,0);
        }
        i += 1;
        p = p.advancedBy(1);
        if i > 9 {
            // safety exit condition
            return (0,0);
        }
    }
    if i == 0 {
        return (0,0);
    }
    var endp = UnsafeMutablePointer<CChar>(pointer.advancedBy(1));
    let dataLength = strtol(endp, &endp, 10);
    return (dataLength, i+2);
}

public class HBCIResultMessage {
    let syntax:HBCISyntax;
    var binaries = Array<NSData>();
    var segmentData = Array<NSData>();
    var segmentStrings = Array<NSString>();
    var segments = Array<HBCISegment>();
    var messageResponses = Array<HBCIMessageResponse>();
    var segmentResponses = Array<HBCIOrderResponse>();
    
    init(syntax:HBCISyntax) {
        self.syntax = syntax;
    }
    
    func addBinary(binary:NSData) ->Int {
        let idx = binaries.count;
        binaries.append(binary);
        return idx;
    }
    
    func parse(msgData:NSData) ->Bool {
        // first extract binary data
        let content = UnsafePointer<CChar>(msgData.bytes);
        var target = [CChar](count:msgData.length, repeatedValue:0);
        var i = 0, j = 0;
        var p = UnsafeMutablePointer<CChar>(content);
        
        while i < msgData.length {
            if p.memory == HBCIChar.amper.rawValue && i > 0 {
                // first check if we have binary data
                let (bin_size, tag_size) = checkForDataTag(p);
                if bin_size > 0 {
                    // now we have binary data
                    let bin_start = p.advancedBy(tag_size);
                    let data = NSData(bytes: bin_start, length: bin_size);
                    // add data to repository
                    let bin_idx = addBinary(data);
                    let tag = "@\(bin_idx)@";
                    if let cstr = tag.cStringUsingEncoding(NSISOLatin1StringEncoding) {
                        // copy tag to buffer
                        for c in cstr {
                            if c != 0 {
                                target[j] = c;
                                j += 1;
                            }
                        }
                        i += tag_size+bin_size;
                        p = p.advancedBy(tag_size+bin_size);
                    } else {
                        // issue during conversion
                        logError("tag \(tag) cannot be converted to Latin1");
                        return false;
                    }
                    continue;
                }
            }
            
            target[j] = p.memory;
            j += 1;
            i += 1;
            p = p.advancedBy(1);
        }
        
        // now we have data that does not contain binary data any longer
        // next step: split into sequence of segments
        let messageSize = j;
        var segContent = [CChar](count:messageSize, repeatedValue:0);
        i = 0;
        var segSize = 0;
        
        p = UnsafeMutablePointer<CChar>(target);
        while i < messageSize {
            segContent[segSize] = p.memory;
            segSize += 1;
            if p.memory == HBCIChar.quote.rawValue && !isEscaped(p) {
                // now we have a segment in segContent
                let data = NSData(bytes: segContent, length: segSize);
                self.segmentData.append(data);
                
                // we convert to String as well for debugging
                if let s = NSString(data: data, encoding: NSISOLatin1StringEncoding) {
                    self.segmentStrings.append(s);
                }
                segSize = 0;
            }
            i += 1;
            p = p.advancedBy(1);
        }
        
        // now we have all segment strings and we can start to parse each segment
        for segData in self.segmentData {
            do {
                if let segment = try self.syntax.parseSegment(segData, binaries: self.binaries) {
                    self.segments.append(segment);
                }
            }
            catch {
                if let segmentString = NSString(data: segData, encoding: NSISOLatin1StringEncoding) {
                    logError("Parse error: segment \(segmentString) could not be parsed");
                } else {
                    logError("Parse error: segment (no conversion possible) could not be parsed");
                }
                return false;
            }
        }
        return true;
    }
    
    func valueForPath(path:String) ->AnyObject? {
        var name:String?
        var newPath:String?
        if let range = path.rangeOfString(".", options: NSStringCompareOptions(), range: nil, locale: nil) {
            name = path.substringToIndex(range.startIndex);
            newPath = path.substringFromIndex(range.startIndex.successor());
        } else {
            name = path;
        }
        
        for seg in self.segments {
            if seg.name == name {
                if newPath == nil {
                    return nil;
                } else {
                    return seg.elementValueForPath(newPath!);
                }
            }
        }
        logError("Segment with name \(name) not found");
        return nil;
    }
    
    func valuesForPath(path:String) ->Array<AnyObject> {
        var result = Array<AnyObject>();
        var name:String?
        var newPath:String?
        if let range = path.rangeOfString(".", options: NSStringCompareOptions(), range: nil, locale: nil) {
            name = path.substringToIndex(range.startIndex);
            newPath = path.substringFromIndex(range.startIndex.successor());
        } else {
            name = path;
        }
        
        for seg in self.segments {
            if seg.name == name {
                if newPath == nil {
                    result.append(seg);
                } else {
                    result += seg.elementValuesForPath(newPath!);
                }
            }
        }
        return result;
    }
    
    func extractBPData() ->NSData? {
        let bpData = NSMutableData();
        
        for data in segmentData {
            //print(NSString(data: data, encoding: NSISOLatin1StringEncoding));
            if let code = NSString(bytes: data.bytes, length: 5, encoding: NSISOLatin1StringEncoding) {
                if code == "HIUPA" || code == "HIUPD" || code == "HIBPA" ||
                    (code.hasPrefix("HI") && code.hasSuffix("S")) {
                        bpData.appendData(data);
                        continue;
                }
            }
            if let code = NSString(bytes: data.bytes, length: 6, encoding: NSISOLatin1StringEncoding) {
                if code == "DIPINS" || (code.hasPrefix("HI") && code.hasSuffix("S")) {
                        bpData.appendData(data);
                }
            }
        }
        if bpData.length > 0 {
            return bpData;
        } else {
            return nil;
        }
    }
        
    func updateParameterForUser(user:HBCIUser) {
        // find BPD version
        var updateParameters = false;
        
        for seg in segments {
            if seg.name == "BPA" {
                if let version = valueForPath("BPA.version") as? Int {
                    if version > user.parameters.bpdVersion {
                        user.parameters.bpdVersion = version;
                        user.bankName = seg.elementValueForPath("kiname") as? String;
                        updateParameters = true;
                    }
                }
            }
            if seg.name == "UPA" {
                if let version = valueForPath("UPA.version") as? Int {
                    if version > user.parameters.updVersion {
                        user.parameters.updVersion = version;
                        updateParameters = true;
                    }
                }
            }
        }
        
        // always update if both versions are 0
        if user.parameters.bpdVersion == 0 && user.parameters.updVersion == 0 {
            updateParameters = true;
        }
        
        if updateParameters == false {
            return;
        }
        
        // now we update user and bank parameters
        user.parameters = HBCIParameters(segments: segments, syntax: syntax);
        user.parameters.bpData = extractBPData();
    }
    
    func segmentWithReference(number:Int, orderName:String) ->HBCISegment? {
        for segment in self.segments {
            if segment.name == orderName + "Res" {
                if let _ = segment.elementValueForPath("SegHead.ref") as? Int {
                    return segment;
                }
            }
        }
        return nil;
    }
    
    func segmentsWithReference(number:Int, orderName:String) ->Array<HBCISegment> {
        var segs = Array<HBCISegment>();
        for segment in self.segments {
            if segment.name == orderName + "Res" {
                if let _ = segment.elementValueForPath("SegHead.ref") as? Int {
                    segs.append(segment);
                }
            }
        }
        return segs;
    }
    
    func responsesForSegmentWithNumber(number:Int) ->Array<HBCIOrderResponse> {
        var responses = Array<HBCIOrderResponse>();
        for response in responsesForSegments() {
            if response.reference == number {
                responses.append(response);
            }
        }
        return responses;
    }
    
    func responsesForSegments() ->Array<HBCIOrderResponse> {
        if self.segmentResponses.count == 0 {
            for segment in self.segments {
                if segment.name == "RetSeg" {
                    // only segments with references
                    if segment.elementValueForPath("SegHead.ref") as? Int  != nil {
                        let values = segment.elementsForPath("RetVal");
                        for retVal in values {
                            if let response = HBCIOrderResponse(element: retVal) {
                                self.segmentResponses.append(response);
                            }
                        }
                    }
                }
            }
        }
        return self.segmentResponses;
    }
    
    func checkResponses() ->Bool {
        var success = true;
        for response in responsesForMessage() {
            if Int(response.code) >= 9000 {
                logError("Message from bank: "+response.description);
                success = false;
            }
        }
        for response in responsesForSegments() {
            if Int(response.code) >= 9000 || (!success && Int(response.code) >= 3000) {
                logError("Message from bank: "+response.description);
                success = false;
            }
        }
        return success;
    }
    
    func responsesForMessage() ->Array<HBCIMessageResponse> {
        if self.messageResponses.count == 0 {
            for segment in self.segments {
                if segment.name == "RetGlob" {
                    
                    let values = segment.elementsForPath("RetVal");
                    for retVal in values {
                        if let response = HBCIMessageResponse(element: retVal) {
                            self.messageResponses.append(response);
                        }
                    }
                }
            }
        }
        return self.messageResponses;
    }
    
    public func isOk() ->Bool {
        let responses = responsesForMessage();
        for response in responses {
            if let code = Int(response.code) {
                if code >= 9000 {
                    return false;
                }
            } else {
                return false;
            }
        }
        return true;
    }
    
    public func hbciParameters() -> HBCIParameters {
        return HBCIParameters(segments: self.segments, syntax: self.syntax);
    }
    
    func segmentsForOrder(orderName:String) ->Array<HBCISegment> {
        var result = Array<HBCISegment>();
        for segment in self.segments {
            if segment.name == orderName + "Res" {
                result.append(segment);
            }
        }
        return result;
    }
    
}
