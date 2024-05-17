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
    public let user:HBCIUser;
    public let name:String;
    public let msg: HBCICustomMessage;
    open var success = false;
    open var needsTan = false;
    open var responses:Array<HBCIOrderResponse>?
    open var segment:HBCISegment!
    open var resultSegments = Array<HBCISegment>();
    
    public init?(name:String, message:HBCICustomMessage) {
        self.name = name;
        self.msg = message;
        self.user = msg.dialog.user;
                
        // check if TAN is needed
        if name != "TAN" {
            guard let seg = message.segmentWithName(name) else {
                return nil;
            }
            self.segment = seg;
            
            if let ptInfo = self.user.parameters.pinTanInfos {
                if let tan_needed = ptInfo.supportedSegs[seg.code] {
                    self.needsTan = tan_needed;
                } else {
                    logInfo(name + " is not supported!");
                    return nil;
                }
            } else {
                logInfo("Missing PIN/TAN information for user \(self.user.anonymizedId)");
                return nil;
            }
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
                            logInfo("Message from Bank: "+response.description);
                            self.success = false;
                        } else {
                            logInfo("Message from Bank: "+response.description);
                        }
                    }
                }
            } else {
                logInfo("UpdateResult: segment number not defined");
            }
        } else {
            logInfo("UpdateResult: segment not defined");
        }
    }
    
    open class func getParameterElement(_ user:HBCIUser, orderName:String) ->(element:HBCISyntaxElement, segment:HBCISegment)? {
        guard let seg = user.parameters.parametersForJob(orderName) else {
            logInfo("User parameter: parameters for order \(orderName) not found");
            return nil;
        }
        guard let elem = seg.elementForPath("Par"+orderName) else {
            logInfo(seg.description);
            return nil;
        }
        return (elem, seg);
    }
    
    func hasResponseWithCode(_ code:String) ->Bool {
        guard let responses = self.responses else {
            return false;
        }
        for response in responses {
            if response.code == code {
                return true;
            }
        }
        return false;
    }
    
    func adjustNeedsTanForPSD2() {
        // some banks do not send reliable HIPINS information
        // we need to adjust the needTan flag
        // we currently set it whenever we have HKTAN#6
        let parameters = self.user.parameters;
        if let sd = parameters.supportedSegmentVersion("TAN") {
            if sd.version >= 6 {
                self.needsTan = true;  // Some banks don't manage to send correct HIPINS
            }
        }

    }
    
}
