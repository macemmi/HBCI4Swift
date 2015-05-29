//
//  HBCIOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 31.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCIOrder {
    let msg: HBCICustomMessage;
    let user:HBCIUser;
    var success = false;
    var segment:HBCISegment!
    var needsTan = false;
    var responses:Array<HBCIOrderResponse>?
    var resultSegments = Array<HBCISegment>();
    let name:String;
    
    init?(name:String, message:HBCICustomMessage) {
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
    
    func updateResult(result:HBCIResultMessage) {
        // first get segment number
        if let seg = self.segment {
            if let segNum = seg.elementValueForPath("SegHead.seq") as? Int {
                // now find result with reference to this segment
                self.resultSegments = result.segmentsWithReference(segNum, orderName: seg.name);
                
                // also update result out of RetSeg
                if let responses = result.responsesForSegmentWithNumber(segNum) {
                    self.success = true;
                    self.responses = responses;
                    for response in responses {
                        if response.code != nil && response.text != nil {
                            if response.code!.toInt() >= 9000 {
                                logError("Message from Bank: \(response.code!): "+response.text!);
                                self.success = false;
                            } else {
                                logInfo("Message from Bank: \(response.code!): "+response.text!);
                            }
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
    
}
