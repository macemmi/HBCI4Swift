//
//  HBCIMessage.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 04.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCIMessage: HBCISyntaxElement {
    
    func enumerateSegments() ->Bool {
        var idx = 1;
        for element in self.children {
            if element.type == ElementType.Segment {
                if !element.setElementValue(idx, path: "SegHead.seq") {
                    return false;
                }
                idx++;
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
        logError("Segment number (SegHead.seq) not found in segment \(self.name)");
        return nil;
    }
    
    override func elementDescription() -> String {
        var name =
        self.name ?? "none";
        return "MSG name: \(name)\n";
    }
    
    func finalize() ->Bool {
        if !enumerateSegments() {
            return false;
        }
        
        let data = self.messageData();
        let sizeString = NSString(format: "%012d", data.length);
        return setElementValue(sizeString, path: "MsgHead.msgsize");
    }
    
    func messageData() ->NSData {
        var data = NSMutableData();
        self.messageData(data);
        var c = self.descr.delimiter;
        data.appendBytes(&c, length: 1);
        return data;
    }
    
    func messageDataForSignature() ->NSData {
        var data = NSMutableData();
        var delim = self.descr.delimiter;
        for idx in 0..<self.children.count {
            let element = self.children[idx];
            if element.name == "MsgHead" || element.name == "MsgTail" || element.name == "SigTail" {
                continue;
            }
            element.messageData(data);
            if idx < self.children.count-1 {
                data.appendBytes(&delim, length: 1);
            }
        }
        return data;
    }
    
    func messageDataForEncryption() ->NSData {
        var data = NSMutableData();
        var delim = self.descr.delimiter;
        for idx in 0..<self.children.count {
            let element = self.children[idx];
            if element.name == "MsgHead" || element.name == "MsgTail" {
                continue;
            }
            element.messageData(data);
            if idx < self.children.count-1 {
                data.appendBytes(&delim, length: 1);
            }
        }
        return data;
    }
    
    override func messageString() -> String {
        return super.messageString()+"'";
    }

}