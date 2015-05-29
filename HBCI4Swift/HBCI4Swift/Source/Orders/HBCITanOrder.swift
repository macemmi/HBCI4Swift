//
//  HBCITanOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 02.03.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCITanOrder : HBCIOrder {
    
    // we only support process variant 2 by now
    var process:String?
    var orderRef:String?
    var listIndex:String?
    var tanMediumName:String?
    
    // results
    var challenge:String?
    var challenge_hdd_uc:NSData?
    
    // todo(?)
    
    
    init?(message:HBCICustomMessage) {
        super.init(name: "TAN", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    func enqueue() ->Bool {
        if let process = self.process {
            var values:Dictionary<String,AnyObject> = ["process":process];
            if tanMediumName != nil {
                values["tanmedia"] = tanMediumName!
            }
            if process == "1" || process == "2" {
                values["notlasttan"] = false;
            }
            
            if orderRef != nil {
                values["orderref"] = orderRef;
            }
            
            if segment.setElementValues(values) {
                msg.addOrder(self);
            } else {
                logError("Values could not be set for TAN order");
                return false;
            }
        } else {
            logError("Could not create TAN order - missing process info");
            return false;
        }
        return true;
    }
    
    override func updateResult(result:HBCIResultMessage) {
        super.updateResult(result);
        
        // get challenge information
        if let seg = resultSegments.first {
            self.challenge = seg.elementValueForPath("challenge") as? String;
            self.orderRef = seg.elementValueForPath("orderref") as? String;
            
            if seg.version > 3 {
                self.challenge_hdd_uc = seg.elementValueForPath("challenge_hdd_uc") as? NSData;
            }
        }
    }

}
