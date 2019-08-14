//
//  HBCIMessage.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 04.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCIMessage: HBCISyntaxElement {
    
    func enumerateSegments() ->Bool {
        var idx = 1;
        for element in self.children {
            if element.type == ElementType.segment {
                if !element.setElementValue(idx, path: "SegHead.seq") {
                    return false;
                }
                idx += 1;
            }
        }
        return true;
    }
    
    func lastSegmentNumber() ->Int? {
        if let element = self.children.last {
            if let num = element.elementValueForPath("SegHead.seq") as? Int {
                return num;
            }
        }
        logInfo("Segment number (SegHead.seq) not found in segment \(self.name)");
        return nil;
    }
    
    func insertAfterSegmentCode(_ seg:HBCISegment, _ code:String) ->Bool {
        guard let segments = self.children as? [HBCISegment] else {
            logInfo("Wrong message setup");
            logInfo(self.debugDescription);
            return false;
        }
        // look for reference segment
        var idx = 1;
        for segment in segments {
            if segment.code == code {
                self.children.insert(seg, at: idx);
                return true;
            }
            idx = idx+1;
        }
        // if reference segment was not found insert at the end
        self.children.insert(seg, at: idx);
        return true;
    }
    
    override func elementDescription() -> String {
        return "MSG name: \(self.name)\n";
    }
    
    func finalize() ->Bool {
        /*
        if !enumerateSegments() {
            return false;
        }
        */
        let data = self.messageData();
        let sizeString = NSString(format: "%012d", data.count);
        return setElementValue(sizeString, path: "MsgHead.msgsize");
    }
    
    func messageData() ->Data {
        let data = NSMutableData();
        self.messageData(data);
        var c = self.descr.delimiter;
        data.append(&c, length: 1);
        return data as Data;
    }
    
    func messageDataForSignature() ->Data {
        let data = NSMutableData();
        var delim = self.descr.delimiter;
        for idx in 0..<self.children.count {
            let element = self.children[idx];
            if element.name == "MsgHead" || element.name == "MsgTail" || element.name == "SigTail" {
                continue;
            }
            element.messageData(data);
            if idx < self.children.count-1 {
                data.append(&delim, length: 1);
            }
        }
        return data as Data;
    }
    
    func messageDataForEncryption() ->Data {
        let data = NSMutableData();
        var delim = self.descr.delimiter;
        for idx in 0..<self.children.count {
            let element = self.children[idx];
            if element.name == "MsgHead" || element.name == "MsgTail" {
                continue;
            }
            element.messageData(data);
            if idx < self.children.count-1 {
                data.append(&delim, length: 1);
            }
        }
        return data as Data;
    }
    
    override open func messageString() -> String {
        return super.messageString()+"'";
    }

}
