//
//  HBCICustomMessage.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 04.02.15.
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


open class HBCICustomMessage : HBCIMessage {
    let dialog:HBCIDialog;
    var success = false;
    var tan:String?
    open var orders = Array<HBCIOrder>();
    open var mainOrder: HBCIOrder?             // main order remains nil in Dialog Init Messages
    var result:HBCIResultMessage?
    
    init(msg:HBCIMessage, dialog:HBCIDialog) {
        self.dialog = dialog;
        super.init(description: msg.descr);
        self.children = msg.children;
        self.name = msg.name;
        self.length = msg.length;
    }
    
    
    open class func newInstance(_ dialog:HBCIDialog) ->HBCICustomMessage? {
        if let md = dialog.syntax.msgs["CustomMessage"] {
            if let msg = md.compose() as? HBCIMessage {
                if let dialogId = dialog.dialogId {
                    if !msg.setElementValue(dialogId, path: "MsgHead.dialogid") { return nil; }
                    if !msg.setElementValue(dialog.messageNum, path: "MsgHead.msgnum") { return nil; }
                    if !msg.setElementValue(dialog.messageNum, path: "MsgTail.msgnum") { return nil; }
                    return HBCICustomMessage(msg: msg, dialog: dialog);
                } else {
                    logInfo("No dialog started yet (dialog ID is missing)");
                }
            }
        }
        return nil;
    }
    
    open func addOrder(_ order:HBCIOrder, afterSegmentCode:String? = nil) -> Bool {
        if let segment = order.segment {
            if segment.code == "HKVPP" || segment.code == "HKVAP" {
                logDebug("segment not allowed in addOrder")
                return false;
            }
            
            orders.append(order);
            if segment.code != "HKTAN" {
                // we can have only one main order
                guard mainOrder == nil else {
                    logDebug("only one main order is supported")
                    return false }
                mainOrder = order;
            }
            if let segmentCode = afterSegmentCode {
                if !self.insertAfterSegmentCode(segment, segmentCode) {
                    logInfo("Error adding segment after "+segmentCode);
                    return false;
                }
            } else {
                self.children.insert(segment, at: 2);
            }
        } else {
            logInfo("Order comes without segment!");
            return false;
        }
        return true;
    }
    
    func addVoPRequestOrder(_ order:HBCIVoPRequestOrder) -> Bool {
        if let segment = order.segment {
            orders.append(order);
            
            // we have to make sure that this segment comes first
            self.children.insert(segment, at: 2);
        } else {
            logInfo("VoP request order comes without segment!");
            return false;
        }
        return true;
    }
    
    func addVoPConfirmationOrder(_ order:HBCIVoPConfirmationOrder) -> Bool {
        if let segment = order.segment {
            orders.append(order);
            
            // we first need to remove the request order
            if !removeSegmentWithCode("HKVPP") {
                return false;
            }
            
            // we have to make sure that this segment comes first
            self.children.insert(segment, at: 2);
        } else {
            logInfo("VoP confirmation order comes without segment!");
            return false;
        }
        return true;
    }
    
    func updateRemoteNameForVoP(vopResult:HBCIVoPResult) -> Bool {
        for order in self.orders {
            if let transferOrder = order as? HBCIAbstractSepaTransferOrder {
                return transferOrder.updateRemoteNameForVoP(vopResult: vopResult);
            }
        }
        return false;
    }
    
    func addTanOrder(_ order:HBCITanOrder) ->Bool {
        guard let refOrder = mainOrder else {
            logInfo("No order in message");
            return false;
        }
        if !order.finalize(refOrder) {
            return false;
        }
        return addOrder(order, afterSegmentCode: refOrder.segment.code);
    }
    
    func segmentWithNameVersion(segName:String, version:Int) ->HBCISegment? {
        guard let segVersions = self.descr.syntax.segs[segName] else {
            logInfo("Segment \(segName) is not supported by HBCI4Swift");
            return nil;
        }
        guard let sd = segVersions.segmentWithVersion(version) else {
            logInfo("Segment \(segName) is not supported for version \(version)");
            return nil;
        }
        if let segment = sd.compose() as? HBCISegment {
            segment.name = segName;
            return segment;
        } else {
            logInfo("Segment \(segName) could not be composed");
        }
        return nil;
    }
    
    func segmentWithName(_ segName:String, version:Int = 0) ->HBCISegment? {
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
                logInfo("Process \(segName) is not supported, no parameter information found");
                // In some cases the bank does not send any Parameter but the process is still supported
                // let's just try it out
                supportedVersions = segVersions.versionNumbers;
            }
            // now sort the versions - we take the latest supported version
            supportedVersions.sort(by: >);
            let segVersion = version == 0 ? supportedVersions.first! : version;
            
            if let sd = segVersions.segmentWithVersion(segVersion) {
                if let segment = sd.compose() as? HBCISegment {
                    segment.name = segName;
                    return segment;
                }
            }
        } else {
            logInfo("Segment \(segName) is not supported by HBCI4Swift");
        }
        return nil;
    }
    
    open func send() throws ->Bool {
        // check
        if orders.count == 0 || mainOrder == nil {
            logInfo("Custom message contains no orders");
            return false;
        }
        
        if dialog.user.securityMethod is HBCISecurityMethodDDV {
            return try sendNoTan();
        }
        
        // first check if there is one order which needs a TAN - then there can be only one order
        var needsTan = false;
        for order in orders {
            if order.needsTan {
                needsTan = true;
            }
        }
        if needsTan && orders.count > 1 {
            logInfo("Custom message contains several TAN-based orders. This is not supported");
            return false;
        }

        if needsTan {
            if dialog.user.tanMethod == nil {
                logInfo("Custom message order needs TAN but no TAN method provided for user");
                return false;
            }
            // if order needs TAN transfer to TAN message processor
            let process = HBCITanProcess_2(dialog: self.dialog);
            return try process.processMessage(self, orders.last!)

        }
        
        return try sendNoTan();
    }

    func sendNoTan() throws ->Bool {
        if let result = try self.dialog.sendMessage(self) {
            self.result = result;
            
            let responses = result.responsesForMessage();
            self.success = true;
            for response in responses {
                if Int(response.code) >= 9000 {
                    logError("Banknachricht: "+response.description);
                    self.success = false;
                } else {
                    logInfo("Banknachricht: "+response.description);
                }
            }
            
            if self.success {
                for order in orders {
                    order.updateResult(result);
                }
                return true;
            }
        }
        return false;
    }
    
    func isVoPRequired() -> Bool {
        guard let par = dialog.user.parameters.getVoPParameters() else { return false }
        
        // check if message contains VoP-relevant orders
        var vop_req = false;
        for order in self.orders {
            if par.segments.contains(order.segment.code) {
                vop_req = true;
                break;
            }
        }
        return vop_req;
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
