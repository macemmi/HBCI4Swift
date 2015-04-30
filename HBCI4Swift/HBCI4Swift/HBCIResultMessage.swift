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
    while p.memory == "?" {
        p = p.advancedBy(-1);
        count++;
    }
    return count%2 == 1;
}

func isDelimiter(pointer:UnsafePointer<CChar>) ->Bool {
    if pointer.memory == "+" || pointer.memory == ":" || pointer.memory == "'" {
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
    while p.memory != "@" {
        if p.memory < "0" || p.memory > "9" {
            // no number
            return (0,0);
        }
        i++;
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
        let target = UnsafeMutablePointer<CChar>.alloc(msgData.length);
        var i = 0, j = 0;
        var p = UnsafeMutablePointer<CChar>(content);
        var q = target;
        
        while i < msgData.length {
            if p.memory == "@" && i > 0 {
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
                            q.memory = c;
                            if c != 0 {
                                j++;
                                q = q.advancedBy(1);
                            }
                        }
                        i += tag_size+bin_size;
                        p = p.advancedBy(tag_size+bin_size);
                    } else {
                        // issue during conversion
                        logError("tag \(tag) cannot be converted to Latin1");
                        target.destroy();
                        target.dealloc(msgData.length);
                        return false;
                    }
                    continue;
                }
            }
            
            q.memory = p.memory;
            i++; j++;
            p = p.advancedBy(1);
            q = q.advancedBy(1);
        }
        
        // now we have data that does not contain binary data any longer
        // next step: split into sequence of segments
        let messageSize = j;
        var segContent = UnsafeMutablePointer<CChar>.alloc(messageSize);
        i = 0; j = 0; var segSize = 0;
        
        p = target;
        q = segContent;
        while i < messageSize {
            q.memory = p.memory;
            if p.memory == "'" && !isEscaped(p) {
                // now we have a segment in segContent
                let data = NSData(bytes: segContent, length: segSize+1);
                self.segmentData.append(data);
                
                // we convert to String as well for debugging
                if let s = NSString(data: data, encoding: NSISOLatin1StringEncoding) {
                    self.segmentStrings.append(s);
                }
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
        
        target.destroy();
        target.dealloc(msgData.length);
        segContent.destroy();
        segContent.dealloc(messageSize);
        
        // now we have all segment strings and we can start to parse each segment
        for segData in self.segmentData {
            let (segment, parseError) = self.syntax.parseSegment(segData, binaries: self.binaries);
            if parseError {
                if let segmentString = NSString(data: segData, encoding: NSISOLatin1StringEncoding) {
                    logError("Parse error: segment \(segmentString) could not be parsed");
                } else {
                    logError("Parse error: segment (no conversion possible) could not be parsed");
                }
            } else {
                if let seg = segment {
                    self.segments.append(seg);
                }
            }
        }
        
        return true;
    }
    
    func valueForPath(path:String) ->AnyObject? {
        var name:String?
        var newPath:String?
        if let range = path.rangeOfString(".", options: NSStringCompareOptions.allZeros, range: nil, locale: nil) {
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
        if let range = path.rangeOfString(".", options: NSStringCompareOptions.allZeros, range: nil, locale: nil) {
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
        var bpData = NSMutableData();
        
        for data in segmentData {
            if let code = NSString(bytes: data.bytes, length: 5, encoding: NSISOLatin1StringEncoding) {
                if code == "HIUPA" || code == "HIUPD" || code == "HIBPA" ||
                    (code.hasPrefix("HI") && code.hasSuffix("S")) {
                        bpData.appendData(data);
                        continue;
                }
            }
            if let code = NSString(bytes: data.bytes, length: 6, encoding: NSISOLatin1StringEncoding) {
                if code.hasPrefix("HI") && code.hasSuffix("S") {
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
                if let num = segment.elementValueForPath("SegHead.ref") as? Int {
                    return segment;
                }
            }
        }
        return nil;
    }
    
    func responsesForSegmentWithNumber(number:Int) ->Array<HBCIOrderResponse>? {
        for segment in self.segments {
            if segment.name == "RetSeg" {
                if let num = segment.elementValueForPath("SegHead.ref") as? Int {
                    var responses = Array<HBCIOrderResponse>();
                    
                    let values = segment.elementsForPath("RetVal");
                    for retVal in values {
                        var response = HBCIOrderResponse();
                        response.code = retVal.elementValueForPath("code") as? String;
                        response.text = retVal.elementValueForPath("text") as? String;
                        response.reference = retVal.elementValueForPath("ref") as? String;
                        //todo: parameters
                        
                        responses.append(response);
                    }
                    return responses;
                }
            }
        }
        return nil;
    }
    
    func responsesForMessage() ->Array<HBCIMessageResponse>? {
        for segment in self.segments {
            if segment.name == "RetGlob" {
                var responses = Array<HBCIMessageResponse>();
                
                let values = segment.elementsForPath("RetVal");
                for retVal in values {
                    var response = HBCIMessageResponse();
                    response.code = retVal.elementValueForPath("code") as? String;
                    response.text = retVal.elementValueForPath("text") as? String;
                    responses.append(response);
                }
                return responses;
            }
        }
        return nil;
    }
    
    func isOk() ->Bool {
        if let responses = responsesForMessage() {
            for response in responses {
                if let code = response.code?.toInt() {
                    if code >= 9000 {
                        return false;
                    }
                } else {
                    return false;
                }
            }
            return true;
        } else {
            return false;
        }
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
