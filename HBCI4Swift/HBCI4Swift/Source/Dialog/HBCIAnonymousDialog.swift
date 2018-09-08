//
//  HBCIAnonymousDialog.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 31.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCIAnonymousDialog {
    var connection:HBCIConnection?
    var dialogId:String?;
    let hbciVersion:String!
    var syntax:HBCISyntax!                  // todo: replace with let once Xcode bug is fixed
    var messageNum = 1;
    
    public init(hbciVersion:String) throws {
        self.hbciVersion = hbciVersion;
        let syntax = try HBCISyntax.syntaxWithVersion(hbciVersion)
        self.syntax = syntax
    }

    @discardableResult func sendMessage(_ message:String, values:Dictionary<String,Any>) throws ->HBCIResultMessage? {
        if let md = self.syntax.msgs[message] {
            if let msg = md.compose() as? HBCIMessage {
                for (path, value) in values {
                    if !msg.setElementValue(value, path: path) {
                        return nil;
                    }
                }
                
                if !msg.enumerateSegments() {
                    return nil;
                }

                if !msg.finalize() {
                    return nil;
                }
                if !msg.validate() {
                    return nil;
                }
                //println(msg.description);
                let msgData = msg.messageData();
                //println(msg.messageString());

                // send message to bank
                let result = try self.connection!.sendMessage(msgData);
                let resultMsg = HBCIResultMessage(syntax: self.syntax);
                if !resultMsg.parse(result) {
                    return nil;
                } else {
                    return resultMsg;
                }
            }
        }
        return nil;
    }

    open func dialogWithURL(_ url:URL, bankCode:String) throws ->HBCIResultMessage? {
        self.connection = HBCIPinTanConnection(url: url);
        
        let values:Dictionary<String,Any> = ["ProcPrep.BPD":"0", "ProcPrep.UPD":"0", "ProcPrep.lang":"0", "ProcPrep.prodName":"Pecunia",
            "ProcPrep.prodVersion":"1.0", "Idn.KIK.country":"280", "Idn.KIK.blz":bankCode ];
        
        if let resultMsg = try sendMessage("DialogInitAnon", values: values) {
            // get dialog id
            if let dialogId = resultMsg.valueForPath("MsgHead.dialogid") as? String {
                self.dialogId = dialogId;
                
                // only if we have the dialogid, we can close the dialog
                let values = ["MsgHead.dialogid":dialogId, "DialogEnd.dialogid":dialogId,
                    "MsgHead.msgnum":"2", "MsgTail.msgnum":"2" ];
                
                do {
                    // don't care if end dialog message fails or not
                    _ = try sendMessage("DialogEndAnon", values: values as Dictionary<String, Any>);
                } catch { };
            }
            return resultMsg;            
        }
        return nil;
    }

}
