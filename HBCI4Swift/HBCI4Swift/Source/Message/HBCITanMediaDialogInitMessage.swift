//
//  HBCITANMediaMessage.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 14.09.19.
//  Copyright © 2019 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCITanMediaDialogInitMessage : HBCIDialogInitMessage {
    
    override class func newInstance(_ dialog:HBCIDialog) ->HBCITanMediaDialogInitMessage? {
        if let md = dialog.syntax.msgs["DialogInit"] {
            if let msg = md.compose() as? HBCIMessage {
                if let dialogId = dialog.dialogId {
                    if !msg.setElementValue(dialogId, path: "MsgHead.dialogid") { return nil; }
                    if !msg.setElementValue(dialog.messageNum, path: "MsgHead.msgnum") { return nil; }
                    if !msg.setElementValue(dialog.messageNum, path: "MsgTail.msgnum") { return nil; }
                    return HBCITanMediaDialogInitMessage(msg: msg, dialog: dialog);
                } else {
                    logInfo("No dialog started yet (dialog ID is missing)");
                }
            }
        }
        return nil;
    }
    
    override func addTanOrder(_ order:HBCITanOrder) ->Bool {
        if !order.finalize(nil) {
            return false;
        }
        if let segment = order.segment {
            if !segment.setElementValue("HKTAB", path: "ordersegcode") {
                return false;
            }
            if order.tanMediumName == nil {
                if !segment.setElementValue("noref", path: "tanmedia") {
                    return false;
                }
            }
            return addOrder(order, afterSegmentCode: "HKVVB");
        } else {
            logInfo("Order comes without segment!");
        }
        return false;
    }
    
}
