//
//  File.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 31.07.19.
//  Copyright © 2019 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCIDialogInitMessage : HBCICustomMessage {

    override class func newInstance(_ dialog:HBCIDialog) ->HBCIDialogInitMessage? {
        if let md = dialog.syntax.msgs["DialogInit"] {
            if let msg = md.compose() as? HBCIMessage {
                if let dialogId = dialog.dialogId {
                    if !msg.setElementValue(dialogId, path: "MsgHead.dialogid") { return nil; }
                    if !msg.setElementValue(dialog.messageNum, path: "MsgHead.msgnum") { return nil; }
                    if !msg.setElementValue(dialog.messageNum, path: "MsgTail.msgnum") { return nil; }
                    return HBCIDialogInitMessage(msg: msg, dialog: dialog);
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
            if !segment.setElementValue("HKIDN", path: "ordersegcode") {
                return false;
            }
            return addOrder(order, afterSegmentCode: "HKVVB");
        } else {
            logInfo("Order comes without segment!");
        }
        return false;
    }

    
    override func send() throws ->Bool {
        
        if dialog.user.securityMethod is HBCISecurityMethodDDV {
            return try sendNoTan();
        }

        // check if TAN#6 is supported by the bank - if yes, we need a TAN
        var needsTan = false;
        
        let parameters = self.dialog.user.parameters;
        guard let sd = parameters.supportedSegmentVersion("TAN") else {
            return false;
        }
        if sd.version >= 6 {
            needsTan = true;
        }
        
        if needsTan {
            if dialog.user.tanMethod == nil {
                logInfo("Custom message order needs TAN but no TAN method provided for user");
                return false;
            }
            // if order needs TAN transfer to TAN message processor
            let process = HBCITanProcess_2(dialog: self.dialog);
            return try process.processMessage(self, orders.last);            
        }
        
        return try sendNoTan();
    }



}
