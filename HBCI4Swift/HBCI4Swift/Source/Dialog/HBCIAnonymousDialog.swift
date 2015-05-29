//
//  HBCIAnonymousDialog.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 31.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCIAnonymousDialog {
    var connection:HBCIConnection?
    var dialogId:String?;
    let hbciVersion:String!
    var syntax:HBCISyntax!                  // todo: replace with let once Xcode bug is fixed
    var messageNum = 1;
    
    init?(hbciVersion:String, error:NSErrorPointer) {
        self.hbciVersion = hbciVersion;
        if let syntax = HBCISyntax.syntaxWithVersion(hbciVersion, error: error) {
            self.syntax = syntax;
        } else {
            return nil;
        }
    }

    func sendMessage(message:String, values:Dictionary<String,AnyObject>, error:NSErrorPointer) ->HBCIResultMessage? {
        if let md = self.syntax.msgs[message] {
            if let msg = md.compose() as? HBCIMessage {
                for (path, value) in values {
                    if !msg.setElementValue(value, path: path) {
                        return nil;
                    }
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
                if let result = self.connection!.sendMessage(msgData, error: error) {
                    let resultMsg = HBCIResultMessage(syntax: self.syntax);
                    if !resultMsg.parse(result) {
                        return nil;
                    } else {
                        return resultMsg;
                    }
                }
            }
        }
        return nil;
    }

    func anonymousDialogForURL(url:NSURL, bankCode:String, error:NSErrorPointer) ->HBCIResultMessage? {
        self.connection = HBCIConnection(url: url);
        
        let values:Dictionary<String,AnyObject> = ["ProcPrep.BPD":"0", "ProcPrep.UPD":"0", "ProcPrep.lang":"0", "ProcPrep.prodName":"Pecunia",
            "ProcPrep.prodVersion":"1.0", "Idn.KIK.country":"280", "Idn.KIK.blz":bankCode ];
        
        if let resultMsg = sendMessage("DialogInitAnon", values: values, error: error) {
            // get dialog id
            if let dialogId = resultMsg.valueForPath("MsgHead.dialogid") as? String {
                self.dialogId = dialogId;
                
                // only if we have the dialogid, we can close the dialog
                let values = ["MsgHead.dialogid":dialogId, "DialogEnd.dialogid":dialogId,
                    "MsgHead.msgnum":"2", "MsgTail.msgnum":"2" ];
                
                // don't care if end dialog message fails or not
                sendMessage("DialogEndAnon", values: values, error: error);
            }
            return resultMsg;
        }
        return nil;
    }

}
