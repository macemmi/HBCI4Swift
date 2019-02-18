//
//  HBCIOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 31.01.15.
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


open class HBCIOrder {
    open let user:HBCIUser;
    open var success = false;
    open var needsTan = false;
    open var responses:Array<HBCIOrderResponse>?
    open let name:String;
    open let msg: HBCICustomMessage;
    open var segment:HBCISegment!
    open var resultSegments = Array<HBCISegment>();
    
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
                    logDebug(name + " is not supported!");
                    return nil;
                }
            } else {
                logDebug("Missing PIN/TAN information for user \(self.user.userId)");
                return nil;
            }
        } else {
            return nil;
        }
    }
    
    open func updateResult(_ result:HBCIResultMessage) {
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
                            logDebug("Message from Bank: "+response.description);
                            self.success = false;
                        } else {
                            logInfo("Message from Bank: "+response.description);
                        }
                    }
                }
            } else {
                logDebug("UpdateResult: segment number not defined");
            }
        } else {
            logDebug("UpdateResult: segment not defined");
        }
    }
    
    open class func getParameterElement(_ user:HBCIUser, orderName:String) ->(element:HBCISyntaxElement, segment:HBCISegment)? {
        guard let seg = user.parameters.parametersForJob(orderName) else {
            logDebug("User parameter: parameters for order \(orderName) not found");
            return nil;
        }
        guard let elem = seg.elementForPath("Par"+orderName) else {
            logDebug(seg.description);
            return nil;
        }
        return (elem, seg);
    }
    
}
