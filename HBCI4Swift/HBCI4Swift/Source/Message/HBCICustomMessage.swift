//
//  HBCICustomMessage.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 04.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCICustomMessage : HBCIMessage {
    let dialog:HBCIDialog;
    var success = false;
    var tan:String?
    var orders = Array<HBCIOrder>();
    var result:HBCIResultMessage?
    
    init(msg:HBCIMessage, dialog:HBCIDialog) {
        self.dialog = dialog;
        super.init(description: msg.descr);
        self.children = msg.children;
        self.name = msg.name;
        self.length = msg.length;
    }
    
    
    public class func newInstance(dialog:HBCIDialog) ->HBCICustomMessage? {
        if let md = dialog.syntax.msgs["CustomMessage"] {
            if var msg = md.compose() as? HBCIMessage {
                if let dialogId = dialog.dialogId {
                    msg.setElementValue(dialogId, path: "MsgHead.dialogid");
                    msg.setElementValue(dialog.messageNum, path: "MsgHead.msgnum");
                    msg.setElementValue(dialog.messageNum, path: "MsgTail.msgnum");
                    return HBCICustomMessage(msg: msg, dialog: dialog);
                } else {
                    logError("No dialog started yet (dialog ID is missing)");
                }
            }
        }
        return nil;
    }
    
    func addOrder(order:HBCIOrder) {
        if let segment = order.segment {
            orders.append(order);
            self.children.insert(segment, atIndex: 2);
        } else {
            logError("Order comes without segment!");
        }
    }
    
    func segmentWithName(segName:String) ->HBCISegment? {
        if let segVersions = self.descr.syntax.segs[segName] {
            // now find the right segment version
            // check which segment versions are supported by the bank
            var supportedVersions = Array<Int>();
            for seg in dialog.user.parameters.bpSegments {
                if seg.name == segName+"Par" {
                    // check if this version is also supported by us
                    if segVersions.isVersionSupported(seg.version) {
                        supportedVersions.append(seg.version);
                    }
                }
            }
            
            if supportedVersions.count == 0 {
                // this process is not supported by the bank
                logError("Process \(segName) is not supported");
                return nil;
            }
            // now sort the versions - we take the latest supported version
            sort(&supportedVersions, >);
            
            if let sd = segVersions.segmentWithVersion(supportedVersions.first!) {
                if let segment = sd.compose() as? HBCISegment {
                    segment.name = segName;
                    return segment;
                }
            }
        } else {
            logError("Segment \(segName) is not supported by HBCI4Swift");
        }
        return nil;
    }
    
    public func send(error:NSErrorPointer) ->Bool {
        // check
        if orders.count == 0 {
            logError("Custom message contains no orders");
            return false;
        }
        
        // first check if there is one order which needs a TAN - then there can be only one order
        var needsTan = false;
        for order in orders {
            if order.needsTan {
                needsTan = true;
            }
        }
        if needsTan && orders.count > 1 {
            logError("Custom message contains several TAN-based orders. This is not supported");
            return false;
        }

        if needsTan {
            if dialog.user.tanMethod == nil {
                logError("Custom message order needs TAN but no TAN method provided for user");
                return false;
            }
            // if order needs TAN transfer to TAN message processor
            let process = HBCITanProcess_2(dialog: self.dialog);
            return process.processOrder(orders.last!, error: error);

        }
        
        return sendNoTan(error);
    }

    func sendNoTan(error:NSErrorPointer) ->Bool {
        if let result = self.dialog.sendMessage(self, error: error) {
            self.result = result;
            for order in orders {
                order.updateResult(result);
            }
            
            if let responses = result.responsesForMessage() {
                self.success = true;
                for response in responses {
                    if response.code != nil && response.text != nil {
                        logInfo("Message from Bank: \(response.code!): "+response.text!);
                        if response.code!.toInt() >= 9000 {
                            self.success = false;
                        }
                    }
                }
            }
            
            if self.success {
                return true;
            }
        }
        return false;
    }
    
    override func validate() ->Bool {
        var success = true;
        
        // The custom message is a template message, we therefore have to check the segments one by one
        for childElem in children {
            if !childElem.isEmpty {
                if !childElem.validate() {
                    success = false;
                }
            }
        }
        return success;
    }

    
}
