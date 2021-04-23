//
//  HBCISecurityMethodPinTan.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 17.07.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCISecurityMethodPinTan : HBCISecurityMethod {

    public override init() {
        super.init();
        self.code = .pinTan;
    }

    override func signMessage(_ msg:HBCIMessage) ->Bool {
        //let secref:String = NSString(format: "%d", arc4random());
        var version = 0;
        
        let secref = "\(arc4random())";
        
        if user.tanMethod == nil {
            logInfo("Signing failed: missing tanMethod");
            return false;
        }
        if user.sysId == nil {
            logInfo("Signing failed: missing sysId");
            return false;
        }
        if user.pin == nil {
            logInfo("Signing failed: missing PIN");
            return false;
        }
        
        if let seg = msg.elementForPath("SigHead") as? HBCISegment {
            version = seg.version;
        } else {
            logInfo("SigHead segment not found");
            return false;
        }
        
        // sign message head
        var values = ["SigHead.secfunc":user.tanMethod!,
            "SigHead.seccheckref":secref, "SigHead.range":"1", "SigHead.role":"1", "SigHead.SecIdnDetails.func":"1",
            "SigHead.SecIdnDetails.sysid":user.sysId!, "SigHead.secref":"1", "SigHead.SecTimestamp.type":"1",
            "SigHead.SecTimestamp.date":Date(), "SigHead.SecTimestamp.time":Date(), "SigHead.HashAlg.alg":"999",
            "SigHead.SigAlg.alg":"10", "SigHead.SigAlg.mode":"16", "SigHead.KeyName.country":"280",
            "SigHead.KeyName.blz":user.bankCode, "SigHead.KeyName.userid":user.userId, "SigHead.KeyName.keytype":"S",
            "SigHead.KeyName.keynum":"0", "SigHead.KeyName.keyversion":"0", "SigTail.seccheckref":secref,
            "SigTail.UserSig.pin":user.pin!
        ] as [String : Any];
        
        if version > 3 {
            values["SigHead.SecProfile.method"] = "PIN";
            values["SigHead.SecProfile.version"] = "2";

            if values["SigHead.secfunc"] as! String == "999" {
                values["SigHead.SecProfile.version"] = "1";
            }
        }
                
        // check if there is a TAN and if so, use it
        if let custMsg = msg as? HBCICustomMessage {
            if let tan = custMsg.tan {
                values["SigTail.UserSig.tan"] = tan;
            }
        }
        
        return msg.setElementValues(values);
    }
    
    func signCryptedMessage(_ msg:HBCIMessage) ->Bool {
        var version = 0;
        
        let encKey = [UInt8](repeating: 0, count: 8);
        //let encKeyData = Data(bytes: UnsafePointer<UInt8>(encKey), count: 8);
        let encKeyData = Data(encKey);
        
        if user.sysId == nil {
            logInfo("Signing failed: missing sysId");
            return false;
        }
        
        if let seg = msg.elementForPath("CryptHead") as? HBCISegment {
            version = seg.version;
        } else {
            logInfo("CryptHead segment not found");
            return false;
        }
        
        
        var values = [ "CryptHead.SegHead.seq":"998",
            "CryptHead.secfunc":"998", "CryptHead.role":"1", "CryptHead.SecIdnDetails.func":"1",
            "CryptHead.SecIdnDetails.sysid":user.sysId!, "CryptHead.SecTimestamp.date":Date(), "CryptHead.SecTimestamp.time":Date(),
            "CryptHead.CryptAlg.mode":"2", "CryptHead.CryptAlg.alg":"13", "CryptHead.CryptAlg.enckey":encKeyData,
            "CryptHead.CryptAlg.keytype":"5", "CryptHead.KeyName.country":"280", "CryptHead.KeyName.blz":user.bankCode,
            "CryptHead.KeyName.userid":user.userId, "CryptHead.KeyName.keynum":"0", "CryptHead.KeyName.keyversion":"0",
            "CryptHead.compfunc":"0"
        ] as [String : Any];
        
        if version > 2 {
            values["CryptHead.SecProfile.method"] = "PIN";
            values["CryptHead.SecProfile.version"] = "2";
        }
        
        return msg.setElementValues(values);
    }
    
    override func encryptMessage(_ msg:HBCIMessage, dialog:HBCIDialog) ->HBCIMessage? {
        if let lastSegNum = msg.lastSegmentNumber() {
            if let dialogId = dialog.dialogId {
                let msgBody = msg.messageDataForEncryption();
                
                let values = ["MsgHead.dialogid":dialogId, "MsgHead.msgnum":"\(dialog.messageNum)", "CryptData.data":msgBody,
                    "CryptData.SegHead.seq":"999", "MsgHead.SegHead.seq":"1", "MsgTail.msgnum":"\(dialog.messageNum)",
                    "MsgTail.SegHead.seq":"\(lastSegNum)"
                ] as [String : Any]
                
                if let md = dialog.syntax.msgs["Crypted"] {
                    if let msg_crypted = md.compose() as? HBCIMessage {
                        if signCryptedMessage(msg_crypted) {
                            if msg_crypted.setElementValues(values) {
                                let cryptedData = msg_crypted.messageData();
                                let sizeString = NSString(format: "%012d", cryptedData.count) as String;
                                if msg_crypted.setElementValue(sizeString, path: "MsgHead.msgsize") {
                                    return msg_crypted;
                                }
                            }
                        }
                    }
                } else {
                    logInfo("SyntaxFile error: Crypted message not found");
                }
            } else {
                logInfo("Dialog ID is not defined");
            }
        }
        return nil;
    }
    
    override func decryptMessage(_ rmsg:HBCIResultMessage, dialog:HBCIDialog) ->HBCIResultMessage? {
        if let msgData = rmsg.valueForPath("CryptData.data") as? Data {
            let result = HBCIResultMessage(syntax: dialog.syntax);
            if !result.parse(msgData) {
                logInfo("Result Message could not be parsed");
                logInfo(String(data: msgData, encoding: String.Encoding.isoLatin1));
            }
            return result;
        }
        return nil;
    }


}
