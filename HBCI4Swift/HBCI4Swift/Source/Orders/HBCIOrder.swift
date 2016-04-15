//
//  HBCIOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 31.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCIOrder {
    public let user:HBCIUser;
    public var success = false;
    public var needsTan = false;
    public var responses:Array<HBCIOrderResponse>?
    public let name:String;
    public let msg: HBCICustomMessage;
    public var segment:HBCISegment!
    public var resultSegments = Array<HBCISegment>();
    
    public init?(name:String, message:HBCICustomMessage) {
        self.name = name;
        self.msg = message;
        self.user = msg.dialog.user;
        if let seg = message.segmentWithName(name) {
            self.segment = seg;
            
            // check if TAN is needed
            if let ptInfo = self.user.parameters.pinTanInfos {
                if let tan_needed = ptInfo.supportedSegs[seg.code] {
                    self.needsTan = tan_needed;
                } else {
                    logError(name + " is not supported!");
                    return nil;
                }
            } else {
                logError("Missing PIN/TAN information for user "+(self.user.userId ?? "<unknown>"));
                return nil;
            }
        } else {
            return nil;
        }
    }
    
    public func updateResult(result:HBCIResultMessage) {
        // first get segment number
        if let seg = self.segment {
            if let segNum = seg.elementValueForPath("SegHead.seq") as? Int {
                // now find result with reference to this segment
                self.resultSegments = result.segmentsWithReference(segNum, orderName: seg.name);
                
                // also update result out of RetSeg
                let responses = result.responsesForSegmentWithNumber(segNum);
                if responses.count > 0 {
                    self.success = true;
                    self.responses = responses;
                    for response in responses {
                        if Int(response.code) >= 9000 {
                            logError("Message from Bank: "+response.description);
                            self.success = false;
                        } else {
                            logInfo("Message from Bank: "+response.description);
                        }
                    }
                }
            } else {
                logError("UpdateResult: segment number not defined");
            }
        } else {
            logError("UpdateResult: segment not defined");
        }
    }
    
    public class func getParameterElement(user:HBCIUser, orderName:String) ->(element:HBCISyntaxElement, segment:HBCISegment)? {
        guard let seg = user.parameters.parametersForJob(orderName) else {
            logError("User parameter: parameters for order \(orderName) not found");
            return nil;
        }
        guard let elem = seg.elementForPath("Par"+orderName) else {
            logError(seg.description);
            return nil;
        }
        return (elem, seg);
    }
    
}
